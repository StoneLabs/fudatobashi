import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../config/vector_art.dart';
import '../../config/yomifuda_spec.dart';
import '../../data/poem.dart';
import '../../l10n/card_info_strings.dart';
import '../../l10n/strings.dart';
import '../manga/manga.dart';
import '../torifuda/torifuda_painter.dart';
import '../torifuda/yomifuda_card.dart';

/// A poem's two cards: the taking card (取り札) and the reading card (読み札).
enum CardFace {
  taking,
  reading;

  CardFace get other => this == taking ? reading : taking;
}

/// A poem's two cards on a dotted desk, [front] in front and the other
/// tucked behind it. Dragging the front card follows the finger sideways;
/// let go far enough and it is thrown aside and the cards swap. A tap on the
/// card behind swaps them too. Either way [onSwap] hears the face to bring
/// forward, and the owner moves it to [front]. A SWIPE sticker sits in the
/// corner while [sticker] is on.
///
/// A waka with no taking card, such as the 序歌, has its reading card alone
/// ([CardPanel.readingOnly]): it drags the same, and a throw brings it back.
class CardPanel extends StatefulWidget {
  const CardPanel({
    super.key,
    required Poem this.poem,
    required this.front,
    required ValueChanged<CardFace> this.onSwap,
    required this.sticker,
  });

  /// [poem]'s reading card alone, with no sticker: there is no other card to
  /// swipe to.
  const CardPanel.readingOnly({super.key, required this.poem})
      : front = CardFace.reading,
        onSwap = null,
        sticker = false;

  final Waka poem;
  final CardFace front;

  /// Null when the reading card is alone.
  final ValueChanged<CardFace>? onSwap;
  final bool sticker;

  @override
  State<CardPanel> createState() => _CardPanelState();
}

/// Where a card sits: its offset from the panel's centre, its turn in
/// degrees and how much it is dimmed.
typedef _Pose = ({double x, double y, double turn, double dim});

class _CardPanelState extends State<CardPanel> {
  static final _Pose _frontPose =
      (x: AboutCardLayout.frontAt.dx, y: AboutCardLayout.frontAt.dy, turn: 0, dim: 0);
  static final _Pose _backPose = (
    x: AboutCardLayout.backAt.dx,
    y: AboutCardLayout.backAt.dy,
    turn: AboutCardLayout.backTurn,
    dim: 1 - AboutCardLayout.backBrightness,
  );

  /// How far the front card is dragged, while it is.
  double? _drag;
  double _dragFrom = 0;

  /// The side the front card is thrown to (−1 or 1), until the swap.
  double? _thrown;
  Timer? _swap;

  @override
  void dispose() {
    _swap?.cancel();
    super.dispose();
  }

  void _start(DragStartDetails details) {
    if (_thrown != null) return;
    _dragFrom = details.globalPosition.dx;
    setState(() => _drag = 0);
  }

  void _update(DragUpdateDetails details) {
    if (_drag == null) return;
    setState(() => _drag = details.globalPosition.dx - _dragFrom);
  }

  void _end() {
    final drag = _drag;
    if (drag == null) return;
    setState(() {
      _drag = null;
      if (drag.abs() > CardPanelTuning.throwDistance) _thrown = drag.sign;
    });
    if (_thrown == null) return;
    _swap = Timer(CardPanelTuning.swapDelay, () {
      if (!mounted) return;
      setState(() => _thrown = null);
      widget.onSwap?.call(widget.front.other);
    });
  }

  _Pose _poseOf(CardFace face) {
    if (face != widget.front) return _backPose;
    if (_thrown case final side?) {
      return (x: side * CardPanelTuning.throwTo, y: 0, turn: side * CardPanelTuning.throwTurn, dim: 0);
    }
    if (_drag case final drag?) {
      return (x: _frontPose.x + drag, y: _frontPose.y, turn: drag * CardPanelTuning.dragTurn, dim: 0);
    }
    return _frontPose;
  }

