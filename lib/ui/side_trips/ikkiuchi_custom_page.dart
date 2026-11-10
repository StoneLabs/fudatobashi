import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../config/vector_art.dart';
import '../../domain/ikkiuchi_layout.dart';
import '../../domain/ikkiuchi_record.dart';
import '../../domain/rank_ladder.dart';
import '../../l10n/ikkiuchi_strings.dart';
import '../../l10n/ranked_strings.dart';
import '../../l10n/strings.dart';
import '../../state/scope.dart';
import '../ikkiuchi/ikkiuchi_field_picture.dart';
import '../ikkiuchi/ikkiuchi_match_screen.dart';
import '../manga/manga.dart';
import '../play/time_format.dart';
import 'burst_button.dart';

/// The guest's last setup, while the app runs.
IkkiuchiSetup _guestSetup = IkkiuchiSetup.firstFree;

/// Opens 一騎打ち's custom page ([IkkiuchiCustomPage]) on the last free
/// match's setup, or the first free match's before any; for a [guest], on
/// the guest's last setup.
Future<void> openIkkiuchiCustom(BuildContext context, {bool guest = false}) =>
    Navigator.of(context).push(MangaRoute<void>(
        builder: (_) => IkkiuchiCustomPage(
            initial: guest ? _guestSetup : ProgressScope.read(context).ikkiuchi.freeSetup, guest: guest)));

/// 一騎打ち's custom page: a free match's setup, from [initial], in one
/// panel under the header with back. Tobi's rating: a key for each of
/// [IkkiuchiFreeTuning.ratingClasses] (its class's threshold on the shared
/// class scale) over a stepper for any rating. The cards a side: keys over
/// a stepper. The rows: a key for each, with the most cards a side it
/// takes; those the cards do not fit (`IkkiuchiLayout.rowsAllowed`) are
/// shut, and a line under them says why. A change of cards the rows no
/// longer fit moves them to the fewest that do. The memory time: a
/// stepper. Each setting's keys are joined in one bar, and a stepper's
/// button held down steps on. Then the setup in brief beside a picture of
/// its field, and the burst that starts the match. Home's dotted ground,
/// in the sea's blue, lies behind the panel; the page scrolls when it is
/// taller than the screen.
///
/// For a [guest] it is guest mode: its title says so, a line under it
/// says the match records nothing, and the burst starts a guest's match,
/// its setup kept as the guest's last.
class IkkiuchiCustomPage extends StatefulWidget {
  const IkkiuchiCustomPage({super.key, required this.initial, this.guest = false});

  final IkkiuchiSetup initial;
  final bool guest;

  @override
  State<IkkiuchiCustomPage> createState() => _IkkiuchiCustomPageState();
}

class _IkkiuchiCustomPageState extends State<IkkiuchiCustomPage> {
  late double _rating = _clampRating(widget.initial.opponentRating);
  late int _perSide = widget.initial.perSide.clamp(IkkiuchiFreeTuning.perSideMin, IkkiuchiFreeTuning.perSideMax);
  late int _rows = _fitting(widget.initial.rows, _perSide);
  late Duration _memorise = Duration(
      microseconds: widget.initial.memorise.inMicroseconds.clamp(
          IkkiuchiFreeTuning.memoriseMin.inMicroseconds, IkkiuchiFreeTuning.memoriseMax.inMicroseconds));

  /// The rows a side may be laid out in, fewest first.
  static final _rowChoices = [for (var r = 1; r <= IkkiuchiLayoutTuning.rows; r++) r];

  static double _clampRating(double r) => r.clamp(IkkiuchiFreeTuning.ratingMin, IkkiuchiFreeTuning.ratingMax);

  /// The rating a class's key sets: its threshold, held in Tobi's range.
  static double _ratingOf(RankBand band) => _clampRating(band.minRating.roundToDouble());

  /// [rows] when a side of [perSide] cards fits them, else the fewest rows
  /// it fits.
  static int _fitting(int rows, int perSide) => IkkiuchiLayout.rowsAllowed(perSide, rows)
      ? rows
      : _rowChoices.firstWhere((r) => IkkiuchiLayout.rowsAllowed(perSide, r));

  /// The most cards a side [rows] rows take on this page.
  static int _upTo(int rows) => switch (rows) {
        1 => IkkiuchiLayoutTuning.oneRowUpTo,
        2 => IkkiuchiLayoutTuning.twoRowsUpTo,
        _ => IkkiuchiFreeTuning.perSideMax,
      };

