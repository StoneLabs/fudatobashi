import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../config/vector_art.dart';
import '../../domain/ankiren_field.dart';
import '../../domain/ankiren_game.dart';
import '../../domain/side_trips.dart';
import '../../domain/teiichi.dart';
import '../../domain/teiichi_placing.dart';
import '../../l10n/ankiren_strings.dart';
import '../../l10n/strings.dart';
import '../../l10n/teiichi_strings.dart';
import '../../state/progress.dart';
import '../../state/scope.dart';
import '../ankiren/ankiren_band.dart';
import '../ankiren/ankiren_card.dart';
import '../ankiren/ankiren_field_view.dart';
import '../ankiren/ankiren_play.dart';
import '../manga/manga.dart';
import '../sound/sounds.dart';
import 'teiichi_placing_layer.dart';
import 'teiichi_results_screen.dart';
import 'teiichi_zoom.dart';

/// 定位置's play screen, always landscape on 暗記練's true-scale field
/// ([AnkirenFieldView]), the own side alone, a row [TeiichiTuning.rowSlots]
/// pitches across, never rescaled. [setup]'s cards are dealt from [known]
/// into a face-up stack where the other player's side would be, and laid
/// out one at a time ([TeiichiPlacing], [TeiichiPlacingLayer]) while the
/// clock counts up. Done grows the field ([TeiichiZoom]), turns the cards
/// face down, and the game goes on as 暗記練's does ([AnkirenPlay]), to its
/// end; wrong taps only count. It ends into [TeiichiResultsScreen].
///
/// End while placing leaves without a game, after asking once a card is
/// placed; once the cards are face down,
/// the cards not found yet count as missed. The owner's games are recorded
/// once over; a guest's never are.
class TeiichiScreen extends StatefulWidget {
  const TeiichiScreen({
    super.key,
    required this.setup,
    required this.known,
    this.player = AnkirenPlayer.owner,
    this.seed,
  });

  final TeiichiSetup setup;

  /// The cards the stack is dealt from.
  final List<int> known;

  final AnkirenPlayer player;

  /// Seeds the deal and the order of the prompts; random when null.
  final int? seed;

  @override
  State<TeiichiScreen> createState() => _TeiichiScreenState();
}

class _TeiichiScreenState extends State<TeiichiScreen> with AnkirenPlay {
  late final Progress _progress;
  late final math.Random _rng;
  late final TeiichiPlacing _placing;
  AnkirenGame? _game;
  final DateTime _startedAt = DateTime.now();

  /// Placing times are read off [_clock]; [_shown] is what the band shows,
  /// whole seconds.
  final Stopwatch _clock = Stopwatch()..start();
  final ValueNotifier<Duration> _shown = ValueNotifier(Duration.zero);
  Timer? _tick;

  TeiichiDrag? _drag;
  bool _ending = false;

  /// Done is pressed: the field grows, cards still face up, then [_flip].
  bool _zoomed = false;
  Timer? _zoomTimer;

  @override
  AnkirenGame get game => _game!;

  bool get _placingNow => _game == null;

  /// Cards are placed and the player has not left: leaving throws the
  /// layout away, so it asks first.
  bool get _layoutAtStake => _placingNow && _placing.order.isNotEmpty;
  bool get _recorded => widget.player.recorded;

  @override
  void initState() {
    super.initState();
    _progress = ProgressScope.read(context);
    _rng = math.Random(widget.seed);
    final deck = {...widget.known}.toList()..shuffle(_rng);
    _placing = TeiichiPlacing(widget.setup, deck.take(widget.setup.cards).toList());
    holdStage(landscape: true);
    _tick = Timer.periodic(TeiichiPlayTuning.clockTick, (t) => _shown.value = TeiichiPlayTuning.clockTick * t.tick);
  }

  @override
  void dispose() {
    _tick?.cancel();
    _zoomTimer?.cancel();
    _shown.dispose();
    releaseStage();
    _leave();
    super.dispose();
  }

  /// The screen is going without End or Results: a game already played to
  /// its end is recorded without Results; anything else records nothing.
  void _leave() {
    if (_ending) return;
    _ending = true;
    _tick?.cancel();
    _zoomTimer?.cancel();
    stopRecall();
    final game = _game;
    if (_recorded && game != null && game.phase == AnkirenPhase.done) {
      unawaited(_progress.recordTeiichi(_placing, game, startedAt: _startedAt));
    }
  }

  Duration get _now => _clock.elapsed;

  void _placed() {
    playSound(context, Sfx.cardFlick);
    if (_progress.settings.haptics) unawaited(HapticFeedback.selectionClick());
  }

