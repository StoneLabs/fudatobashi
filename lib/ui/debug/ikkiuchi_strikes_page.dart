import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../data/poem.dart';
import '../../domain/ikkiuchi_board.dart';
import '../../domain/ikkiuchi_geometry.dart';
import '../../domain/ikkiuchi_read.dart';
import '../../domain/ikkiuchi_strike.dart';
import '../../l10n/karafuda_strings.dart';
import '../../l10n/strings.dart';
import '../ikkiuchi/ikkiuchi_board_painter.dart';
import '../ikkiuchi/ikkiuchi_board_scene.dart';
import '../sound/sounds.dart';
import 'debug_common.dart';
import 'ikkiuchi_dealer.dart';
import 'ikkiuchi_rating_header.dart';
import 'ikkiuchi_values.dart';

/// What a tap on the strikes page's board does.
enum IkkiuchiTapMode {
  /// The card is read: Tobi reacts after his take time, then strikes.
  read,

  /// Tobi strikes at the card at once.
  now,
}

/// The developer's view of Tobi's strikes (一騎打ち): a full field, his side
/// laid out by his own layout at the rating chosen, the player's at random.
/// A tap on the board reads the card under it (or the nearest), and Tobi
/// strikes at it with real card physics: taken cards leave, knocked cards
/// stay where they land until the board resets, which the next read does
/// first. Nothing is stored.
class IkkiuchiStrikesPage extends StatefulWidget {
  const IkkiuchiStrikesPage({super.key, this.rating = IkkiuchiToolsTuning.ratingStart, this.seed, this.landscape = false});

  final double rating;

  /// The deal's seed, random when null.
  final int? seed;

  /// Whether the board starts in its landscape layout.
  final bool landscape;

  @override
  State<IkkiuchiStrikesPage> createState() => IkkiuchiStrikesPageState();
}

class IkkiuchiStrikesPageState extends State<IkkiuchiStrikesPage> with SingleTickerProviderStateMixin {
  static const _moveNames = {
    IkkiuchiMove.sweep: 'sweep',
    IkkiuchiMove.whip: 'whip',
    IkkiuchiMove.coilLunge: 'coil',
    IkkiuchiMove.smear: 'smear',
  };

  final _dealer = IkkiuchiDealer();
  late double _rating = widget.rating;
  late int _seed = widget.seed ?? math.Random().nextInt(IkkiuchiToolsTuning.seeds);
  late var _rng = math.Random(_seed);
  late bool _landscape = widget.landscape;
  var _mode = IkkiuchiTapMode.read;
  final _moves = {...IkkiuchiMove.values};
  var _mistakes = true, _wind = true, _voice = true, _autoReset = true;
  var _speed = IkkiuchiToolsTuning.slowMotion.first;

  late final Ticker _ticker = createTicker(_tick);
  Duration _last = Duration.zero;
  Duration? _idleSince;
  bool _called = false;

  /// The board as drawn now (for tests).
  IkkiuchiBoardScene? get scene => _dealer.scene;

  @override
  void initState() {
    super.initState();
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _dealer.dispose();
    super.dispose();
  }

  /// Deals a new board: a new seed, with new cards and both sides laid out.
  void _newSeed() {
    scene?.reset();
    _called = false;
    _idleSince = null;
    setState(() {
      _seed = math.Random().nextInt(IkkiuchiToolsTuning.seeds);
      _rng = math.Random(_seed);
    });
  }

  /// The scene for a board filling [room], set out afresh when its size,
  /// the layout, the rating or the seed changes.
  IkkiuchiBoardScene _sceneFor(Size room) => _dealer.sceneFor(context, room,
      landscape: _landscape, rating: _rating, seed: _seed, onNew: (scene) {
        _called = false;
        scene.wind = _wind;
      });

