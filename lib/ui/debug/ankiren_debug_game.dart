import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../config/design.dart';
import '../../data/fuda_sets.dart';
import '../../data/poem.dart';
import '../../domain/ankiren_field.dart';
import '../../domain/ankiren_level.dart';
import '../ankiren/ankiren_band.dart';
import '../ankiren/ankiren_screen.dart';
import 'ankiren_debug_overlay.dart';

/// The developer's 暗記練 test game: an untracked game under a debug bar
/// that switches the level (dealing a new field at once), reseeds the deal,
/// and toggles the debug layers over the field ([AnkirenDebugOverlay]).
class AnkirenDebugGame extends StatefulWidget {
  const AnkirenDebugGame({super.key, required this.known, this.level = 0});

  /// The player's known cards; a level they cannot fill deals from all.
  final List<int> known;
  final int level;

  @override
  State<AnkirenDebugGame> createState() => _AnkirenDebugGameState();
}

class _AnkirenDebugGameState extends State<AnkirenDebugGame> {
  final _seeds = math.Random();
  late int _level = widget.level;
  late int _seed = _newSeed();
  final Set<AnkirenDebugLayer> _layers = {...AnkirenDebugLayer.values};

  int _newSeed() => _seeds.nextInt(1 << 31);

  List<int> get _deck =>
      widget.known.length >= AnkirenLevels.of(_level).cards ? widget.known : [for (final p in poems.all) p.id];

  void _toggle(AnkirenDebugLayer layer) =>
      setState(() => _layers.contains(layer) ? _layers.remove(layer) : _layers.add(layer));

  @override
  Widget build(BuildContext context) {
    final level = AnkirenLevels.of(_level);
    final perCard = level.memorise.inMilliseconds / 1000 / level.cards;
    final middle = level.allInMiddle
        ? 'all (beginner)'
        : AnkirenDealer.mayHaveMiddle(level.perSide)
            ? 'up to ${AnkirenDealer.maxMiddle(level.perSide)}'
            : 'never';
    final layers = {..._layers};
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AnkirenDebugStyle.barBackground,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SafeArea(
              bottom: false,
              child: Padding(
                padding: AnkirenDebugStyle.barPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (var l = 0; l <= AnkirenLevels.top; l++)
                            _Chip('$l', on: l == _level, onTap: () => setState(() => _level = l)),
                          _Chip('reseed', on: false, onTap: () => setState(() => _seed = _newSeed())),
                        ],
                      ),
                    ),
                    const SizedBox(height: AnkirenDebugStyle.rowGap),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final layer in AnkirenDebugLayer.values)
                            _Chip(layer.name, on: _layers.contains(layer), onTap: () => _toggle(layer)),
                        ],
                      ),
                    ),
                    const SizedBox(height: AnkirenDebugStyle.rowGap),
                    Text(
                      'L$_level  ${level.perSide}/side  ${level.cards} cards  ${formatMinutes(level.memorise)}'
                      '  ${perCard.toStringAsFixed(1)} s/card'
                      '  middle $middle'
                      '  seed $_seed',
                      style: const TextStyle(
                        fontFamily: AnkirenDebugStyle.mono,
                        fontSize: AnkirenDebugStyle.barFont,
                        color: AnkirenDebugStyle.barMute,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: MediaQuery.removePadding(
                context: context,
                removeTop: true,
                child: AnkirenScreen(
                  key: ValueKey((_level, _seed)),
                  setup: AnkirenSetup.forLevel(_level),
                  known: _deck,
                  tracked: false,
                  seed: _seed,
                  overlay: layers.isEmpty
                      ? null
                      : (game, placement) => AnkirenDebugOverlay(
                            game: game,
                            placement: placement,
                            layers: layers,
                            kimariji: (id) => poems[id].kimariji,
                            tomofuda: fudaSets.tomofuda,
                          ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A debug bar button: monospace, filled while [on].
class _Chip extends StatelessWidget {
  const _Chip(this.label, {required this.on, required this.onTap});

  final String label;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: AnkirenDebugStyle.chipGap),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(
              minWidth: AnkirenDebugStyle.chipMinWidth,
              minHeight: AnkirenDebugStyle.chipHeight,
            ),
            padding: AnkirenDebugStyle.chipPadding,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: on ? AnkirenDebugStyle.chipOn : null,
              border: Border.all(color: AnkirenDebugStyle.chipOn, width: AnkirenDebugStyle.chipBorder),
              borderRadius: BorderRadius.circular(AnkirenDebugStyle.chipRadius),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontFamily: AnkirenDebugStyle.mono,
                fontSize: AnkirenDebugStyle.barFont,
                color: on ? AnkirenDebugStyle.chipOnText : AnkirenDebugStyle.barText,
              ),
            ),
          ),
        ),
      );
}
