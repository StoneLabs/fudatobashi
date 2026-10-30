import 'package:flutter/material.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../config/vector_art.dart';
import '../../l10n/side_trip_strings.dart';
import '../../l10n/strings.dart';
import '../../l10n/teiichi_strings.dart';
import '../../state/scope.dart';
import '../manga/manga.dart';
import 'ankiren_rules_sheet.dart';
import 'ankiren_sheet.dart';

/// 定位置's rules (遊び方) in a sheet, from its page; once shown, the page
/// no longer opens with them.
Future<void> openTeiichiRules(BuildContext context) {
  final progress = ProgressScope.read(context);
  if (!progress.settings.teiichiRulesSeen) {
    progress.updateSettings(progress.settings.copyWith(teiichiRulesSeen: true));
  }
  return showMangaSheet<void>(
    context,
    barrierColor: FreePracticeLayout.barrier,
    barrierLabel: S.of(context).cancel,
    builder: (_) => const TeiichiRulesSheet(),
  );
}

/// The game's three steps in pictures, as 暗記練's rules show them (placing,
/// then 暗記練's flip and take), then how placing works, a row's width, the
/// clock and what counts for the best time, and how the cards are asked
/// for, with the numbers from [TeiichiTuning] and [AnkirenTuning]. Every
/// line has the other language's under it.
class TeiichiRulesSheet extends StatelessWidget {
  const TeiichiRulesSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final o = s.sub;
    const reveal = AnkirenTuning.revealAfterWrong, cards = TeiichiTuning.cards;
    final row = '${TeiichiTuning.rowSlots}';
    return AnkirenSheet(
      title: s.howToPlay,
      sub: o?.howToPlay,
      body: [
        RulesSteps([
          (TeiichiRulesLayout.place, s.teiichiStepPlace, s.teiichiStepPlaceLine, o?.teiichiStepPlaceLine),
          (AnkirenRulesLayout.flip, s.ankirenStepFlip, s.ankirenStepFlipLine, o?.ankirenStepFlipLine),
          (AnkirenRulesLayout.take, s.ankirenStepTake, s.ankirenStepTakeLine, o?.ankirenStepTakeLine),
        ]),
        RuleList([
          RuleItem(RuleMark.icon(Palette.sun, IconArt.cards), s.teiichiRuleTap, o?.teiichiRuleTap),
          RuleItem(RuleMark.text(Palette.paper, row), s.teiichiRuleRow(row), o?.teiichiRuleRow(row)),
          RuleItem(RuleMark.icon(Palette.shallow, IconArt.history), s.teiichiRuleClock(cards), o?.teiichiRuleClock(cards)),
          RuleItem(RuleMark.icon(Palette.pinkSoft, IconArt.close), s.ankirenRuleWrong, o?.ankirenRuleWrong),
          RuleItem(const RuleMark.text(Palette.sun, '$reveal'), s.ankirenRuleReveal(reveal), o?.ankirenRuleReveal(reveal)),
          RuleItem(RuleMark.icon(Palette.desk, IconArt.question), s.ankirenRuleDontKnow, o?.ankirenRuleDontKnow),
          RuleItem(RuleMark.icon(Palette.land, IconArt.end), s.teiichiRuleToEnd, o?.teiichiRuleToEnd),
        ]),
      ],
    );
  }
}