  void _tick(Duration elapsed) {
    final scene = this.scene;
    final dt = elapsed - _last;
    _last = elapsed;
    if (scene == null) return;
    scene.advance(dt.inMicroseconds / Duration.microsecondsPerMillisecond * _speed);
    final board = scene.board;
    if (!_called || board.busy) {
      _idleSince = null;
      return;
    }
    if (scene.note == null) scene.annotate(_readout());
    if (!_autoReset || !board.cards.settled) return;
    _idleSince ??= elapsed;
    if (elapsed - _idleSince! >= IkkiuchiToolsTuning.autoReset) _reset();
  }

  void _reset() {
    scene?.reset();
    _called = false;
    _idleSince = null;
  }

  /// Reads the card [pick] chooses on the board as it was set out: a board
  /// called on since is reset first, cancelling any strike still playing.
  void _read(int? Function(IkkiuchiBoard board) pick) {
    if (_called) _reset();
    final scene = this.scene;
    if (scene == null) return;
    final poemId = pick(scene.board);
    if (poemId != null) _call(scene, poemId);
  }

  /// Reads [poemId]: on the field, or a からふだ.
  void _call(IkkiuchiBoardScene scene, int poemId) {
    final board = scene.board;
    final field = board.field;
    final read = IkkiuchiRead.decide(
      rating: _rating,
      called: poemId,
      field: field,
      from: board.shoulders,
      alike: _dealer.layout.alike,
      rng: _rng,
      now: _mode == IkkiuchiTapMode.now,
      mistakes: _mistakes,
      moves: _moves,
    );
    final karafuda = !field.containsKey(poemId);
    scene.show(kimarijiFor(context, poemId), karafuda: karafuda ? S.of(context).karafuda : null);
    board.call(read);
    if (_voice && _mode == IkkiuchiTapMode.read) unawaited(sounds.playKimarijiVoice(poemId));
    _called = true;
    _idleSince = null;
  }

  /// The card under [at] (board dp), or the nearest.
  void _tapAt(Offset at) => _read((board) {
        final p = Vec(at.dx, at.dy);
        final field = board.field.entries.toList();
        if (field.isEmpty) return null;
        field.sort((a, b) => a.value.gapTo(p).compareTo(b.value.gapTo(p)));
        return field.first.key;
      });

  void _random() => _read((board) {
        final ids = board.field.keys.toList()..sort();
        return ids.isEmpty ? null : ids[_rng.nextInt(ids.length)];
      });

  void _karafuda() => _read((board) {
        final onField = board.field.keys.toSet();
        final away = [
          for (final p in poems.all)
            if (!onField.contains(p.id)) p.id,
        ];
        return away[_rng.nextInt(away.length)];
      });

