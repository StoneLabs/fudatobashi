#!/usr/bin/env python3
"""Generates the kimariji (決まり字) voice clips, assets/voice/kimariji/NNN.m4a
(NNN = zero-padded poem id), with Google's Gemini 3.8 Flash TTS (voice Puck)
through OpenRouter.

Each poem's kimarijiReading in assets/data/poems.json (the modern
pronunciation, e.g. あひ → あい) is sent as katakana only: the TTS reads
katakana most accurately, and it speaks any instructions in the input aloud.
Each take is trimmed, loudness-normalized and encoded as mono AAC. A take
whose speech is implausibly short or long for its number of kana is retaken;
if every take fails, the last one is kept and marked CHECK in
.scratchpad/kimariji_voice_review.txt.

Run with ./scripts/kimariji_voice.sh [ids...] (it sets up the venv and the
OPENROUTER_API_KEY). Gemini's output varies, so every run produces new takes.
--check only re-runs the length check on the clips already there, e.g. after
dropping in a recording.
"""

import argparse
import concurrent.futures
import json
import os
import pathlib
import subprocess
import sys
import time
import urllib.error
import urllib.request

import numpy as np

REPO_ROOT = pathlib.Path(__file__).resolve().parent.parent
POEMS_JSON = REPO_ROOT / "assets" / "data" / "poems.json"
OUT_DIR = REPO_ROOT / "assets" / "voice" / "kimariji"
REVIEW_FILE = REPO_ROOT / ".scratchpad" / "kimariji_voice_review.txt"

API_URL = "https://openrouter.ai/api/v1/audio/speech"
TTS_MODEL = "google/gemini-3.8-flash-tts"
VOICE = "Puck"
# A lone kana is often devoiced to a bare consonant (フ → "f", ム → "mm").
# This direction travels as speech metadata, so it is never spoken.
SINGLE_KANA_STYLE = "Say this single Japanese kana slowly and clearly, with a fully voiced vowel"

MAX_TAKES = 3
PARALLEL_POEMS = 6
MAX_REQUEST_ATTEMPTS = 4
RETRY_BACKOFF_S = 2.0
REQUEST_DELAY_S = 0.3
REQUEST_TIMEOUT_S = 90

SAMPLE_RATE = 24000  # Gemini TTS returns 24 kHz mono signed 16-bit PCM
AAC_BITRATE = "64k"

FRAME_MS = 10
# Speech spans the first to the last frame within SPEECH_RANGE_DB of the
# loudest one, but never below the TTS output's noise floor.
SPEECH_RANGE_DB = 40
NOISE_FLOOR_DBFS = -55
LEAD_PAD_MS = 60
TAIL_PAD_MS = 120
FADE_MS = 8

# Frames within LOUDNESS_GATE_DB of the loudest form the speech level, which
# is set to TARGET_SPEECH_DBFS, unless that would push a peak past the
# ceiling.
LOUDNESS_GATE_DB = 20
TARGET_SPEECH_DBFS = -16.0
PEAK_CEILING_DBFS = -1.0

# Plausible speech length per kana. Across the first full run it ranged from
# 0.095 s (ツク, devoiced) to 0.54 s (a slow single ス); outside these bounds,
# a kana was most likely dropped, or something extra was said.
MIN_SPEECH_PER_KANA_S = 0.08
MAX_SPEECH_PER_KANA_S = 0.6


def to_katakana(hiragana: str) -> str:
    """Katakana for [hiragana], with ヲ as オ: the TTS swallows a ヲ after
    another vowel (ヨヲ comes out as just "yo"), and modern karuta reads を
    as "o" anyway."""
    katakana = "".join(chr(ord(c) + 0x60) if "ぁ" <= c <= "ゖ" else c for c in hiragana)
    return katakana.replace("ヲ", "オ")


