import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../config/vector_art.dart';
import '../../domain/ankiren_field.dart';
import '../../domain/ankiren_game.dart';
import '../../domain/ankiren_level.dart';
import '../../domain/karafuda.dart';
import '../../l10n/ankiren_strings.dart';
import '../../l10n/strings.dart';
import '../../state/progress.dart';
import '../../state/scope.dart';
import '../../state/settings.dart';
import '../manga/manga.dart';
import '../debug/ankiren_score_readout.dart';
import '../debug/readout_frame.dart';
import 'ankiren_band.dart';
import 'ankiren_field_view.dart';
import 'ankiren_play.dart';
import 'ankiren_results_screen.dart';

/// 暗記練's play screen. A field of [setup]'s size is dealt from [known]
/// and shown face up while its memorise time counts down (or until the
/// player is ready); then every card turns face down and each is asked for
/// by its kimariji, in turn ([AnkirenPlay]), the setup's からふだ, drawn
/// from the other known cards ([KarafudaPicker]), among them, until all
/// are found or given up ("don't know"), or the game is ended. The owner's
/// free-play level games count strikes (see [AnkirenStrikes]): the last one
/// ends the game at once. It ends into [AnkirenResultsScreen].
///
/// The band has End on the left, with the strikes over it in portrait (beside
/// it in landscape) once they count, and "don't know" on the right, with the
/// からふだ button under it (beside it in landscape) in a game with any.
///
/// The screen holds its orientation while it is up: portrait, or landscape
/// for the true-scale field.
class AnkirenScreen extends StatefulWidget {
  const AnkirenScreen({
    super.key,
    required this.setup,
    required this.known,
    this.player = AnkirenPlayer.owner,
    this.seed,
    this.overlay,
  });

  final AnkirenSetup setup;

  /// The cards the field is dealt from.
  final List<int> known;

  final AnkirenPlayer player;

  /// Seeds the deal and the order of the prompts; random when null.
  final int? seed;

  /// Drawn over the field (the developer's test game's debug layer).
  final Widget Function(AnkirenGame game, FieldPlacement placement)? overlay;

  @override
  State<AnkirenScreen> createState() => _AnkirenScreenState();
}

class _AnkirenScreenState extends State<AnkirenScreen> with AnkirenPlay {
  late final Progress _progress;
  late final bool _zoom;
  @override
  late final AnkirenGame game;
  final DateTime _startedAt = DateTime.now();

  late final ValueNotifier<Duration> _left = ValueNotifier(widget.setup.memorise);
  final Stopwatch _memorising = Stopwatch()..start();
  Timer? _clock;

  bool _ending = false;

  bool get _landscape => ankirenOptions.layout == AnkirenLayout.landscape;