  /// A tap on a spot puts the stack's top card there.
  void _tap(Offset at, FieldPlacement placement) {
    final (x, y) = placement.onOwnHalf(at);
    final spot = TeiichiTargets(_placing.board).spotAt(x, y);
    if (spot == null || !_placing.placeTop(spot, _now)) return;
    setState(() {});
    _placed();
  }

  void _dragStart(int card, {required bool fromStack, required Offset at, required FieldPlacement placement}) =>
      setState(() => _drag = _dragAt(card, fromStack: fromStack, at: at, placement: placement));

  void _dragTo(Offset at, FieldPlacement placement) {
    final drag = _drag;
    if (drag == null) return;
    setState(() => _drag = _dragAt(drag.card, fromStack: drag.fromStack, at: at, placement: placement));
  }

  /// [card] dragged to [at]: the spot under the finger it may go, or the
  /// stack for a placed card.
  TeiichiDrag _dragAt(int card, {required bool fromStack, required Offset at, required FieldPlacement placement}) {
    if (!fromStack && stackRect(placement).inflate(TeiichiPlayLayout.stackMargin).contains(at)) {
      return TeiichiDrag(card: card, fromStack: false, at: at, onStack: true);
    }
    final (x, y) = placement.onOwnHalf(at);
    final spot = TeiichiTargets(_placing.board, moving: fromStack ? null : card).spotAt(x, y);
    return TeiichiDrag(card: card, fromStack: fromStack, at: at, spot: spot);
  }

  void _dragEnd() {
    final drag = _drag;
    if (drag == null) return;
    final spot = drag.spot;
    final moved = drag.onStack
        ? _placing.takeBack(drag.card, _now)
        : spot != null && (drag.fromStack ? _placing.placeTop(spot, _now) : _placing.move(drag.card, spot));
    setState(() => _drag = null);
    if (moved) _placed();
  }

  /// The board as it shows now: with a dragged card where it would land.
  TeiichiBoard get _shownBoard {
    final drag = _drag;
    final spot = drag?.spot;
    if (drag == null || spot == null) return _placing.board;
    return _placing.board.put(drag.card, spot) ?? _placing.board;
  }

  /// Every card is placed and the player is done: the clock stops, the
  /// field grows, then the cards turn face down and the first prompt
  /// follows.
  void _done() {
    if (!_placing.finish(_now)) return;
    _clock.stop();
    _tick?.cancel();
    _shown.value = _placing.placingTime!;
    setState(() {
      _drag = null;
      _zoomed = true;
    });
    _zoomTimer = Timer(stillMotion ? Duration.zero : TeiichiPlayLayout.zoomTime, _flip);
  }

  void _flip() {
    if (!mounted) return;
    setState(() => _game = _placing.recall(_rng));
    turnFaceDown(memorised: _placing.placingTime);
  }

  @override
  void recallOver() => unawaited(_finish());

  /// End, or the back gesture: while placing nothing has been played, so it
  /// just leaves, asking first once a card is placed; after, the cards not
  /// found yet count as missed.
  Future<void> _end() async {
    if (_ending) return;
    if (_placingNow) {
      if (_layoutAtStake && !await _confirmLeave()) return;
      if (_ending || !mounted) return;
      Navigator.of(context).pop();
      return;
    }
    game.end();
    unawaited(_finish());
  }