def synthesize(text: str, style: str | None) -> np.ndarray:
    """[text] spoken by the TTS, retrying rate limits, upstream errors and
    network failures."""
    body = {"model": TTS_MODEL, "input": text, "voice": VOICE, "response_format": "pcm"}
    if style:
        body["provider"] = {"options": {"google-ai-studio": {"speech_metadata": {"style": style}}}}
    request = urllib.request.Request(
        API_URL,
        data=json.dumps(body).encode(),
        headers={"Authorization": f"Bearer {os.environ['OPENROUTER_API_KEY']}", "Content-Type": "application/json"},
    )
    for attempt in range(1, MAX_REQUEST_ATTEMPTS + 1):
        time.sleep(REQUEST_DELAY_S)
        try:
            with urllib.request.urlopen(request, timeout=REQUEST_TIMEOUT_S) as response:
                content_type = response.headers.get("Content-Type", "")
                if f"rate={SAMPLE_RATE}" not in content_type or "channels=1" not in content_type:
                    raise RuntimeError(f"unexpected TTS audio format: {content_type}")
                return np.frombuffer(response.read(), dtype="<i2").astype(np.float64) / 32768
        except urllib.error.HTTPError as e:
            if (e.code != 429 and e.code < 500) or attempt == MAX_REQUEST_ATTEMPTS:
                raise RuntimeError(f"TTS: HTTP {e.code}: {e.read().decode(errors='replace')[:300]}") from e
        except (urllib.error.URLError, TimeoutError):
            if attempt == MAX_REQUEST_ATTEMPTS:
                raise
        time.sleep(RETRY_BACKOFF_S * attempt)
    raise AssertionError("unreachable")


