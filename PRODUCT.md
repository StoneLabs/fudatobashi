# Product

<!-- impeccable:product-schema 1 -->

## Platform

adaptive

One Flutter codebase for Android (primary; developed on a Samsung SM-A546B at 120 Hz), iOS (a big plus, built later on macOS CI) and desktop (minor plus). One shared design language, not per-OS styling.

## Stack

Flutter (Dart, Impeller). Chosen by Claude after the user delegated ("whatever is performant and would make the best end result"): pixel-identical custom rendering of the torifuda on every platform, 120 Hz, µs pointer timestamps, one codebase for Android, iOS and desktop. Riverpod, go_router, drift (SQLite), fl_chart.

## Users

The user (a competitive karuta player) and their karuta club, including beginners. APKs are shared directly, maybe TestFlight later. Not a commercial product.
Typical scene: a few minutes of 札落とし between classes or before practice, phone in hand, saying kimariji under their breath and flicking cards as fast as possible. Sometimes the phone is handed to a clubmate (guest mode).

## Product Purpose

A better 札落とし (fudaotoshi) trainer than the Fudaotoshi app (jp.excd.fudaotoshi). It keeps every feature of that app and adds the following:
- ms-exact per-card timing and analytics
- a spaced-repetition training mode that eases beginners in and unlocks new cards with celebrations
- a 隠し字 mode that hides torifuda kana so players stop relying on the first characters
- a continuous rating mapped to A–F classes (with F and E split 上/下)

Success means players measurably get faster, and beginners stick with it.

## Positioning

Per-card, millisecond-level data drives what you practise next. It covers speed and coverage, not just recall, and the card on screen is an exact, faithful torifuda.

## Operating Context

- **Play loop:** a card appears; the player says the kimariji; they flick it away. Straight down means "don't know" (configurable). ひとつ前 undoes, 終了 ends.
- Sessions are short and intense, one-handed, often in noisy places.
- Terminology is Japanese karuta vocabulary: 取り札, 決まり字, 友札, 札落とし, 級, 逆さま.

## Capabilities and Constraints

- The torifuda rendering is fixed and must be 100% faithful: green frame, grey paper, black brush kana in a 5/5/rest grid, calibrated against the original app's card art. Never restyle the card.
- Timing precision and smooth 120 Hz operation outrank decoration. Nothing may add input latency or frame drops during play.
- The UI is bilingual EN/JA, follows the system language by default, and has a toggle. Karuta content is always Japanese.
- All data is local. Guest mode records nothing.

## Brand Commitments

- Name: Fudatobashi (札飛ばし).
- The user explicitly wants it **fun and playful, not business-like or boring** ("this is not a for money product so we can have some fun").

## Evidence on Hand

- `reference/`: the original app's 200 card PNGs, used only for calibration and never shipped.
- The 100-poem dataset lives in `assets/data/poems.json`.
- No testimonials, users or metrics exist yet; none may be invented.

## Product Principles

1. The card is sacred: exact, calm and legible. Fun lives around it, never on it.
2. Speed first: every screen gets you to the next swipe fast. Play chrome stays minimal.
3. Data you can feel: numbers and charts are there to motivate, with progress celebrated loudly.
4. Beginner-kind, expert-honest: gentle ramps for newcomers, true ms and ranks for competitors.

## Accessibility & Inclusion

- High contrast (the original's grey-on-green history text is an anti-example).
- Large touch targets for one-handed fast play.
- Respect reduced motion in celebrations.
