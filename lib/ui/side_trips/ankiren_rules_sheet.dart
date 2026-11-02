import 'package:flutter/material.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../domain/ankiren_field.dart';
import '../../domain/ankiren_level.dart';
import '../../l10n/karafuda_strings.dart';
import '../../l10n/side_trip_strings.dart';
import '../../l10n/strings.dart';
import '../../state/scope.dart';
import '../manga/manga.dart';
import '../play/time_format.dart';
import '../settings/settings_rows.dart';
import 'ankiren_sheet.dart';

/// 暗記練's rules (遊び方) in a sheet, from the hub or 暗記練's page; once
/// shown, the page no longer opens with them.
Future<void> openAnkirenRules(BuildContext context) {
  final progress = ProgressScope.read(context);
  final settings = progress.settings;
  if (!settings.ankiren.rulesSeen) {
    progress.updateSettings(settings.copyWith(ankiren: settings.ankiren.copyWith(rulesSeen: true)));
  }
  return showMangaSheet<void>(
    context,
    barrierColor: FreePracticeLayout.barrier,
    barrierLabel: S.of(context).cancel,
    builder: (_) => const AnkirenRulesSheet(),
  );
}

/// The game's three steps in pictures with a line on each, then what a
/// wrong tap, giving up and leaving do, how free play's strikes open its
/// levels, ranked's one setup, and how a game scores, with the numbers from
/// [AnkirenTuning]: a tap's points by where it lands in a table. Every line
/// has the other language's under it. It closes with ×, a tap outside or
/// Back.
class AnkirenRulesSheet extends StatelessWidget {
  const AnkirenRulesSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final o = s.sub;
    final steps = [
      (AnkirenRulesLayout.memorise, s.ankirenStepMemorise, s.ankirenStepMemoriseLine, o?.ankirenStepMemoriseLine),
      (AnkirenRulesLayout.flip, s.ankirenStepFlip, s.ankirenStepFlipLine, o?.ankirenStepFlipLine),
      (AnkirenRulesLayout.take, s.ankirenStepTake, s.ankirenStepTakeLine, o?.ankirenStepTakeLine),
    ];
    const reveal = AnkirenTuning.revealAfterWrong;
    final early = _number(1 + AnkirenTuning.earlyBonus);
    const strikes = AnkirenTuning.strikesOut;
    const perSide = AnkirenTuning.rankedPerSide, opensAt = AnkirenTuning.rankedAfterLevel;
    const karafudaFrom = AnkirenTuning.karafudaFromLevel, ranked = AnkirenSetup.ranked();
    final memorise = formatMinutes(AnkirenTuning.rankedMemorise);
    return AnkirenSheet(
      title: s.howToPlay,
      sub: o?.howToPlay,
      body: [
        RulesSteps(steps),
        RuleList([
          RuleItem(const RuleMark.image(RuleMarkFiles.wrong), s.ankirenRuleWrong, o?.ankirenRuleWrong),
          RuleItem(const RuleMark.text(Palette.sun, '$reveal'), s.ankirenRuleReveal(reveal), o?.ankirenRuleReveal(reveal)),
          RuleItem(const RuleMark.image(RuleMarkFiles.dontKnow), s.ankirenRuleDontKnow, o?.ankirenRuleDontKnow),
          RuleItem(const RuleMark.image(RuleMarkFiles.leave), s.ankirenRuleLeave, o?.ankirenRuleLeave),
          RuleItem(const RuleMark.image(RuleMarkFiles.strikes), s.ankirenRuleStrikes(strikes), o?.ankirenRuleStrikes(strikes)),
          RuleItem(const RuleMark.image(RuleMarkFiles.karafuda), s.karafudaRule(karafudaFrom), o?.karafudaRule(karafudaFrom)),
          RuleItem(const RuleMark.text(Palette.pink, '${2 * perSide}'),
              s.ankirenRuleRanked(perSide, memorise, opensAt, ranked.karafuda),
              o?.ankirenRuleRanked(perSide, memorise, opensAt, ranked.karafuda)),
        ]),
        SettingsSection(title: s.ankirenScoring, sub: o?.ankirenScoring.toUpperCase(), children: [
          RuleList([
            ...callScoring(s),
            RuleItem(const RuleMark.image(RuleMarkFiles.early), s.ankirenScoreEarly(early), o?.ankirenScoreEarly(early)),
            RuleItem(RuleMark.text(Palette.pink, s.ankirenMarkPoints), s.ankirenScoreLevel, o?.ankirenScoreLevel),
          ]),
        ]),
      ],
    );
  }

  /// How each call scores, in 暗記練 and in 定位置: a right first tap with
  /// its speed bonus, a tap that misses by where it lands (the tier table),
  /// and a からふだ.
  static List<RuleItem> callScoring(S s) {
    final o = s.sub;
    const first = AnkirenTuning.cardPoints, speed = AnkirenTuning.speedMax;
    final second = (AnkirenTuning.tapWeights[1] * 100).round();
    return [
      RuleItem(RuleMark.text(Palette.paper, s.ankirenMarkPoints), s.ankirenScoreFind(first, speed),
          o?.ankirenScoreFind(first, speed)),
      RuleItem(const RuleMark.image(RuleMarkFiles.cards), s.ankirenScoreNear(second), o?.ankirenScoreNear(second),
          below: const _TierTable()),
      RuleItem(const RuleMark.image(RuleMarkFiles.karafuda), s.karafudaScore, o?.karafudaScore),
    ];
  }

  /// A number as the rules print it: "0.25", or "2" when whole.
  static String _number(double x) {
    final rounded = double.parse(x.toStringAsFixed(AnkirenRulesLayout.shareDecimals));
    return rounded == rounded.roundToDouble() ? '${rounded.round()}' : '$rounded';
  }
}