  Future<bool> _confirmLeave() async {
    final s = S.of(context);
    final leave = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(s.teiichiLeaveTitle),
        content: Text(s.teiichiLeaveNote),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(s.cancel)),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(s.ankirenLeave)),
        ],
      ),
    );
    return leave == true;
  }

  Future<void> _finish() async {
    if (_ending || !mounted) return;
    _ending = true;
    stopRecall();
    final bestBefore = _recorded ? _progress.sideTripsHub()[SideTrip.teiichi].placing.best : null;
    if (_recorded) await _progress.recordTeiichi(_placing, game, startedAt: _startedAt);
    // Left meanwhile: its route is on its way out, and replacing "the
    // current route" would replace the one under it.
    if (!mounted || ModalRoute.isCurrentOf(context) == false) return;
    wentToResults = true;
    AnkirenPlay.releaseOrientation();
    unawaited(Navigator.of(context).pushReplacement(MangaRoute<void>(
      builder: (_) =>
          TeiichiResultsScreen(placing: _placing, game: game, player: widget.player, bestBefore: bestBefore),
    )));
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final showNumber = _progress.settings.showPoemNumber;
    final placingNow = _placingNow;
    final editing = placingNow && !_zoomed;
    final allPlaced = _placing.allPlaced && _drag == null && !_zoomed;
    final band = AnkirenBand(
      landscape: true,
      leading: BandButton(icon: IconArt.end, label: s.end, onTap: _ending ? null : () => unawaited(_end())),
      center: placingNow || (asked == null && game.answers.isEmpty)
          ? MemoriseClock(left: _shown, landscape: true, label: editing ? s.teiichiPlacing : s.teiichiPlaced)
          : recallPrompt(landscape: true),
      trailing: placingNow
          ? BandButton(
              icon: IconArt.arrow,
              label: s.done,
              color: allPlaced ? Palette.sun : Palette.paper,
              dimmed: !allPlaced,
              onTap: allPlaced ? _done : null,
            )
          : dontKnowButton(),
    );
    final shownBoard = _shownBoard;
    return PopScope(
      canPop: !_layoutAtStake,
      onPopInvokedWithResult: (didPop, _) => didPop ? _leave() : unawaited(_end()),
      child: AnkirenTatami(
        child: AnkirenFieldView(
          field: placingNow ? AnkirenField(own: shownBoard.half, opponent: AnkirenHalf.empty()) : game.field,
          landscape: true,
          zoom: false,
          trueSlots: TeiichiTuning.rowSlots,
          roomAbove: TeiichiPlayLayout.roomAbove,
          move: _zoomed ? null : (stillMotion ? Duration.zero : TeiichiPlayLayout.move),
          growth: const FieldGrowth(
              limit: TeiichiZoom.limit, duration: TeiichiPlayLayout.zoomTime, curve: TeiichiPlayLayout.zoomCurve),
          grown: _zoomed,
          card: (poemId, side) => placingNow
              ? _laidCard(poemId, showNumber: showNumber)
              : recallCard(poemId, side, showNumber: showNumber),
          band: band,
          underlay: editing ? _spots : null,
          foreground: editing ? (placement) => _layer(placement, shownBoard, showNumber: showNumber) : null,
        ),
      ),
    );
  }

  /// A card laid out, face up; built as [recallCard] builds it, so that it
  /// turns over in place when the cards go face down. The card being
  /// dragged shows where it would land.
  Widget _laidCard(int poemId, {required bool showNumber}) {
    if (_drag?.card == poemId) return const _Landing();
    return Listener(
      behavior: HitTestBehavior.opaque,
      child: AnkirenCard(key: ValueKey(poemId), poemId: poemId, faceUp: true, inverted: false, showNumber: showNumber),
    );
  }

  /// The cards laid out as they show now, on screen.
  static Map<int, Rect> _laid(FieldPlacement placement) => {
        for (final MapEntry(key: id, value: r) in placement.geometry.half(FieldSide.own).entries)
          id: placement.rectOf(FieldSide.own, r),
      };

  /// The dashed spots the stack's top card, or the card dragged, may go.
  Widget _spots(FieldPlacement placement) {
    final drag = _drag;
    if (_placing.top == null && drag == null) return const SizedBox.shrink();
    final targets = TeiichiTargets(_placing.board, moving: drag == null || drag.fromStack ? null : drag.card);
    return TeiichiSpots(
      spots: [for (final (spot, r) in targets.freeSpots) (spot, placement.rectOf(FieldSide.own, r))],
      cards: [
        for (final MapEntry(key: id, value: r) in _laid(placement).entries)
          if (id != drag?.card) r,
      ],
    );
  }

  Widget _layer(FieldPlacement placement, TeiichiBoard shown, {required bool showNumber}) {
    final drag = _drag;
    final laid = _laid(placement);
    return TeiichiPlacingLayer(
      placement: placement,
      stack: _placing.stack,
      cards: {for (final MapEntry(key: id, value: r) in laid.entries) if (id != drag?.card) id: r},
      showHint: _placing.order.isEmpty && drag == null,
      drag: drag,
      landing: switch (drag) {
        TeiichiDrag(onStack: true) => S.of(context).teiichiStack,
        TeiichiDrag(:final card, spot: _?) => _spotName(shown, card),
        _ => null,
      },
      showNumber: showNumber,
      onTap: (at) => _tap(at, placement),
      onDragStart: (card, {required fromStack, required at}) =>
          _dragStart(card, fromStack: fromStack, at: at, placement: placement),
      onDrag: (at) => _dragTo(at, placement),
      onDragEnd: _dragEnd,
    );
  }

  /// Where [card] lies on [board]: its row and its part of it.
  String _spotName(TeiichiBoard board, int card) {
    final place = board.half.placeOf(card)!;
    return S.of(context).teiichiSpotName(place.row, place.part);
  }
}

/// Where a dragged card would land: sun over its spot, outlined in ink.
class _Landing extends StatelessWidget {
  const _Landing();

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: TeiichiPlayLayout.landingFill,
          border: Border.all(color: Palette.ink, width: TeiichiPlayLayout.landingBorder),
        ),
      );
}