  @override
  void initState() {
    super.initState();
    _progress = ProgressScope.read(context);
    _zoom = _progress.settings.accessibilityMode && !_landscape;
    final rng = math.Random(widget.seed);
    final field =
        AnkirenDealer.ofPoems().deal(widget.known, widget.setup.perSide, rng, allInMiddle: widget.setup.allInMiddle);
    game = AnkirenGame(
      field: field,
      setup: widget.setup,
      rng: rng,
      karafuda: KarafudaPicker.ofPoems.pick(field.cards, widget.known, widget.setup.karafuda, rng),
      countsStrikes: widget.player == AnkirenPlayer.owner && widget.setup.level != null,
    );
    holdStage(_landscape ? OrientationTuning.landscape : OrientationTuning.app);
    // Counted by the ticks due, not the ones run: a stalled or suspended app
    // skips ticks, never time.
    _clock = Timer.periodic(AnkirenPlayTuning.clockTick, (timer) {
      final left = widget.setup.memorise - AnkirenPlayTuning.clockTick * timer.tick;
      _left.value = left > Duration.zero ? left : Duration.zero;
      if (left <= Duration.zero) _startRecall();
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    _left.dispose();
    releaseStage();
    _leave();
    super.dispose();
  }

  /// A ranked game is on and recall has begun: leaving it is a forfeit.
  bool get _forfeitable => _recorded && widget.setup.ranked && game.phase == AnkirenPhase.recall;

  bool get _recorded => widget.player.recorded;

  /// The screen is going without End or Results: nothing more happens on
  /// it. A game already played to its end is recorded without Results, a
  /// ranked one still in recall is forfeited, and anything else (free play
  /// midway, memorising) records nothing.
  void _leave() {
    if (_ending) return;
    _ending = true;
    _clock?.cancel();
    stopRecall();
    if (_recorded && (game.phase == AnkirenPhase.done || _forfeitable)) {
      game.end();
      unawaited(_progress.recordAnkiren(game, startedAt: _startedAt, meta: _meta));
    }
  }

  Map<String, Object?> get _meta => {'layout': ankirenOptions.layout.name, 'zoom': _zoom};

  /// The memorise time is up, or the player is [ready] sooner: the field
  /// turns face down and the first prompt follows.
  void _startRecall({bool ready = false}) {
    _clock?.cancel();
    turnFaceDown(memorised: ready ? _memorising.elapsed : null);
  }

  @override
  void recallOver() => unawaited(_finish());

  /// End, or the back gesture: before recall nothing has been played, so it
  /// just leaves; after, the cards not found yet count as missed, and a
  /// ranked game asks first, as it is a forfeit.
  Future<void> _end() async {
    if (_ending) return;
    if (game.phase == AnkirenPhase.memorise) {
      Navigator.of(context).pop();
      return;
    }
    if (_forfeitable && !await _confirmLeave()) return;
    if (_ending || !mounted) return;
    game.end();
    unawaited(_finish());
  }

  Future<bool> _confirmLeave() {
    final s = S.of(context);
    return confirmLeaving(context, title: s.ankirenLeaveTitle, note: s.ankirenLeaveNote, stay: s.cancel, leave: s.ankirenLeave);
  }

  Future<void> _finish() async {
    if (_ending || !mounted) return;
    _ending = true;
    stopRecall();
    final report = _recorded ? await _progress.recordAnkiren(game, startedAt: _startedAt, meta: _meta) : null;
    // Left meanwhile: its route is on its way out, and replacing "the
    // current route" would replace the one under it.
    if (!mounted || ModalRoute.isCurrentOf(context) == false) return;
    wentToResults = true;
    AnkirenPlay.releaseOrientation();
    unawaited(Navigator.of(context).pushReplacement(MangaRoute<void>(
      builder: (_) => AnkirenResultsScreen(game: game, report: report, player: widget.player),
    )));
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final memorising = game.phase == AnkirenPhase.memorise;
    final settings = _progress.settings;
    final showNumber = settings.showPoemNumber;

    final dontKnow = dontKnowButton();
    final strikes = game.countsStrikes;
    final karafuda = game.karafuda.isNotEmpty;
    final end = BandButton(icon: IconArt.end, label: s.end, onTap: _ending ? null : () => unawaited(_end()));
    final flip = stillMotion ? Duration.zero : AnkirenMotion.flip;
    final band = AnkirenBand(
      landscape: _landscape,
      slot: _landscape ? AnkirenPlay.landscapeSlot(strikes: strikes, karafuda: karafuda) : AnkirenPlayLayout.sideSlot,
      leading: AnimatedSwitcher(
          duration: flip, child: strikes && !memorising ? withStrikes(end, landscape: _landscape) : end),
      center: memorising ? MemoriseClock(left: _left, landscape: _landscape) : recallPrompt(landscape: _landscape),
      trailing: AnimatedSwitcher(
        duration: flip,
        child: memorising
            ? BandButton(
                icon: IconArt.arrow, label: s.ankirenReady, color: Palette.sun, onTap: () => _startRecall(ready: true))
            : karafuda
                ? _withKarafuda(dontKnow)
                : dontKnow,
      ),
    );

    final overlay = widget.overlay;
    final Widget field = AnkirenFieldView(
      field: game.field,
      landscape: _landscape,
      zoom: _zoom,
      card: (poemId, side) => recallCard(poemId, side, faceUp: memorising, showNumber: showNumber),
      band: band,
      bandExtent: (strikes || karafuda) && !_landscape ? AnkirenPlayLayout.bandPortraitStrikes : null,
      overlay: overlay == null ? null : (placement) => overlay(game, placement),
    );
    return PopScope(
      canPop: !_forfeitable,
      onPopInvokedWithResult: (didPop, _) => didPop ? _leave() : unawaited(_end()),
      child: AnkirenTatami(
        child: settings.debugMode && settings.playOverlay
            ? ReadoutFrame(readout: AnkirenScoreReadout(game: game, split: !_landscape), landscape: _landscape, child: field)
            : field,
      ),
    );
  }

  /// [dontKnow] with the からふだ button: over it in portrait, beside it in
  /// landscape.
  Widget _withKarafuda(Widget dontKnow) => _landscape
      ? Row(mainAxisSize: MainAxisSize.min, children: [
          dontKnow,
          const SizedBox(width: AnkirenPlayLayout.bandGap),
          karafudaButton(),
        ])
      : StackedControls(top: dontKnow, bottom: karafudaButton());
}