  /// What Tobi did on the last call, for the band.
  String _readout() {
    final board = scene?.board;
    final read = board?.read;
    if (board == null || read == null) return '';
    const ms = IkkiuchiUnit.ms;
    return [
      if (!read.strikes) 'no strike',
      if (read.strikes) ...[
        'reaction ${ms.format(read.reactionMs)}',
        'reach ${ms.format(read.reachMs)}',
        _moveNames[read.move]!,
      ],
      if (read.searchMs case final search?) 'blank +${ms.format(search)}',
      if (read.slip == IkkiuchiSlip.lookAlike) 'look-alike ${poems[read.wrong!].kimariji} first',
      if (read.slip == IkkiuchiSlip.stray) 'stray touch',
      if (board.faults.isNotEmpty) IkkiuchiBoardStyle.stamp,
    ].join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    return DebugScaffold(
      title: "Tobi's strikes",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          IkkiuchiRatingHeader(
            rating: _rating,
            note: 'seed $_seed · you ${IkkiuchiDealer.playerRating(_seed).round()}',
            onChanged: (v) => setState(() => _rating = v),
          ),
          Expanded(
            child: ClipRect(
              child: LayoutBuilder(
                builder: (context, box) =>
                    IkkiuchiDealer.turned(IkkiuchiBoardView(_sceneFor(box.biggest), onTap: _tapAt), landscape: _landscape),
              ),
            ),
          ),
          Padding(
            padding: IkkiuchiToolsStyle.controlsPadding,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Wrap(
                spacing: IkkiuchiToolsStyle.controlSpacing,
                runSpacing: IkkiuchiToolsStyle.controlSpacing,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  for (final mode in IkkiuchiTapMode.values)
                    _chip(mode == IkkiuchiTapMode.read ? 'Read' : 'Strike now', _mode == mode,
                        () => setState(() => _mode = mode)),
                  _button('Random', _random),
                  _button(S.of(context).karafuda, _karafuda),
                  _button('Reset', _reset),
                  _button('New seed', _newSeed),
                  _button('Rotate', () => setState(() => _landscape = !_landscape)),
                  _menu<double>(
                    _speedName(_speed),
                    {for (final speed in IkkiuchiToolsTuning.slowMotion) speed: _speedName(speed)},
                    (speed) => setState(() => _speed = speed),
                  ),
                  _chip('mistakes', _mistakes, () => setState(() => _mistakes = !_mistakes)),
                  _chip('wind', _wind, () => setState(() => scene?.wind = _wind = !_wind)),
                  _chip('voice', _voice, () => setState(() => _voice = !_voice)),
                ],
              ),
              const SizedBox(height: IkkiuchiToolsStyle.controlSpacing),
              Wrap(
                spacing: IkkiuchiToolsStyle.controlSpacing,
                runSpacing: IkkiuchiToolsStyle.controlSpacing,
                children: [
                  for (final move in IkkiuchiMove.values)
                    _chip(_moveNames[move]!, _moves.contains(move), () => setState(() => _toggle(move))),
                  _chip('auto reset', _autoReset, () => setState(() => _autoReset = !_autoReset)),
                ],
              ),
            ]),
          ),
        ],
      ),
    );
  }

  /// Turns [move] on or off for the strikes to come; the last one on stays on.
  void _toggle(IkkiuchiMove move) {
    if (!_moves.contains(move)) {
      _moves.add(move);
    } else if (_moves.length > 1) {
      _moves.remove(move);
    }
  }

  static String _speedName(double speed) => '${IkkiuchiUnit.plain.axis(speed)}×';

  static final _label = debugMono.copyWith(fontSize: IkkiuchiToolsStyle.controlFont);

  /// The chips as tight as the buttons, so the board keeps the height.
  static const _tight = VisualDensity(horizontal: VisualDensity.minimumDensity, vertical: VisualDensity.minimumDensity);

  static Widget _chip(String label, bool selected, VoidCallback onTap) => ChoiceChip(
        label: Text(label, style: _label),
        selected: selected,
        showCheckmark: false,
        visualDensity: _tight,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: IkkiuchiToolsStyle.chipPadding,
        labelPadding: IkkiuchiToolsStyle.chipLabelPadding,
        onSelected: (_) => onTap(),
      );

  static Widget _button(String label, VoidCallback onPressed) => OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          visualDensity: VisualDensity.compact,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          minimumSize: Size.zero,
          padding: IkkiuchiToolsStyle.buttonPadding,
        ),
        child: Text(label, style: _label),
      );

  /// A button showing [label] that picks one of [choices].
  static Widget _menu<T>(String label, Map<T, String> choices, ValueChanged<T> onPicked) => PopupMenuButton<T>(
        onSelected: onPicked,
        itemBuilder: (context) => [
          for (final MapEntry(key: value, value: name) in choices.entries)
            PopupMenuItem(value: value, child: Text(name, style: debugMono)),
        ],
        child: Container(
          padding: IkkiuchiToolsStyle.buttonPadding,
          decoration: BoxDecoration(
            border: Border.all(color: IkkiuchiToolsStyle.soft),
            borderRadius: BorderRadius.circular(IkkiuchiToolsStyle.menuRadius),
          ),
          child: Text.rich(TextSpan(style: _label, children: [
            TextSpan(text: label),
            TextSpan(
                text: IkkiuchiToolsStyle.menuMark, style: _label.copyWith(fontSize: IkkiuchiToolsStyle.menuMarkFont)),
          ])),
        ),
      );
}