  IkkiuchiSetup get _setup =>
      IkkiuchiSetup.free(opponentRating: _rating, perSide: _perSide, memorise: _memorise, rows: _rows);

  void _setPerSide(int n) => setState(() {
        _perSide = n;
        _rows = _fitting(_rows, n);
      });

  void _start() {
    final setup = _setup;
    if (widget.guest) _guestSetup = setup;
    startIkkiuchiMatch(context, setup, guest: widget.guest);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final o = s.sub;
    const keyTop = TextStyle(fontFamily: Fonts.display, fontSize: IkkiuchiCustomLayout.keyFont);
    const keySub = TextStyle(fontWeight: Weights.bold, fontSize: IkkiuchiCustomLayout.keySubFont);
    const value = TextStyle(fontFamily: Fonts.display, fontSize: IkkiuchiCustomLayout.valueFont);
    const unit = TextStyle(fontWeight: Weights.black, fontSize: IkkiuchiCustomLayout.unitFont);
    const fine = TextStyle(fontWeight: Weights.bold, fontSize: IkkiuchiCustomLayout.fineFont, color: Palette.mute);
    const why = TextStyle(
        fontWeight: Weights.bold,
        fontSize: IkkiuchiCustomLayout.whyFont,
        height: IkkiuchiCustomLayout.whyLineHeight,
        leadingDistribution: TextLeadingDistribution.even,
        color: Palette.mute);
    const whyNumber = TextStyle(fontFamily: Fonts.display, fontWeight: Weights.regular, color: Palette.ink);
    const gap = SizedBox(height: IkkiuchiCustomLayout.barGap);
    final bands = [
      for (final id in IkkiuchiFreeTuning.ratingClasses) RankLadder.bands.firstWhere((b) => b.id == id),
    ];
    final fewest = _fitting(1, _perSide);
    return Scaffold(
      body: Stack(children: [
        const Positioned.fill(child: GradationBox(Tones.homeSea)),
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
                Gaps.gutter, HeaderStyle.topGap, Gaps.gutter, IkkiuchiCustomLayout.bottomGap),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              MangaHeader(
                title: widget.guest
                    ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        ScreenTitle(s.ikkiuchiGuestMode, sub: s.ikkiuchiGuestTag),
                        const SizedBox(height: IkkiuchiCustomLayout.guestLineGap),
                        Text.rich(
                          Phrases.span(s.ikkiuchiGuestLine),
                          style: const TextStyle(
                              fontWeight: Weights.bold, fontSize: IkkiuchiCustomLayout.guestLineFont, color: Palette.mute),
                        ),
                      ])
                    : ScreenTitle(s.ikkiuchiCustom, sub: s.ikkiuchiCustomTag),
                actions: [
                  InkIconButton(icon: IconArt.back, semanticLabel: s.back, onTap: () => Navigator.maybePop(context)),
                ],
              ),
              const SizedBox(height: IkkiuchiCustomLayout.panelTop),
              MangaPanel(
                shape: const PanelShape(topLeft: Offset(0, IkkiuchiCustomLayout.cut)),
                padding: EdgeInsets.only(
                    top: IkkiuchiCustomLayout.padding.top, bottom: IkkiuchiCustomLayout.padding.bottom),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Padding(
                    padding: EdgeInsets.only(
                        left: IkkiuchiCustomLayout.padding.left, right: IkkiuchiCustomLayout.padding.right),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      _Label(s.ikkiuchiTobiRating, o?.ikkiuchiTobiRating),
                      gap,
                      _KeyBar([
                        for (final band in bands)
                          _BarKey(
                            semanticLabel: '${s.className(band)} ${_ratingOf(band).round()}',
                            chosen: _rating == _ratingOf(band),
                            onTap: () => setState(() => _rating = _ratingOf(band)),
                            top: Text(s.className(band), style: keyTop),
                            bottom: Text('${_ratingOf(band).round()}', style: keySub),
                          ),
                      ]),
                      gap,
                      _Stepper(
                        label: Text(s.ikkiuchiFineTune, style: fine),
                        value: Text('${_rating.round()}', style: value),
                        onLess: _rating > IkkiuchiFreeTuning.ratingMin
                            ? () => setState(() => _rating = _clampRating(_rating - IkkiuchiFreeTuning.ratingStep))
                            : null,
                        onMore: _rating < IkkiuchiFreeTuning.ratingMax
                            ? () => setState(() => _rating = _clampRating(_rating + IkkiuchiFreeTuning.ratingStep))
                            : null,
                      ),
                      const _Split(),
                      _Label(s.ikkiuchiCardsPerSide, o?.ikkiuchiCardsPerSide),
                      gap,
                      _KeyBar([
                        for (final n in IkkiuchiFreeTuning.perSideKeys)
                          _BarKey(
                            semanticLabel: '$n',
                            chosen: _perSide == n,
                            onTap: () => _setPerSide(n),
                            top: Text('$n', style: keyTop),
                          ),
                      ]),
                      gap,
                      _Stepper(
                        label: Text(s.ikkiuchiFineTune, style: fine),
                        value: NumberedText(s.ikkiuchiPerSideCount, [_perSide], style: unit, numberStyle: value),
                        onLess: _perSide > IkkiuchiFreeTuning.perSideMin
                            ? () => _setPerSide(_perSide - IkkiuchiFreeTuning.perSideStep)
                            : null,
                        onMore: _perSide < IkkiuchiFreeTuning.perSideMax
                            ? () => _setPerSide(_perSide + IkkiuchiFreeTuning.perSideStep)
                            : null,
                      ),
                      const _Split(),
                      _Label(s.ikkiuchiRows, o?.ikkiuchiRows),
                      gap,
                      _KeyBar(height: IkkiuchiCustomLayout.rowKeyHeight, [
                        for (final r in _rowChoices)
                          _BarKey(
                            semanticLabel: '${s.ikkiuchiRowsKey(r)} ${s.ikkiuchiRowsUpTo(_upTo(r))}',
                            chosen: _rows == r,
                            onTap: IkkiuchiLayout.rowsAllowed(_perSide, r) ? () => setState(() => _rows = r) : null,
                            top: Text(s.ikkiuchiRowsKey(r), style: keyTop),
                            bottom: Text(s.ikkiuchiRowsUpTo(_upTo(r)), style: keySub),
                          ),
                      ]),
                      const SizedBox(height: IkkiuchiCustomLayout.whyGap),
                      switch (fewest) {
                        1 => Text(s.ikkiuchiRowsAny(IkkiuchiLayoutTuning.oneRowUpTo), style: why),
                        2 => NumberedText(s.ikkiuchiRowsFromTwo(IkkiuchiLayoutTuning.oneRowUpTo), [_perSide],
                            style: why, numberStyle: whyNumber),
                        _ => NumberedText(
                            s.ikkiuchiRowsOnlyThree(IkkiuchiLayoutTuning.twoRowsUpTo, IkkiuchiLayoutTuning.oneRowUpTo),
                            [_perSide],
                            style: why,
                            numberStyle: whyNumber),
                      },
                      const _Split(),
                      _Stepper(
                        label: _Label(s.ikkiuchiMemoryTime, o?.ikkiuchiMemoryTime, under: true),
                        value: Text(formatMinutes(_memorise), style: value),
                        onLess: _memorise > IkkiuchiFreeTuning.memoriseMin
                            ? () => setState(() => _memorise -= IkkiuchiFreeTuning.memoriseStep)
                            : null,
                        onMore: _memorise < IkkiuchiFreeTuning.memoriseMax
                            ? () => setState(() => _memorise += IkkiuchiFreeTuning.memoriseStep)
                            : null,
                      ),
                      const SizedBox(height: IkkiuchiCustomLayout.summaryTop),
                      _Summary(_setup),
                    ]),
                  ),
                  Padding(
                    padding: IkkiuchiCustomLayout.burstMargin,
                    child: BurstButton(
                      title: s.ikkiuchiPlayCards(_perSide),
                      onTap: _start,
                    ),
                  ),
                ]),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}

