import 'package:flutter/material.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../config/vector_art.dart';
import '../../domain/ankiren_field.dart';
import '../../l10n/side_trip_strings.dart';
import '../../l10n/strings.dart';
import '../../state/scope.dart';
import '../manga/manga.dart';
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
/// wrong tap, giving up and leaving do, and how a game scores, with the
/// numbers from [AnkirenTuning]: a tap's points by where it lands in a
/// table. Every line has the other language's under it. It closes with ×,
/// a tap outside or Back.
class AnkirenRulesSheet extends StatelessWidget {
  const AnkirenRulesSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final o = s.other;
    final steps = [
      (AnkirenRulesLayout.memorise, s.ankirenStepMemorise, s.ankirenStepMemoriseLine, o.ankirenStepMemoriseLine),
      (AnkirenRulesLayout.flip, s.ankirenStepFlip, s.ankirenStepFlipLine, o.ankirenStepFlipLine),
      (AnkirenRulesLayout.take, s.ankirenStepTake, s.ankirenStepTakeLine, o.ankirenStepTakeLine),
    ];
    const reveal = AnkirenTuning.revealAfterWrong;
    const first = AnkirenTuning.cardPoints, speed = AnkirenTuning.speedMax;
    final second = (AnkirenTuning.tapWeights[1] * 100).round();
    final early = _number(1 + AnkirenTuning.earlyBonus);
    return AnkirenSheet(
      title: s.howToPlay,
      sub: o.howToPlay,
      body: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          for (final (i, (picture, name, line, sub)) in steps.indexed) ...[
            if (i > 0) const SizedBox(width: AnkirenRulesLayout.stepGap),
            Expanded(child: _Step(number: i + 1, picture: picture, name: name, line: line, sub: sub)),
          ],
        ]),
        _RuleList([
          _Rule(_Mark.icon(Palette.pinkSoft, IconArt.close), s.ankirenRuleWrong, o.ankirenRuleWrong),
          _Rule(const _Mark.text(Palette.sun, '$reveal'), s.ankirenRuleReveal(reveal), o.ankirenRuleReveal(reveal)),
          _Rule(_Mark.icon(Palette.desk, IconArt.question), s.ankirenRuleDontKnow, o.ankirenRuleDontKnow),
          _Rule(_Mark.icon(Palette.ink, IconArt.end), s.ankirenRuleLeave, o.ankirenRuleLeave),
        ]),
        SettingsSection(title: s.ankirenScoring, sub: o.ankirenScoring.toUpperCase(), children: [
          _RuleList([
            _Rule(_Mark.text(Palette.paper, s.ankirenMarkPoints), s.ankirenScoreFind(first, speed),
                o.ankirenScoreFind(first, speed)),
            _Rule(_Mark.icon(Palette.paper, IconArt.cards), s.ankirenScoreNear(second), o.ankirenScoreNear(second),
                below: const _TierTable()),
            _Rule(_Mark.icon(Palette.sun, IconArt.history), s.ankirenScoreEarly(early), o.ankirenScoreEarly(early)),
            _Rule(_Mark.text(Palette.paper, s.ankirenMarkLevel), s.ankirenScoreLevel, o.ankirenScoreLevel),
          ]),
        ]),
      ],
    );
  }

  /// A number as the rules print it: "0.25", or "2" when whole.
  static String _number(double x) {
    final rounded = double.parse(x.toStringAsFixed(AnkirenRulesLayout.shareDecimals));
    return rounded == rounded.roundToDouble() ? '${rounded.round()}' : '$rounded';
  }
}

/// What a tap earns by where it lands, nearest first: as the first tap (on
/// the card, plus its speed bonus) and as the second, weighted
/// ([AnkirenTuning.tapWeights]). Every name has the other language's under
/// it.
class _TierTable extends StatelessWidget {
  const _TierTable();

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final o = s.other;
    String points(TapProximity place, int tap) => AnkirenRulesSheet._number(
        AnkirenTuning.cardPoints * AnkirenTuning.tapShare[place]! * AnkirenTuning.tapWeights[tap]);
    Widget name(String line, String sub, {bool head = false, TextAlign align = TextAlign.start}) => Padding(
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
    const firstTap = 0, secondTap = 1;
    return Table(
      columnWidths: const {1: IntrinsicColumnWidth(), 2: IntrinsicColumnWidth()},
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        TableRow(children: [
          name(s.ankirenTierPlace, o.ankirenTierPlace, head: true),
          name(s.ankirenTierFirst, o.ankirenTierFirst, head: true, align: TextAlign.end),
          name(s.ankirenTierSecond, o.ankirenTierSecond, head: true, align: TextAlign.end),
        ]),
        for (final place in TapProximity.values)
          TableRow(decoration: rule, children: [
            name(s.ankirenTier(place), o.ankirenTier(place)),
            value(place == TapProximity.card ? s.ankirenTierSpeed(points(place, firstTap)) : points(place, firstTap)),
            value(points(place, secondTap)),
          ]),
      ],
    );
  }
}

/// One step of the game: its picture, its number and [name], then its
/// [line] and the other language's [sub] under it.
class _Step extends StatelessWidget {
  const _Step({required this.number, required this.picture, required this.name, required this.line, required this.sub});

  final int number;
  final String picture, name, line, sub;

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

  final String line, sub;
  final double fontSize, subFontSize;
  final FontWeight weight;
  final TextAlign align;

  @override
  Widget build(BuildContext context) => Text.rich(
        TextSpan(children: [
          Phrases.span(line),
          const TextSpan(text: '\n'),
          Phrases.span(sub,
              style: TextStyle(fontWeight: Weights.medium, fontSize: subFontSize, color: Palette.mute)),
        ]),
        textAlign: align,
        style: TextStyle(fontWeight: weight, fontSize: fontSize, height: AnkirenRulesLayout.lineHeight),
      );
}

/// What a list row is marked with: a box of [color] holding an icon, or
/// short text.
class _Mark extends StatelessWidget {
  const _Mark.icon(this.color, VectorArt this.icon) : text = null;
  const _Mark.text(this.color, String this.text) : icon = null;

  final Color color;
  final VectorArt? icon;
  final String? text;

  @override
  Widget build(BuildContext context) {
    final ink = color == Palette.ink ? Palette.paper : Palette.ink;
    final icon = this.icon;
    return Container(
      width: AnkirenRulesLayout.markBox,
      height: AnkirenRulesLayout.markBox,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: Palette.ink, width: AnkirenRulesLayout.markBorder),
      ),
      child: icon != null
          ? MangaIcon(icon, size: AnkirenRulesLayout.markIcon, color: ink, strokeWidth: AnkirenRulesLayout.markIconStroke)
          : FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(text!,
                  style: TextStyle(
                      fontFamily: Fonts.display, fontSize: AnkirenRulesLayout.markFont, height: 1, color: ink)),
            ),
    );
  }
}

/// A rule: its [mark], its [line] and the other language's [sub], and what
/// shows [below] them.
class _Rule {
  const _Rule(this.mark, this.line, this.sub, {this.below});

  final _Mark mark;
  final String line, sub;
  final Widget? below;
}

/// Rules, one a row, split by light rules.
class _RuleList extends StatelessWidget {
  const _RuleList(this.rules);

  final List<_Rule> rules;

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
