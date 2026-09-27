# Fudatobashi – working notes / handoff

The plan lives in `~/.claude-revi/plans/we-are-going-to-async-llama.md`, and product truth in `PRODUCT.md`.

## Status (2026-09-27)

### Done (all tests pass: `flutter test`)
- **Data:** `dart run tool/build_poems.dart` fetches StoneLabs/hyakuninissyu-csv and writes `assets/data/poems.json`. It validates the torifuda split, kimariji uniqueness and the standard distributions. The display kimariji follows the particle-は convention (ひとは, いまは, よのなかは).
- **Torifuda renderer:** `lib/ui/torifuda/`, with geometry calibrated from the original app's 374×525 card PNGs (`reference/`, gitignored).
  - A 6-kana column (#21) gets a tighter pitch.
  - The card font is *provisional* (Yuji Syuku); the user dislikes it. The original is the commercial **Morisawa 正楷書CB1** (confirmed by specimen match, ~77.4 px/em). The font subagent is still working on this with the user.
  - Only `TorifudaSpec.fontFamily` and the pubspec font entry need to change.
- **Swipe deck:** `lib/ui/play/swipe_deck.dart`.
  - Raw `Listener` for µs timestamps. Reveal = vsync of the first frame painting the card; the next card stays blank until commit.
  - Straight down (±25°) = don't know.
  - Clock domains were verified on the device: pointer and frame timestamps share the monotonic clock (pointer resolution is 1 ms).
- **Domain:**
  - `play_session.dart`: undo, marking wrong, tainted redo.
  - `card_stats.dart`: EWMA, rolling windows, p95, solid.
  - `trainer.dart`: the FSRS-6 `fsrs` package plus ms→grade mapping, unlock batches keeping kimariji families together, goal ladder, session planner.
  - `masking.dart`: 隠し字 levels 1–7 with a uniqueness guarantee (min visible distance 2).
  - `rating.dart`: projected 100-card time → `600·log2(1000/T)`, Elo-style smoothing, bands 入門, F下 … A.
- **Persistence:** drift DB in `lib/db/database.dart`; `lib/state/progress.dart` loads everything, records runs (guest runs record nothing), handles unlocks and rating.
- **Debug page:** `lib/ui/debug/debug_page.dart` (overview and knobs, items with FSRS S/D/R, scheduler preview, rating breakdown, timing). It is *not wired into navigation yet*.
- `main.dart` currently launches a temporary PlayScreen (a random 10-card deck) for feel-testing on the phone.

### In progress
- **Design direction:** three HTML mockups are being built by subagents. They land in scratchpad `design/`, copied to `research/design/` (gitignored):
  - `banzuke.html`: sumo banzuke, purple.
  - `manga.html`: sports-manga panels, SFX.
  - `islands.html`: かな諸島 flat-colour archipelago.
  - The user will pick or give feedback in the browser. The build is code-led (no image generation).
- **Font:** waiting on the font subagent and the user.

### Next
1. Show the mockups (`xdg-open research/design/*.html`) and get the user's pick.
2. Build the themed UI in the chosen world:
   - home (Training hero, Free, 苦手, Guest with the SRS note)
   - the play chrome
   - results with unlock and PB celebrations
   - stats (mastery map plus per-card chart)
   - history and detail (like the original, readable)
   - the filter screen (orientation, 100首, 11 initial groups, 19 confusable sets, ひと/わか, kimariji length)
   - help (解説, 決まり字一覧, 覚える順序)
   - rank ladder, settings (EN/JA toggle, following the system by default), and a debug entry
3. Wire the run flow: plan → PlaySession → `Progress.recordRun` → results. Add training's in-session re-queue after a miss (plus its 友札).
4. Scramble/shape mask styles polish; the adaptive mask level per card.
5. Dynamic-kimariji mode, export/import, desktop keyboard controls, iOS CI.

## Conventions
- Commit messages are one line, with no Co-Authored-By. Commits are SSH-signed; the user loads the key.
- Phone: SM-A546B over adb. Use the SDK adb (`~/Android/Sdk/platform-tools`); the env is in `scratchpad/env.sh`: flutter at `~/dev/flutter/bin`, `JAVA_HOME` jdk21, `ANDROID_HOME ~/Android/Sdk`.
- Build and install: `flutter build apk --debug && adb install -r build/app/outputs/flutter-apk/app-debug.apk`