/// A setting's label, with the other language's [sub] in tracked capitals
/// after it, or [under] it.
class _Label extends StatelessWidget {
  const _Label(this.text, this.sub, {this.under = false});

  final String text;
  final String? sub;
  final bool under;

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(fontWeight: Weights.black, fontSize: IkkiuchiCustomLayout.labelFont);
    final main = Text(text, style: style, softWrap: false);
    final sub = this.sub;
    final small = sub == null
        ? null
        : Text(
            sub.toUpperCase(),
            softWrap: false,
            style: const TextStyle(
              fontWeight: Weights.black,
              fontSize: IkkiuchiCustomLayout.labelSubFont,
              letterSpacing: IkkiuchiCustomLayout.labelSubTracking,
            ),
          );
    if (under) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        main,
        if (small != null) ...[const SizedBox(height: IkkiuchiCustomLayout.memorySubGap), small],
      ]);
    }
    return SizedBox(
      height: IkkiuchiCustomLayout.labelHeight,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            main,
            if (small != null) ...[
              const SizedBox(width: IkkiuchiCustomLayout.labelSubGap),
              Flexible(child: small),
            ],
          ],
        ),
      ),
    );
  }
}

/// [keys] joined in one bar, each [height] tall, ink rules between them.
class _KeyBar extends StatelessWidget {
  const _KeyBar(this.keys, {this.height = IkkiuchiCustomLayout.keyHeight});