def frame_dbfs(samples: np.ndarray) -> np.ndarray:
    size = SAMPLE_RATE * FRAME_MS // 1000
    count = max(1, len(samples) // size)
    frames = np.resize(samples, count * size).reshape(count, size)
    return 20 * np.log10(np.maximum(np.sqrt((frames**2).mean(axis=1)), 1e-9))


def speech_span(samples: np.ndarray) -> tuple[int, int]:
    """The sample range from the first to the last frame of speech."""
    db = frame_dbfs(samples)
    speech = np.where(db >= max(db.max() - SPEECH_RANGE_DB, NOISE_FLOOR_DBFS))[0]
    if speech.size == 0:
        return 0, 0
    frame = SAMPLE_RATE * FRAME_MS // 1000
    return speech[0] * frame, (speech[-1] + 1) * frame


def trim(samples: np.ndarray) -> np.ndarray:
    """Cuts the silence around the speech, keeping a short margin that fades
    in and out so no consonant attack or vowel release is clipped."""
    start, end = speech_span(samples)
    clip = samples[
        max(0, start - SAMPLE_RATE * LEAD_PAD_MS // 1000) : min(len(samples), end + SAMPLE_RATE * TAIL_PAD_MS // 1000)
    ].copy()
    fade = min(len(clip) // 2, SAMPLE_RATE * FADE_MS // 1000)
    ramp = np.linspace(0, 1, fade)
    clip[:fade] *= ramp
    clip[len(clip) - fade :] *= ramp[::-1]
    return clip


def normalize(samples: np.ndarray) -> np.ndarray:
    db = frame_dbfs(samples)
    loud = db > db.max() - LOUDNESS_GATE_DB
    speech_dbfs = 10 * np.log10(np.mean(10 ** (db[loud] / 10)))
    peak_dbfs = 20 * np.log10(max(np.abs(samples).max(), 1e-9))
    gain_db = min(TARGET_SPEECH_DBFS - speech_dbfs, PEAK_CEILING_DBFS - peak_dbfs)
    return samples * 10 ** (gain_db / 20)


def encode_m4a(samples: np.ndarray, path: pathlib.Path) -> None:
    pcm = (np.clip(samples, -1, 1) * 32767).astype("<i2").tobytes()
    subprocess.run(
        [
            "ffmpeg", "-y", "-loglevel", "error",
            "-f", "s16le", "-ar", str(SAMPLE_RATE), "-ac", "1", "-i", "-",
            "-c:a", "aac", "-b:a", AAC_BITRATE,
            "-map_metadata", "-1", "-fflags", "+bitexact", "-flags:a", "+bitexact",
            str(path),
        ],
        input=pcm,
        check=True,
    )


def decode_m4a(path: pathlib.Path) -> np.ndarray:
    pcm = subprocess.run(
        ["ffmpeg", "-loglevel", "error", "-i", str(path), "-f", "s16le", "-ac", "1", "-ar", str(SAMPLE_RATE), "-"],
        capture_output=True,
        check=True,
    ).stdout
    return np.frombuffer(pcm, dtype="<i2").astype(np.float64) / 32768


def review(poem: dict) -> tuple[bool, str]:
    """Checks [poem]'s clip on disk; returns whether its speech length is
    plausible and its review row."""
    sent = to_katakana(poem["kimarijiReading"])
    clip = decode_m4a(OUT_DIR / f"{poem['id']:03d}.m4a")
    start, end = speech_span(clip)
    per_kana_s = (end - start) / SAMPLE_RATE / len(sent)
    ok = MIN_SPEECH_PER_KANA_S <= per_kana_s <= MAX_SPEECH_PER_KANA_S
    row = (
        f"{poem['id']:03d} | {poem['kimarijiReading']:<6} | {sent:<6} | {len(clip) / SAMPLE_RATE:.2f}s"
        f" | {(end - start) / SAMPLE_RATE:.2f}s | {per_kana_s:.3f}s | {'OK' if ok else 'CHECK'}"
    )
    return ok, row


def generate(poem: dict) -> str:
    """Records [poem]'s clip, retaking it up to MAX_TAKES times until its
    length is plausible, and returns its review row."""
    sent = to_katakana(poem["kimarijiReading"])
    style = SINGLE_KANA_STYLE if len(sent) == 1 else None
    for _ in range(MAX_TAKES):
        encode_m4a(normalize(trim(synthesize(sent, style))), OUT_DIR / f"{poem['id']:03d}.m4a")
        ok, row = review(poem)
        if ok:
            break
    return row


def write_review(rows: dict[int, str]) -> None:
    """Merges [rows] into the review file, replacing the rows of the same
    poems and keeping the rest."""
    if REVIEW_FILE.exists():
        for line in REVIEW_FILE.read_text(encoding="utf-8").splitlines():
            if line[:3].isdigit():
                rows.setdefault(int(line[:3]), line)
    header = "id  | reading | sent   | clip  | speech | per kana | verdict"
    lines = [header, "-" * len(header)] + [rows[k] for k in sorted(rows)]
    REVIEW_FILE.parent.mkdir(parents=True, exist_ok=True)
    REVIEW_FILE.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("ids", nargs="*", type=int, help="poem ids to process (default: all)")
    parser.add_argument("--check", action="store_true", help="only check the existing clips, without regenerating")
    args = parser.parse_args()
    if not args.check and "OPENROUTER_API_KEY" not in os.environ:
        sys.exit("OPENROUTER_API_KEY is not set: export it or put it in ~/.config/fudatobashi/openrouter.key")

    poems = sorted(json.loads(POEMS_JSON.read_text(encoding="utf-8")), key=lambda p: p["id"])
    if args.ids:
        poems = [p for p in poems if p["id"] in set(args.ids)]
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    process = (lambda poem: review(poem)[1]) if args.check else generate
    rows = {}
    with concurrent.futures.ThreadPoolExecutor(PARALLEL_POEMS) as pool:
        for poem, row in zip(poems, pool.map(process, poems)):
            rows[poem["id"]] = row
            print(row, flush=True)
            write_review({poem["id"]: row})
    checks = sum(row.endswith("CHECK") for row in rows.values())
    print(f"{len(rows)} clips in {OUT_DIR}, {checks} marked CHECK; review: {REVIEW_FILE}")


if __name__ == "__main__":
    main()