/// What a tap earns by where it lands, nearest first: as the first tap (on
/// the card, plus its speed bonus) and as the second, weighted
/// ([AnkirenTuning.tapWeights]).
class _TierTable extends StatelessWidget {
  const _TierTable();

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final o = s.sub;
    String points(TapProximity place, int tap) => AnkirenRulesSheet._number(
        AnkirenTuning.cardPoints * AnkirenTuning.tapShare[place]! * AnkirenTuning.tapWeights[tap]);
    const firstTap = 0, secondTap = 1;
    return RulesTable(
      heads: [
        (s.ankirenTierPlace, o?.ankirenTierPlace),
        (s.ankirenTierFirst, o?.ankirenTierFirst),
        (s.ankirenTierSecond, o?.ankirenTierSecond),
      ],
      rows: [
        for (final place in TapProximity.values)
          (
            (s.ankirenTier(place), o?.ankirenTier(place)),
            [
              place == TapProximity.card ? s.ankirenTierSpeed(points(place, firstTap)) : points(place, firstTap),
              points(place, secondTap),
            ],
          ),
      ],
    );
  }
}

/// A table under a rule's line: a row of heads, then a row each split by
/// light rules, its name first and its values set to the right. Every head
/// and name has the other language's under it.
class RulesTable extends StatelessWidget {
  const RulesTable({super.key, required this.heads, required this.rows});

  /// Each column's head, and the head in the other language.
  final List<(String, String?)> heads;

  /// Each row's name, the name in the other language, and its values.
  final List<((String, String?), List<String>)> rows;

  @override
  Widget build(BuildContext context) {
    Widget name(String line, String? sub, {bool head = false, TextAlign align = TextAlign.start}) => Padding(
          padding: AnkirenRulesLayout.tierCellPadding,
          child: _Lines(line, sub,
              fontSize: head ? AnkirenRulesLayout.tierHeadFont : AnkirenRulesLayout.tierFont,
              subFontSize: AnkirenRulesLayout.tierSubFont,
              align: align),
        );
    Widget value(String text) => Padding(
          padding: AnkirenRulesLayout.tierCellPadding,
          child: Text(text,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: Weights.black, fontSize: AnkirenRulesLayout.tierFont)),
        );
    const rule = BoxDecoration(
      border: Border(top: BorderSide(color: AnkirenPageLayout.lightRule, width: AnkirenPageLayout.lightRuleWidth)),
    );
    return Table(
      columnWidths: {for (var i = 1; i < heads.length; i++) i: const IntrinsicColumnWidth()},
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        TableRow(children: [
          for (final (i, (line, sub)) in heads.indexed)
            name(line, sub, head: true, align: i == 0 ? TextAlign.start : TextAlign.end),
        ]),
        for (final ((line, sub), values) in rows)
          TableRow(decoration: rule, children: [name(line, sub), for (final v in values) value(v)]),
      ],
    );
  }
}

/// A game's steps side by side, numbered: each its picture, its name, and
/// its line with the other language's under it.
class RulesSteps extends StatelessWidget {
  const RulesSteps(this.steps, {super.key});

  /// Each step's picture, name, line and the line in the other language.
  final List<(String, String, String, String?)> steps;

  @override
  Widget build(BuildContext context) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        for (final (i, (picture, name, line, sub)) in steps.indexed) ...[
          if (i > 0) const SizedBox(width: AnkirenRulesLayout.stepGap),
          Expanded(child: RulesStep(number: i + 1, picture: picture, name: name, line: line, sub: sub)),
        ],
      ]);
}

/// One step of the game: its picture, its number and [name], then its
/// [line] and the other language's [sub] under it.
class RulesStep extends StatelessWidget {
  const RulesStep({super.key, required this.number, required this.picture, required this.name, required this.line, required this.sub});

