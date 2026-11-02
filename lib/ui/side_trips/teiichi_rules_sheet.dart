import 'package:flutter/material.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../domain/teiichi.dart';
import '../../l10n/ankiren_strings.dart';
import '../../l10n/karafuda_strings.dart';
import '../../l10n/side_trip_strings.dart';
import '../../l10n/strings.dart';
import '../../l10n/teiichi_strings.dart';
import '../../state/scope.dart';
import '../manga/manga.dart';
import '../play/time_format.dart';
import 'ankiren_rules_sheet.dart';
import 'ankiren_sheet.dart';

/// 定位置's rules (遊び方) in a sheet, from its page; once shown, the page
/// no longer opens with them.
Future<void> openTeiichiRules(BuildContext context) {
  final progress = ProgressScope.read(context);
  if (!progress.settings.teiichi.rulesSeen) {
    progress.updateSettings(progress.settings.copyWith(teiichi: progress.settings.teiichi.copyWith(rulesSeen: true)));
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
/// clock and what counts for the best time, the time limits, how the cards
/// are asked for, and how the levels, the custom level and ranked work, with
/// the numbers from [TeiichiTuning] and [AnkirenTuning]. Every line has the
/// other language's under it.
class TeiichiRulesSheet extends StatelessWidget {
  const TeiichiRulesSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final o = s.sub;
    const reveal = AnkirenTuning.revealAfterWrong, cards = TeiichiTuning.cards;
    const strikes = AnkirenTuning.strikesOut, ranked = TeiichiSetup.ranked();
    const customAfter = TeiichiTuning.customAfterLevel;
    const rankedAfter = TeiichiTuning.rankedAfterLevel;
    final limit = formatMinutes(ranked.limit!);
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
          RuleItem(const RuleMark.image(RuleMarkFiles.tap), s.teiichiRuleTap, o?.teiichiRuleTap),
          RuleItem(const RuleMark.image(RuleMarkFiles.width), s.teiichiRuleRow(row), o?.teiichiRuleRow(row)),
          RuleItem(const RuleMark.image(RuleMarkFiles.clock), s.teiichiRuleClock(cards), o?.teiichiRuleClock(cards)),
          RuleItem(const RuleMark.image(RuleMarkFiles.clock), s.teiichiRuleLimit, o?.teiichiRuleLimit),
          RuleItem(const RuleMark.image(RuleMarkFiles.wrong), s.ankirenRuleWrong, o?.ankirenRuleWrong),
          RuleItem(const RuleMark.text(Palette.sun, '$reveal'), s.ankirenRuleReveal(reveal), o?.ankirenRuleReveal(reveal)),
          RuleItem(const RuleMark.image(RuleMarkFiles.dontKnow), s.ankirenRuleDontKnow, o?.ankirenRuleDontKnow),
          RuleItem(const RuleMark.image(RuleMarkFiles.karafuda), s.karafudaRuleTeiichi, o?.karafudaRuleTeiichi),
          RuleItem(const RuleMark.image(RuleMarkFiles.toEnd), s.teiichiRuleToEnd, o?.teiichiRuleToEnd),
          RuleItem(const RuleMark.image(RuleMarkFiles.strikes), s.teiichiRuleStrikes(strikes), o?.teiichiRuleStrikes(strikes)),
          RuleItem(RuleMark.text(Palette.sun, s.ankirenCustom), s.teiichiRuleCustom(customAfter),
              o?.teiichiRuleCustom(customAfter)),
          RuleItem(const RuleMark.text(Palette.pink, '$cards'),
              s.teiichiRuleRanked(ranked.cards, ranked.rows, ranked.karafuda, limit, rankedAfter),
              o?.teiichiRuleRanked(ranked.cards, ranked.rows, ranked.karafuda, limit, rankedAfter)),
          RuleItem(const RuleMark.image(RuleMarkFiles.leave), s.teiichiRuleLeave, o?.teiichiRuleLeave),
          RuleItem(RuleMark.text(Palette.paper, s.ankirenMarkPoints), s.teiichiScoreNote, o?.teiichiScoreNote),
        ]),
      ],
    );
  }
}
