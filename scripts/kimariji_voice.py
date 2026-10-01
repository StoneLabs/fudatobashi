#!/usr/bin/env python3
"""Generates placeholder kimariji (決まり字) voice clips with pyopenjtalk, an
offline Japanese TTS engine (Open JTalk + HTS Engine, bundled "Mei" voice).

Reads assets/data/poems.json's kimarijiReading (the correct modern-
pronunciation hiragana for each card, which can differ from its orthographic
kimariji, e.g. id 35: きみ "ひとは" is read "ひとわ") and writes one clip per
poem to assets/voice/kimariji/NNN.m4a (NNN = zero-padded poem id), so a human
can later drop in a real recording under the same filename. Also writes a
plain-text review file for spot-checking the readings and their phoneme
breakdown.

Rerun with ./scripts/kimariji_voice.sh (sets up the venv this needs first).
Deterministic: pyopenjtalk's HTS synthesis has no random seed to control.
"""

import json
import pathlib
import subprocess
import wave

import numpy as np
import pyopenjtalk

REPO_ROOT = pathlib.Path(__file__).resolve().parent.parent
POEMS_JSON = REPO_ROOT / "assets" / "data" / "poems.json"
OUT_DIR = REPO_ROOT / "assets" / "voice" / "kimariji"
REVIEW_FILE = REPO_ROOT / ".scratchpad" / "kimariji_voice_review.txt"

# A single kana is the hardest case for this engine: one mora, no surrounding
# context to carry the consonant's attack. These 7 ids get a slower speed and
# extra trailing padding so they don't clip or mumble.
SINGLE_KANA_IDS = {18, 22, 57, 70, 77, 81, 87}

OUTPUT_SAMPLE_RATE = 22050  # plenty for speech; keeps the .m4a files tiny
AAC_BITRATE = "64k"

# pyopenjtalk.tts(text, speed=1.0, ...): below 1.0 is slower. 0.85 reads
# noticeably slower and clearer than natural speech without sounding
# robotic; the single-kana cards go slower still since there's no adjacent
# mora to lean on.
DEFAULT_SPEED = 0.85
SINGLE_KANA_SPEED = 0.75

# Trimming: cut samples quieter than this fraction of the clip's own peak
# (silence/hiss before and after the speech), but keep a safety margin
# afterwards so the attack of a leading consonant is never clipped. The
# single-kana cards get a wider margin.
TRIM_THRESHOLD_RATIO = 0.03
TRIM_PAD_MS = 80
SINGLE_KANA_PAD_MS = 110

# Peak-normalize every trimmed clip to the same level, so the 100 cards are
# consistently loud (this also fixes the naturally quiet single-kana clips)
# and so a human recording swapped in later has a level to match (see
# HOW_TO_REPLACE.txt).
TARGET_PEAK_RATIO = 0.9
INT16_MAX = 32767

# A clip this short or quiet after trimming almost certainly failed to
# synthesize anything meaningful; flagged in the printed summary, not fatal.
SUSPECT_DURATION_S = 0.15
SUSPECT_PEAK = 1


def tts_text(reading: str) -> str:
    """The text actually fed to the synthesizer for [reading].

    Open JTalk's own text analysis guesses word boundaries and readings from
    context it doesn't have here — a kimariji is a truncated fragment, not a
    full phrase. A trailing hiragana は in particular is almost always the
    topic particle in its lexicon, so it defaults to reading it "wa" even
    when the data says it's really the plain "ha" sound of the next word
    (e.g. id 15's き「みがためは」 continues into 春, id 17's ち「は」 into
    早, both "ha"; contrast id 35's ひとは, truly the topic particle, which
    kimarijiReading already spells ひとわ and so never hits this case). A
    trailing katakana ハ isn't in the particle lexicon, so it's read as the
    plain mora instead — confirmed against pyopenjtalk.g2p before relying on
    it here.
    """
    if reading.endswith('は'):
        return reading[:-1] + 'ハ'
    return reading


def trim_silence(samples: np.ndarray, sr: int, pad_ms: int) -> np.ndarray:
    """Cuts leading/trailing near-silence, keeping pad_ms of margin."""
    peak = np.abs(samples).max()
    if peak == 0:
        return samples
    above = np.where(np.abs(samples) > peak * TRIM_THRESHOLD_RATIO)[0]
    if above.size == 0:
        return samples
    pad = int(sr * pad_ms / 1000)
    start = max(0, above[0] - pad)
    end = min(len(samples), above[-1] + pad + 1)
    return samples[start:end]


def peak_normalize(samples: np.ndarray) -> np.ndarray:
    peak = np.abs(samples).max()
    if peak == 0:
        return samples
    target = TARGET_PEAK_RATIO * INT16_MAX
    return samples * (target / peak)


def write_m4a(samples: np.ndarray, sr: int, out_path: pathlib.Path) -> None:
    """Writes samples to out_path as AAC/m4a, via a temporary 16-bit wav."""
    pcm16 = np.clip(samples, -32768, 32767).astype(np.int16)
    tmp_wav = out_path.with_suffix(".tmp.wav")
    with wave.open(str(tmp_wav), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(sr)
        w.writeframes(pcm16.tobytes())
    try:
        subprocess.run(
            [
                "ffmpeg", "-y", "-loglevel", "error",
                "-i", str(tmp_wav),
                "-ar", str(OUTPUT_SAMPLE_RATE), "-ac", "1",
                "-c:a", "aac", "-b:a", AAC_BITRATE,
                str(out_path),
            ],
            check=True,
        )
    finally:
        tmp_wav.unlink()


def main() -> None:
    poems = json.loads(POEMS_JSON.read_text(encoding="utf-8"))
    poems.sort(key=lambda p: p["id"])

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    REVIEW_FILE.parent.mkdir(parents=True, exist_ok=True)

    header = f"{'id':<4}| {'kimariji':<8}| {'reading':<8}| phonemes (pyopenjtalk.g2p)"
    review_lines = [header, "-" * len(header)]
    suspects = []

    for poem in poems:
        poem_id = poem["id"]
        kimariji = poem["kimariji"]
        reading = poem["kimarijiReading"]
        single = poem_id in SINGLE_KANA_IDS
        speed = SINGLE_KANA_SPEED if single else DEFAULT_SPEED
        pad_ms = SINGLE_KANA_PAD_MS if single else TRIM_PAD_MS

        samples, sr = pyopenjtalk.tts(tts_text(reading), speed=speed)
        samples = trim_silence(samples, sr, pad_ms)
        duration_s = len(samples) / sr
        samples = peak_normalize(samples)

        write_m4a(samples, sr, OUT_DIR / f"{poem_id:03d}.m4a")

        peak = np.abs(samples).max()
        if duration_s < SUSPECT_DURATION_S or peak <= SUSPECT_PEAK:
            suspects.append(f"id {poem_id} ({kimariji}/{reading}): duration={duration_s:.3f}s peak={peak:.0f}")

        phones = pyopenjtalk.g2p(tts_text(reading))
        review_lines.append(f"{poem_id:03d} | {kimariji:<8}| {reading:<8}| {phones}")

    REVIEW_FILE.write_text("\n".join(review_lines) + "\n", encoding="utf-8")

    print(f"Wrote {len(poems)} clips to {OUT_DIR}")
    print(f"Wrote review file to {REVIEW_FILE}")
    if suspects:
        print("Suspiciously short/quiet clips (check manually):")
        for line in suspects:
            print(" ", line)


if __name__ == "__main__":
    main()
