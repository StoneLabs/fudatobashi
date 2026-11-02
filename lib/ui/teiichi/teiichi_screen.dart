import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../config/vector_art.dart';
import '../../domain/ankiren_field.dart';
import '../../domain/ankiren_game.dart';
import '../../domain/karafuda.dart';
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
import '../debug/readout_frame.dart';
import '../debug/teiichi_score_readout.dart';
import '../manga/manga.dart';
import 'teiichi_placing_layer.dart';
import 'teiichi_results_screen.dart';
import 'teiichi_turn_tip.dart';
import 'teiichi_zoom.dart';

/// 定位置's play screen, on 暗記練's true-scale field ([AnkirenFieldView]),
/// the own side alone across the foot of the screen, a row
/// [TeiichiTuning.rowSlots] pitches across, never rescaled. [setup]'s cards
/// are dealt from [known] into a face-up stack where the other player's
/// side would be, and laid out one at a time ([TeiichiPlacing],
/// [TeiichiPlacingLayer]) while the clock counts up, or down from the
/// setup's limit. Done, or the limit running out, grows the field
/// ([TeiichiZoom]), turns the cards face down, and the game goes on as
/// 暗記練's does ([AnkirenPlay]), the setup's からふだ, drawn from the other
/// known cards ([KarafudaPicker]) but never from the cards left in the
/// stack, among the cards, to its end; with no card laid out it ends there.
/// The owner's level games count strikes, each card left in the stack one
/// from the start (see [AnkirenStrikes]). With からふだ, or strikes on a
/// portrait screen, the band rises from then on, for "don't know" over the
/// からふだ button and the strikes over End. It ends into
/// [TeiichiResultsScreen].
///
/// The screen turns sideways for the game, or follows the phone without
/// the auto turn (`TeiichiSettings.autoTurn`); either way it is laid out
/// for the shape it has. Turned mid-game it keeps everything but a drag
/// under way, whose card goes back. Laying out on a portrait screen, it
/// tips the player once a game to turn the phone ([showTeiichiTurnTip]),
/// the clock stopped meanwhile; never in a ranked game, whose placing time
/// is the real time from the deal to the flip.
///
/// End while placing leaves without a game, after asking once a card is
/// placed; once the cards are face down,
/// the cards not found yet count as missed. A ranked game is a forfeit from
/// the deal on: leaving it asks first, then records it at 0. The owner's
/// games are recorded once over; a guest's never are.
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
  late final List<int> _deal;
  late final TeiichiPlacing _placing;
  AnkirenGame? _game;
  final DateTime _startedAt = DateTime.now();

  /// Placing times are read off [_clock]; [_shown] is what the band shows,
  /// whole seconds: the time left of a limit, or else the time so far.
  final Stopwatch _clock = Stopwatch()..start();
  late final ValueNotifier<Duration> _shown = ValueNotifier(widget.setup.limit ?? Duration.zero);
  Timer? _tick;
  int _ticks = 0;

  TeiichiDrag? _drag;
  bool _ending = false;

  /// The screen's size, and whether it is taller than wide; null until
  /// first laid out.
  Size? _size;
  bool? _portrait;
  bool _tipped = false;
  Timer? _tipTimer;
  final _field = GlobalKey();

  /// Done is pressed: the field grows, cards still face up, then [_flip].
  bool _zoomed = false;
  Timer? _zoomTimer;

  @override
  AnkirenGame get game => _game!;

  bool get _placingNow => _game == null;

  /// The cards are being laid out: Done is not pressed yet.
  bool get _editing => _placingNow && !_zoomed;

  /// Cards are placed and the player has not left: leaving throws the
  /// layout away, so it asks first.
  bool get _layoutAtStake => _placingNow && _placing.order.isNotEmpty;
  bool get _recorded => widget.player.recorded;

  /// The owner's level game: its strikes count.
  bool get _countsStrikes => widget.player == AnkirenPlayer.owner && widget.setup.level != null;

  /// A card has been placed: from then on leaving a ranked game is a
  /// forfeit, and the game is journalled.
  bool _cardPlaced = false;

  /// A ranked game is on and has a card placed: leaving it is a forfeit.
  /// Before the first card leaving saves nothing.
  bool get _forfeitable => _cardPlaced && _recorded && widget.setup.ranked && _game?.phase != AnkirenPhase.done;

  @override
  void initState() {
    super.initState();
    _progress = ProgressScope.read(context);
    _rng = math.Random(widget.seed);
    final deck = {...widget.known}.toList()..shuffle(_rng);
    _deal = deck.take(widget.setup.cards).toList();
    _placing = TeiichiPlacing(widget.setup, _deal);
    holdStage(_progress.settings.teiichi.autoTurn ? OrientationTuning.landscape : OrientationTuning.any);
    _tick = Timer.periodic(TeiichiPlayTuning.clockTick, _onTick);
  }

  /// Counted by the ticks due, not the ones run: a stalled or suspended app
  /// skips ticks, never time.
  void _onTick(Timer timer) {
    final step = TeiichiPlayTuning.clockTick * (timer.tick - _ticks);
    _ticks = timer.tick;
    if (!_clock.isRunning) return;
    if (widget.setup.limit == null) {
      _shown.value += step;
      return;
    }
    final left = _shown.value - step;
    _shown.value = left > Duration.zero ? left : Duration.zero;
    if (left <= Duration.zero) _timeUp();
  }

  /// The screen turned, or changed size: a drag under way lets go, as the
  /// field moves under it, and a portrait screen gets the tip.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final size = MediaQuery.sizeOf(context);
    if (size == _size) return;
    if (_size != null) _drag = null;
    _size = size;
    final portrait = size.height > size.width;
    if (portrait == _portrait) return;
    _portrait = portrait;
    _tipTimer?.cancel();
    if (portrait) _tipTimer = Timer(TeiichiPlayTuning.tipDelay, () => unawaited(_tip()));
  }

  /// Tobi's tip to turn the phone, once a game, while the cards are laid
  /// out on a portrait screen; unless the player asked for it no more.
  Future<void> _tip() async {
    if (!mounted || _tipped || _ending || !_editing || _portrait != true || widget.setup.ranked) return;
    if (_progress.settings.teiichi.turnTipOff) return;
    _tipped = true;
    _clock.stop();
    await showTeiichiTurnTip(context);
    if (mounted && _editing) _clock.start();
  }

  @override
  void dispose() {
    _tick?.cancel();
    _zoomTimer?.cancel();
    _tipTimer?.cancel();
    _shown.dispose();
    releaseStage();
    _leave();
    super.dispose();
  }

  /// The screen is going without End or Results: a game already played to
  /// its end is recorded without Results, a ranked one still on is
  /// forfeited, and anything else records nothing.
  void _leave() {
    if (_ending) return;
    _ending = true;
    _tick?.cancel();
    _zoomTimer?.cancel();
    stopRecall();
    if (_forfeitable) _forfeit();
    final game = _game;
    if (_recorded && game != null && game.phase == AnkirenPhase.done) {
      unawaited(_progress.recordTeiichi(_placing, game, startedAt: _startedAt));
    }
  }

  /// The ranked game ends here: the layout stands as it is, and every call
  /// not answered yet counts as missed.
  void _forfeit() {
    _tick?.cancel();
    _zoomTimer?.cancel();
    _placing.stop(_placingTime);
    _game ??= _placing.recall(_rng);
    _game!.end();
  }

  Duration get _now => _clock.elapsed;

  /// The placing time now, never past the limit.
  Duration get _placingTime {
    final limit = widget.setup.limit;
    return limit != null && _now > limit ? limit : _now;
  }

  void _placed() {
    if (!_cardPlaced) {
      _cardPlaced = true;
      if (_forfeitable) unawaited(_progress.journalTeiichi(_deal, _startedAt));
    }
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

  /// Every card is placed and the player is done.
  void _done() {
    if (_placing.finish(_placingTime)) _laidOut();
  }

  /// The limit ran out: the layout stands as it is, as if Done was pressed.
  void _timeUp() {
    if (_ending || _placing.done) return;
    _placing.stop(widget.setup.limit!);
    _laidOut();
  }

  /// The layout is final: the clock stops, the field grows, then the cards
  /// turn face down and the first prompt follows, at once when the field
  /// has no room to grow.
  void _laidOut() {
    _clock.stop();
    _tick?.cancel();
    _shown.value = _placing.placingTime!;
    setState(() {
      _drag = null;
      _zoomed = true;
    });
    final grows = _growth() > 1 + _growthTolerance;
    _zoomTimer = Timer(stillMotion || !grows ? Duration.zero : TeiichiPlayLayout.zoomTime, _flip);
  }

  /// A growth this close to none is none.
  static const _growthTolerance = 1e-6;

  /// How far the laid-out field grows for play, on the screen as it is.
  double _growth() {
    final size = _field.currentContext?.size;
    if (size == null) return 1;
    return TeiichiZoom.limit(_laidField(_placing.board), AnkirenFieldView.areaIn(size),
        AnkirenFieldView.bandHeight(landscape: !_portrait!), _bandRise(landscape: !_portrait!, zoomed: true));
  }

  /// How much higher the band reaches once the layout is final ([zoomed])
  /// in a game with からふだ, or with strikes to show on a portrait screen;
  /// in landscape they fit beside End.
  double _bandRise({required bool landscape, required bool zoomed}) {
    if (!zoomed || (widget.setup.karafuda == 0 && (landscape || !_countsStrikes))) return 0;
    final tall = landscape ? TeiichiPlayLayout.karafudaBandLandscape : TeiichiPlayLayout.karafudaBandPortrait;
    return tall - AnkirenFieldView.bandHeight(landscape: landscape);
  }

  /// The field while the cards are laid out: [board] on the own side.
  static AnkirenField _laidField(TeiichiBoard board) => AnkirenField(own: board.half, opponent: AnkirenHalf.empty());

  void _flip() {
    if (!mounted) return;
    final left = _placing.unplaced.toSet();
    final known = [for (final card in widget.known) if (!left.contains(card)) card];
    setState(() => _game = _placing.recall(_rng,
        karafuda: KarafudaPicker.ofPoems.pick(_placing.board.cards, known, widget.setup.karafuda, _rng),
        countsStrikes: _countsStrikes));
    turnFaceDown(memorised: _placing.placingTime);
    if (game.phase == AnkirenPhase.done) recallOver();
  }

  @override
  void recallOver() => unawaited(_finish());

  /// End, or the back gesture: a ranked game is forfeited, after asking.
  /// Any other game while placing has played nothing, so it just leaves,
  /// asking first once a card is placed; after, the cards not found yet
  /// count as missed.
  Future<void> _end() async {
    if (_ending) return;
    if (_forfeitable) {
      if (!await _confirmForfeit() || _ending || !mounted || !_forfeitable) return;
      setState(_forfeit);
      unawaited(_finish());
      return;
    }
    if (_placingNow) {
      if (_layoutAtStake && !await _confirmLeave()) return;
      if (_ending || !mounted) return;
      Navigator.of(context).pop();
      return;
    }
    game.end();
    unawaited(_finish());
  }

  Future<bool> _confirmLeave() {
    final s = S.of(context);
    return _confirm(s.teiichiLeaveTitle, s.teiichiLeaveNote);
  }

  Future<bool> _confirmForfeit() {
    final s = S.of(context);
    return _confirm(s.teiichiForfeitTitle, s.teiichiForfeitNote);
  }

  Future<bool> _confirm(String title, String note) async {
    final s = S.of(context);
    final leave = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(title),
        content: Text(note),
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
    final report = _recorded ? await _progress.recordTeiichi(_placing, game, startedAt: _startedAt) : null;
    // Left meanwhile: its route is on its way out, and replacing "the
    // current route" would replace the one under it.
    if (!mounted || ModalRoute.isCurrentOf(context) == false) return;
    wentToResults = true;
    AnkirenPlay.releaseOrientation();
    unawaited(Navigator.of(context).pushReplacement(MangaRoute<void>(
      builder: (_) => TeiichiResultsScreen(
          placing: _placing, game: game, player: widget.player, bestBefore: bestBefore, report: report),
    )));
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final showNumber = _progress.settings.showPoemNumber;
    final portrait = _portrait!;
    final landscape = !portrait;
    final placingNow = _placingNow;
    final editing = _editing;
    final allPlaced = _placing.allPlaced && _drag == null && !_zoomed;
    final limited = widget.setup.limit != null;
    final strikes = _countsStrikes && !placingNow;
    final end = BandButton(icon: IconArt.end, label: s.end, onTap: _ending ? null : () => unawaited(_end()));
    final band = AnkirenBand(
      landscape: landscape,
      slot: landscape ? AnkirenPlay.landscapeSlot(strikes: strikes, karafuda: false) : AnkirenPlayLayout.sideSlot,
      leading: AnimatedSwitcher(
          duration: stillMotion ? Duration.zero : AnkirenMotion.flip,
          child: strikes ? withStrikes(end, landscape: landscape) : end),
      center: placingNow || (asked == null && game.answers.isEmpty)
          ? MemoriseClock(
              left: _shown,
              landscape: landscape,
              label: !editing
                  ? s.teiichiPlaced
                  : limited
                      ? s.teiichiTimeLeft
                      : s.teiichiPlacing,
              lowAt: editing && limited ? TeiichiPlayTuning.lowTime : null,
            )
          : recallPrompt(landscape: landscape),
      trailing: placingNow
          ? BandButton(
              icon: IconArt.arrow,
              label: s.done,
              color: allPlaced ? Palette.sun : Palette.paper,
              dimmed: !allPlaced,
              onTap: allPlaced ? _done : null,
            )
          : game.karafuda.isEmpty
              ? dontKnowButton()
              : StackedControls(top: dontKnowButton(), bottom: karafudaButton()),
    );
    final shownBoard = _shownBoard;
    final field = AnkirenFieldView(
      key: _field,
      field: placingNow ? _laidField(shownBoard) : game.field,
      landscape: landscape,
      trueScale: true,
      zoom: false,
      trueSlots: TeiichiTuning.rowSlots,
      roomAbove: TeiichiPlayLayout.roomAbove,
      bandRise: _bandRise(landscape: landscape, zoomed: _zoomed),
      move: _zoomed ? null : (stillMotion ? Duration.zero : TeiichiPlayLayout.move),
      growth: const FieldGrowth(
          limit: TeiichiZoom.limit, duration: TeiichiPlayLayout.zoomTime, curve: TeiichiPlayLayout.zoomCurve),
      grown: _zoomed,
      card: (poemId, side) => placingNow
          ? _laidCard(poemId, showNumber: showNumber)
          : recallCard(poemId, side, showNumber: showNumber),
      band: band,
      underlay: editing ? _spots : null,
      foreground: editing ? _layer : null,
      aboveBand: editing ? (placement) => _riding(placement, shownBoard, showNumber: showNumber) : null,
    );
    final settings = _progress.settings;
    return PopScope(
      canPop: !_layoutAtStake && !_forfeitable,
      onPopInvokedWithResult: (didPop, _) => didPop ? _leave() : unawaited(_end()),
      child: AnkirenTatami(
        child: settings.debugMode && settings.playOverlay
            ? ReadoutFrame(
                readout: TeiichiScoreReadout(
                  setup: widget.setup,
                  placing: _placing,
                  ticks: _shown,
                  placingTime: () => _placingTime,
                  game: _game,
                  split: portrait,
                ),
                landscape: landscape,
                child: field,
              )
            : field,
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

  Widget _layer(FieldPlacement placement) {
    final drag = _drag;
    final laid = _laid(placement);
    return TeiichiPlacingLayer(
      placement: placement,
      stack: _placing.stack,
      cards: {for (final MapEntry(key: id, value: r) in laid.entries) if (id != drag?.card) id: r},
      showHint: _placing.order.isEmpty && drag == null,
      drag: drag,
      onTap: (at) => _tap(at, placement),
      onDragStart: (card, {required fromStack, required at}) =>
          _dragStart(card, fromStack: fromStack, at: at, placement: placement),
      onDrag: (at) => _dragTo(at, placement),
      onDragEnd: _dragEnd,
    );
  }

  Widget _riding(FieldPlacement placement, TeiichiBoard shown, {required bool showNumber}) {
    final drag = _drag;
    return TeiichiRiding(
      placement: placement,
      stack: _placing.stack,
      drag: drag,
      landing: switch (drag) {
        TeiichiDrag(onStack: true) => S.of(context).teiichiStack,
        TeiichiDrag(:final card, spot: _?) => _spotName(shown, card),
        _ => null,
      },
      showNumber: showNumber,
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