  final List<Widget> keys;
  final double height;

  @override
  Widget build(BuildContext context) => Container(
        height: height + 2 * IkkiuchiCustomLayout.barBorder,
        decoration: BoxDecoration(
          color: Palette.paper,
          border: Border.all(color: Palette.ink, width: IkkiuchiCustomLayout.barBorder),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          for (final (i, key) in keys.indexed) ...[
            if (i > 0) const SizedBox(width: IkkiuchiCustomLayout.keyRule, child: ColoredBox(color: Palette.ink)),
            Expanded(child: key),
          ],
        ]),
      );
}

/// One key of a bar: [top] over [bottom]; sun-lit in an ink ring when
/// [chosen]; hatched and grey under a lock, shut, without [onTap]. It
/// stamps when pressed.
class _BarKey extends StatelessWidget {
  const _BarKey({required this.semanticLabel, required this.chosen, required this.onTap, required this.top, this.bottom});

  final String semanticLabel;
  final bool chosen;
  final VoidCallback? onTap;
  final Widget top;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    final shut = onTap == null;
    final bottom = this.bottom;
    return Semantics(
      selected: chosen,
      child: _Stamps(
        onTap: onTap,
        semanticLabel: semanticLabel,
        child: Stack(fit: StackFit.passthrough, children: [
          Positioned.fill(
            child: shut
                ? const CustomPaint(painter: _HatchPainter())
                : ColoredBox(color: chosen ? IkkiuchiCustomLayout.chosen : Palette.paper),
          ),
          Container(
            alignment: Alignment.center,
            foregroundDecoration: chosen
                ? BoxDecoration(border: Border.all(color: Palette.ink, width: IkkiuchiCustomLayout.chosenRing))
                : null,
            child: DefaultTextStyle.merge(
              style: TextStyle(height: 1, color: shut ? IkkiuchiCustomLayout.shut : Palette.ink),
              softWrap: false,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  top,
                  if (bottom != null) ...[const SizedBox(height: IkkiuchiCustomLayout.keySubGap), bottom],
                ]),
              ),
            ),
          ),
          if (shut)
            Positioned(
              top: IkkiuchiCustomLayout.lockInset.dy,
              right: IkkiuchiCustomLayout.lockInset.dx,
              child: MangaIcon(IconArt.lock,
                  size: IkkiuchiCustomLayout.lockSize,
                  strokeWidth: IkkiuchiCustomLayout.lockStroke,
                  color: IkkiuchiCustomLayout.shut),
            ),
        ]),
      ),
    );
  }
}

/// [child], which flashes the ink stamp while pressed and stays put; inert
/// without [onTap].
class _Stamps extends StatelessWidget {
  const _Stamps({required this.onTap, required this.semanticLabel, required this.child});

  final VoidCallback? onTap;
  final String semanticLabel;
  final Widget child;

  @override
  Widget build(BuildContext context) => Pressable(
        onTap: onTap,
        drop: 0,
        scale: 1,
        turn: 0,
        semanticLabel: semanticLabel,
        builder: (context, pressed) => Stack(fit: StackFit.passthrough, children: [
          child,
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedOpacity(
                opacity: pressed ? Tones.stampOpacity : 0,
                duration: Motion.stampFade,
                child: const ToneBox(Tones.stamp),
              ),
            ),
          ),
        ]),
      );
}

