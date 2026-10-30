import 'package:flutter/widgets.dart';
import 'package:fudatobashi/data/poem.dart';
import 'package:fudatobashi/domain/sound_ladder.dart';
import 'package:fudatobashi/l10n/strings.dart';
import 'package:fudatobashi/state/settings.dart';
import 'package:fudatobashi/ui/cards/sound_ladder_view.dart';

import 'figure_layout.dart';
import 'figure_panel.dart';
import 'kimariji_rows.dart';

/// The kimariji guide's pictures (First sounds, opened from a card's About
/// page), drawn from the ladders of [FirstSoundsExamples]' cards as the
/// About page shows them, in the player's script.

/// The card the guide walks down, and the one card that starts like it.
(Poem, Poem) _pair() {
  final card = poems[FirstSoundsExamples.card];
  final pair = SoundLadder.of(card, poems.all, kanaOnly: true)[1];
  return (card, poems[pair.joining.single]);
}

/// The card and its rival, each with its kimariji.
class PairFigure extends StatelessWidget {
  const PairFigure({super.key});

  @override
  Widget build(BuildContext context) {
    final (card, rival) = _pair();
    return FigurePanel(
      child: KimarijiRows(rows: [
        KimarijiRow(poem: card, kimariji: card.kimariji),
        KimarijiRow(poem: rival, kimariji: rival.kimariji),
      ]),
    );
  }
}

/// The rival read, and the card needing a sound less.
class ReadFigure extends StatelessWidget {
  const ReadFigure({super.key});

  @override
  Widget build(BuildContext context) {
    final (card, rival) = _pair();
    final pair = SoundLadder.of(card, poems.all, kanaOnly: true)[1];
    return FigurePanel(
      child: KimarijiRows(rows: [
        KimarijiRow(poem: rival, kimariji: rival.kimariji, read: true),
        KimarijiRow(poem: card, kimariji: card.kimariji.substring(0, pair.kana)),
      ]),
    );
  }
}

/// Poem [id]'s stairs as its About page shows them, with whole kana only
/// for [kanaOnly].
class StairsFigure extends StatelessWidget {
  const StairsFigure(this.id, {super.key, this.kanaOnly = false});

  final int id;
  final bool kanaOnly;

  @override
  Widget build(BuildContext context) {
    final romaji = resolvedKimarijiScript(context) == KimarijiScript.romaji;
    return FigurePanel(
      child: SoundLadderView(
        poem: poems[id],
        kanaOnly: kanaOnly,
        romaji: romaji ? kimarijiFor(context, id) : null,
        onOpen: (_) {},
      ),
    );
  }
}
