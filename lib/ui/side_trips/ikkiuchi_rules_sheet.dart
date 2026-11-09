import 'package:flutter/material.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../domain/ikkiuchi_mode.dart';
import '../../domain/ikkiuchi_rating.dart';
import '../../l10n/ikkiuchi_strings.dart';
import '../../l10n/side_trip_strings.dart';
import '../../l10n/strings.dart';
import '../manga/manga.dart';
import '../play/time_format.dart';
import 'ankiren_rules_sheet.dart';
import 'trip_sheet.dart';

/// 一騎打ち's rules (遊び方) in a sheet, from its page.
Future<void> openIkkiuchiRules(BuildContext context) => showMangaSheet<void>(
      context,
      barrierColor: IkkiuchiPageLayout.barrier,
      barrierLabel: S.of(context).cancel,
      builder: (_) => const IkkiuchiRulesSheet(),
    );

/// The match, how it is won, 送り札, faults and からふだ; then ranked, its
/// modes ([IkkiuchiMode]), placement and rating, and custom matches, with
/// the numbers from [IkkiuchiRankedTuning] and [IkkiuchiMatchTuning]. Every
/// line has the other language's under it.
class IkkiuchiRulesSheet extends StatelessWidget {
  const IkkiuchiRulesSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final o = s.sub;
    const karafuda = IkkiuchiMatchTuning.karafuda;
    final modes = [for (final m in IkkiuchiMode.values) (perSide: m.perSide, memory: formatMinutes(m.memorise))];
    final matches = IkkiuchiRating.placementMatches;
    final start = IkkiuchiRating.start.round();
    return TripSheet(
      title: s.howToPlay,
      sub: o?.howToPlay,
      body: [
        RuleList([
          RuleItem(const RuleMark.image(RuleMarkFiles.tap), s.ikkiuchiRuleMatch, o?.ikkiuchiRuleMatch),
          RuleItem(const RuleMark.image(RuleMarkFiles.toEnd), s.ikkiuchiRuleWin, o?.ikkiuchiRuleWin),
          RuleItem(const RuleMark.image(RuleMarkFiles.cards), s.ikkiuchiRuleSend, o?.ikkiuchiRuleSend),
          RuleItem(const RuleMark.image(RuleMarkFiles.wrong), s.ikkiuchiRuleFault, o?.ikkiuchiRuleFault),
          RuleItem(const RuleMark.image(RuleMarkFiles.karafuda), s.ikkiuchiRuleKarafuda(karafuda.karafuda, karafuda.field),
              o?.ikkiuchiRuleKarafuda(karafuda.karafuda, karafuda.field)),
          RuleItem(RuleMark.text(Palette.pink, '${modes.length}'), s.ikkiuchiRuleRanked(modes),
              o?.ikkiuchiRuleRanked(modes)),
          RuleItem(RuleMark.text(Palette.sun, '$matches'), s.ikkiuchiRulePlacement(matches, start),
              o?.ikkiuchiRulePlacement(matches, start)),
          RuleItem(const RuleMark.image(RuleMarkFiles.early), s.ikkiuchiRuleRating, o?.ikkiuchiRuleRating),
          RuleItem(RuleMark.text(Palette.sun, s.ikkiuchiCustom), s.ikkiuchiRuleCustom, o?.ikkiuchiRuleCustom),
        ]),
      ],
    );
  }
}