  final int number;
  final String picture, name, line;
  final String? sub;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: AnkirenRulesLayout.pictureHeight,
            decoration: BoxDecoration(
              color: Palette.desk,
              border: Border.all(color: Palette.ink, width: AnkirenRulesLayout.pictureBorder),
            ),
            child: Image.asset(picture, filterQuality: FilterQuality.medium, excludeFromSemantics: true),
          ),
          const SizedBox(height: AnkirenRulesLayout.stepInnerGap),
          Row(children: [
            _Number(number),
            const SizedBox(width: AnkirenRulesLayout.stepInnerGap),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(name, style: const TextStyle(fontWeight: Weights.black, fontSize: AnkirenRulesLayout.stepFont)),
              ),
            ),
          ]),
          const SizedBox(height: AnkirenRulesLayout.stepInnerGap),
          _Lines(line, sub, fontSize: AnkirenRulesLayout.stepLineFont, subFontSize: AnkirenRulesLayout.stepSubFont),
        ],
      );
}

/// A step's number on an ink square.
class _Number extends StatelessWidget {
  const _Number(this.n);

  final int n;

  @override
  Widget build(BuildContext context) => SizedBox.square(
        dimension: AnkirenRulesLayout.numberBox,
        child: ColoredBox(
          color: Palette.ink,
          child: Center(
            child: Text('$n',
                style: const TextStyle(
                    fontFamily: Fonts.display, fontSize: AnkirenRulesLayout.numberFont, height: 1, color: Palette.paper)),
          ),
        ),
      );
}

/// A [line] in the UI's language, and the other language's [sub] under it
/// in lighter type.
class _Lines extends StatelessWidget {
  const _Lines(this.line, this.sub,
      {required this.fontSize, required this.subFontSize, this.weight = Weights.bold, this.align = TextAlign.start});

  final String line;
  final String? sub;
  final double fontSize, subFontSize;
  final FontWeight weight;
  final TextAlign align;

  @override
  Widget build(BuildContext context) => Text.rich(
        TextSpan(children: [
          Phrases.span(line),
          if (sub != null) ...[
            const TextSpan(text: '\n'),
            Phrases.span(sub!,
                style: TextStyle(fontWeight: Weights.medium, fontSize: subFontSize, color: Palette.mute)),
          ],
        ]),
        textAlign: align,
        style: TextStyle(fontWeight: weight, fontSize: fontSize, height: AnkirenRulesLayout.lineHeight),
      );
}

/// What a list row is marked with: an image of a box holding an icon, or
/// a box of [color] holding short [text] (numbers that follow the tuning).
class RuleMark extends StatelessWidget {
  const RuleMark.image(String this.asset, {super.key})
      : color = null,
        text = null;
  const RuleMark.text(Color this.color, String this.text, {super.key}) : asset = null;

  final String? asset;
  final Color? color;
  final String? text;

  @override
  Widget build(BuildContext context) {
    final asset = this.asset;
    if (asset != null) {
      return Image.asset(asset,
          width: AnkirenRulesLayout.markBox,
          height: AnkirenRulesLayout.markBox,
          filterQuality: FilterQuality.medium,
          excludeFromSemantics: true);
    }
    final color = this.color!;
    return Container(
      width: AnkirenRulesLayout.markBox,
      height: AnkirenRulesLayout.markBox,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: Palette.ink, width: AnkirenRulesLayout.markBorder),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(text!,
            style: TextStyle(
                fontFamily: Fonts.display,
                fontSize: AnkirenRulesLayout.markFont,
                height: 1,
                color: color == Palette.ink ? Palette.paper : Palette.ink)),
      ),
    );
  }
}

/// A rule: its [mark], its [line] and the other language's [sub], and what
/// shows [below] them.
class RuleItem {
  const RuleItem(this.mark, this.line, this.sub, {this.below});

  final RuleMark mark;
  final String line;
  final String? sub;
  final Widget? below;
}

/// Rules, one a row, split by light rules.
class RuleList extends StatelessWidget {
  const RuleList(this.rules, {super.key});

  final List<RuleItem> rules;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, rule) in rules.indexed) ...[
            if (i > 0)
              const SizedBox(
                height: AnkirenPageLayout.lightRuleWidth,
                child: ColoredBox(color: AnkirenPageLayout.lightRule),
              ),
            Padding(
              padding: AnkirenRulesLayout.rowPadding,
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                rule.mark,
                const SizedBox(width: AnkirenRulesLayout.markGap),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    _Lines(rule.line, rule.sub,
                        fontSize: AnkirenRulesLayout.ruleLineFont,
                        subFontSize: AnkirenRulesLayout.ruleSubFont,
                        weight: Weights.black),
                    if (rule.below case final below?) ...[
                      const SizedBox(height: AnkirenRulesLayout.belowGap),
                      below,
                    ],
                  ]),
                ),
              ]),
            ),
          ],
        ],
      );
}