  Widget _card(CardFace face) {
    final front = face == widget.front;
    Widget card = SizedBox(
      width: AboutCardLayout.cardWidth,
      child: DecoratedBox(
        decoration: const BoxDecoration(boxShadow: [AboutCardLayout.cardShadow]),
        child: switch (face) {
          CardFace.taking => TorifudaCard(poem: widget.poem as Poem),
          CardFace.reading => YomifudaCard(poem: widget.poem),
        },
      ),
    );
    card = front
        ? GestureDetector(
            dragStartBehavior: DragStartBehavior.down,
            onHorizontalDragStart: _start,
            onHorizontalDragUpdate: _update,
            onHorizontalDragEnd: (_) => _end(),
            onHorizontalDragCancel: _end,
            child: card,
          )
        : GestureDetector(onTap: _thrown == null ? () => widget.onSwap?.call(face) : null, child: card);
    return TweenAnimationBuilder<_Pose>(
      key: ValueKey(face),
      tween: _PoseTween(end: _poseOf(face)),
      duration: front && _drag != null ? Duration.zero : CardPanelTuning.move,
      curve: CardPanelTuning.moveCurve,
      child: card,
      builder: (context, pose, child) => Transform.translate(
        offset: Offset(pose.x, pose.y),
        child: Transform.rotate(
          angle: pose.turn * math.pi / 180,
          child: Stack(children: [
            child!,
            if (pose.dim > 0)
              Positioned.fill(
                child: IgnorePointer(child: ColoredBox(color: Palette.ink.withValues(alpha: pose.dim))),
              ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    const border = AboutCardLayout.panelBorder;
    return Semantics(
      label: widget.front == CardFace.taking ? s.aboutTakingCard : s.aboutReadingCard,
      child: MangaPanel(
        color: Palette.desk,
        tone: AboutCardLayout.panelTone,
        border: border,
        shadow: const Offset(AboutCardLayout.panelShadow, AboutCardLayout.panelShadow),
        padding: const EdgeInsets.all(border),
        child: SizedBox(
          height: AboutCardLayout.panelHeight - 2 * border,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              if (widget.onSwap != null) _card(widget.front.other),
              _card(widget.front),
              Positioned(
                right: AboutCardLayout.stickerInset,
                bottom: AboutCardLayout.stickerInset,
                child: IgnorePointer(
                  child: AnimatedOpacity(
                    opacity: widget.sticker ? 1 : 0,
                    duration: AboutCardLayout.stickerFade,
                    child: Sticker(
                      tilt: AboutCardLayout.stickerTurn,
                      padding: AboutCardLayout.stickerPadding,
                      border: AboutCardLayout.stickerBorder,
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        MangaIcon(IconArt.swap,
                            size: AboutCardLayout.stickerIcon, strokeWidth: AboutCardLayout.stickerIconStroke),
                        const SizedBox(width: AboutCardLayout.stickerIconGap),
                        Text(s.aboutSwipe,
                            style: const TextStyle(
                                fontWeight: Weights.black,
                                fontSize: AboutCardLayout.stickerFont,
                                letterSpacing: AboutCardLayout.stickerFont * AboutCardLayout.stickerTracking)),
                      ]),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PoseTween extends Tween<_Pose> {
  _PoseTween({super.end});

  @override
  _Pose lerp(double t) => (
        x: lerpDouble(begin!.x, end!.x, t)!,
        y: lerpDouble(begin!.y, end!.y, t)!,
        turn: lerpDouble(begin!.turn, end!.turn, t)!,
        dim: lerpDouble(begin!.dim, end!.dim, t)!,
      );
}

/// The reading card's key, shown while it is in front: a swatch of the card
/// for each of its marks, two to a row.
class ReadingCardKey extends StatelessWidget {
  const ReadingCardKey({super.key, required this.poem});

  final Poem poem;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    const card = YomifudaStyle.standard;
    final glyph = TextStyle(
        fontFamily: card.fontFamily, fontSize: AboutCardLayout.keySwatchFont, height: 1, color: card.ink);
    final entries = [
      (Text(poem.kimariji.substring(0, 1), style: glyph.copyWith(color: card.kimariji)), s.aboutKeyKimariji),
      (
        SizedBox(
          width: AboutCardLayout.keyDashWidth,
          height: AboutCardLayout.keyDashHeight,
          child: ColoredBox(color: card.ink),
        ),
        s.aboutKeyHold
      ),
      (
        VectorArtBox(CardArt.yomifudaEnd, size: AboutCardLayout.keyEnd, color: card.ink),
        s.aboutKeyFade
      ),
      (
        Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(AboutCardLayout.keyGuideText, style: glyph),
          Text(AboutCardLayout.keyGuideReading, style: glyph.copyWith(fontSize: AboutCardLayout.keyRubyFont)),
        ]),
        s.aboutKeyGuide
      ),
    ];
    return LayoutBuilder(builder: (context, constraints) {
      final width = (constraints.maxWidth - AboutCardLayout.keyColumnGap) / 2;
      return Wrap(
        spacing: AboutCardLayout.keyColumnGap,
        runSpacing: AboutCardLayout.keyRowGap,
        children: [
          for (final (mark, label) in entries)
            SizedBox(
              width: width,
              child: Row(children: [
                Container(
                  width: AboutCardLayout.keySwatch.width,
                  height: AboutCardLayout.keySwatch.height,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AboutCardLayout.keySwatchPaper,
                    border: Border.all(color: AboutCardLayout.keySwatchEdge, width: AboutCardLayout.keySwatchBorder),
                  ),
                  child: MediaQuery.withNoTextScaling(child: mark),
                ),
                const SizedBox(width: AboutCardLayout.keyLabelGap),
                Expanded(
                  child: Text.rich(Phrases.span(label),
                      style: const TextStyle(
                          fontWeight: Weights.bold, fontSize: AboutCardLayout.keyFont, color: Palette.inkSoft)),
                ),
              ]),
            ),
        ],
      );
    });
  }
}