/// A shut key's hatching: light bands with darker lines between them,
/// rising to the right.
class _HatchPainter extends CustomPainter {
  const _HatchPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = IkkiuchiCustomLayout.hatchLight);
    // The bands run along x + y, so measured along x a band and a line are
    // √2 times wider than across them.
    const band = IkkiuchiCustomLayout.hatchBand * math.sqrt2;
    const line = IkkiuchiCustomLayout.hatchLine * math.sqrt2;
    final lines = Path();
    for (var at = band; at - line < size.width + size.height; at += band + line) {
      lines
        ..moveTo(at, 0)
        ..lineTo(at + line, 0)
        ..lineTo(at + line - size.height, size.height)
        ..lineTo(at - size.height, size.height)
        ..close();
    }
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.drawPath(lines, Paint()..color = IkkiuchiCustomLayout.hatchDark);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_HatchPainter old) => false;
}

/// A stepper: its [label] at the left, which gives way first, then − value
/// + joined in one outline; an end reached greys its button. A button held
/// down steps on by itself until it is let go or its end is reached.
class _Stepper extends StatelessWidget {
  const _Stepper({required this.label, required this.value, required this.onLess, required this.onMore});

  final Widget label, value;
  final VoidCallback? onLess, onMore;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    const rule = SizedBox(width: IkkiuchiCustomLayout.keyRule, child: ColoredBox(color: Palette.ink));
    Widget button(String sign, String name, VoidCallback? onTap) => SizedBox(
          width: IkkiuchiCustomLayout.stepperButton - IkkiuchiCustomLayout.keyRule,
          child: RepeatsHeld(
            onTap: onTap,
            every: IkkiuchiCustomLayout.repeatEvery,
            child: _Stamps(
              onTap: onTap,
              semanticLabel: name,
              child: ColoredBox(
                color: onTap == null ? Palette.desk : Palette.paper,
                child: Center(
                  child: Text(sign,
                      style: const TextStyle(fontFamily: Fonts.display, fontSize: IkkiuchiCustomLayout.signFont, height: 1)),
                ),
              ),
            ),
          ),
        );
    return Row(children: [
      Expanded(child: label),
      Container(
        height: IkkiuchiCustomLayout.stepperHeight,
        decoration: BoxDecoration(
          color: Palette.paper,
          border: Border.all(color: Palette.ink, width: IkkiuchiCustomLayout.barBorder),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          button('−', s.ikkiuchiLess, onLess),
          rule,
          SizedBox(
            width: IkkiuchiCustomLayout.stepperValueWidth,
            child: Center(child: FittedBox(fit: BoxFit.scaleDown, child: value)),
          ),
          rule,
          button('+', s.ikkiuchiMore, onMore),
        ]),
      ),
    ]);
  }
}

/// A rule between two settings.
class _Split extends StatelessWidget {
  const _Split();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.only(top: IkkiuchiCustomLayout.splitAbove, bottom: IkkiuchiCustomLayout.splitBelow),
        child: SizedBox(height: IkkiuchiCustomLayout.splitHeight, child: ColoredBox(color: IkkiuchiCustomLayout.split)),
      );
}

/// The setup in brief: a picture of its field, then its cards a side and
/// rows over its memory time and Tobi's rating.
class _Summary extends StatelessWidget {
  const _Summary(this.setup);

  final IkkiuchiSetup setup;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    const style = TextStyle(
        fontWeight: Weights.bold,
        fontSize: IkkiuchiCustomLayout.summaryFont,
        height: IkkiuchiCustomLayout.summaryLineHeight,
        color: Palette.mute);
    const number = TextStyle(
        fontFamily: Fonts.display,
        fontWeight: Weights.regular,
        fontSize: IkkiuchiCustomLayout.summaryNumberFont,
        color: Palette.ink);
    return Row(children: [
      SizedBox.fromSize(
        size: IkkiuchiCustomLayout.picture,
        child: IkkiuchiFieldPicture(setup.perSide, rows: setup.rows),
      ),
      const SizedBox(width: IkkiuchiCustomLayout.summaryGap),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          NumberedText(s.ikkiuchiCustomCards(setup.rows), [setup.perSide, setup.rows],
              style: style, numberStyle: number),
          NumberedText(s.ikkiuchiCustomTimes, [formatMinutes(setup.memorise), setup.opponentRating.round()],
              style: style, numberStyle: number),
        ]),
      ),
    ]);
  }
}
