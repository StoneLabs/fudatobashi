import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../config/config.dart';
import '../../data/poem.dart';
import '../../domain/play_session.dart';
import '../../state/scope.dart';
import '../debug/play_overlay.dart';
import 'swipe_deck.dart';

/// Formats a duration like the original app: mm:ss.mmm
String formatRunTime(Duration d) {
  final ms = d.inMilliseconds;
  final m = ms ~/ 60000;
  final s = (ms ~/ 1000) % 60;
  final r = ms % 1000;
  return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}.${r.toString().padLeft(3, '0')}';
}

class PlayScreen extends StatefulWidget {
  const PlayScreen({super.key, required this.cards, this.grading = true, this.onRunEnded});

  final List<CardRef> cards;
  final bool grading;

  /// Called once per run that has at least one attempt: when it finishes,
  /// is restarted or the screen closes.
  final void Function(PlaySession run, DateTime startedAt)? onRunEnded;

  static List<CardRef> randomDeck(int n, {bool mixedOrientation = true}) {
    final rng = math.Random();
    final ids = List<int>.generate(100, (i) => i + 1)..shuffle(rng);
    return [
      for (final id in ids.take(n)) CardRef(id, inverted: mixedOrientation && rng.nextBool()),
    ];
  }

  @override
  State<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen> {
  late PlaySession _session = PlaySession(widget.cards);
  DateTime _startedAt = DateTime.now();
  bool _reported = false;
  bool _live = false;

  @override
  void initState() {
    super.initState();
    _session.addListener(_changed);
    // Let the route transition settle before the first reveal.
    Future.delayed(SwipeTuning.leadIn, () {
      if (mounted) setState(() => _live = true);
    });
  }

  @override
  void dispose() {
    _report();
    _session.removeListener(_changed);
    super.dispose();
  }

  void _report() {
    if (_reported || _session.attempts.isEmpty) return;
    _reported = true;
    widget.onRunEnded?.call(_session, _startedAt);
  }

  void _changed() {
    if (_session.finished) _report();
    setState(() {});
  }

  void _restart() {
    _report();
    _session.removeListener(_changed);
    setState(() {
      _session = PlaySession([...widget.cards]..shuffle());
      _session.addListener(_changed);
      _startedAt = DateTime.now();
      _reported = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = _session;
    final last = s.lastAttempt;
    final chip = last == null ? '開始' : poems[last.card.poemId].kimariji;
    final debugSettings = ProgressScope.of(context).settings;
    return Scaffold(
      backgroundColor: const Color(0xFF2A1B45),
      body: SafeArea(
        child: Stack(children: [
          Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: last == null ? null : s.togglePreviousWrong,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: last?.wrong == true ? const Color(0xFFE0352B) : const Color(0xFFFBF8F1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(chip,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: last?.wrong == true ? Colors.white : const Color(0xFF16121A),
                          )),
                    ),
                  ),
                  const Spacer(),
                  if (last != null)
                    Text('${(last.responseUs / 1000).toStringAsFixed(1)} ms  ',
                        style: const TextStyle(color: Color(0xFFE7B22E), fontSize: 16)),
                  Text('${math.min(s.index + 1, s.cards.length)} / ${s.cards.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 20)),
                ],
              ),
            ),
            Expanded(
              child: s.finished
                  ? Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Text(formatRunTime(s.total ?? Duration.zero),
                            style: const TextStyle(
                                fontSize: 56,
                                color: Colors.white,
                                fontFeatures: [FontFeature.tabularFigures()])),
                        const SizedBox(height: 12),
                        Text(
                          'avg ${(s.attempts.map((a) => a.responseUs).reduce((a, b) => a + b) / s.attempts.length / 1000).toStringAsFixed(0)} ms/card',
                          style: const TextStyle(color: Color(0xFFE7B22E), fontSize: 18),
                        ),
                      ]),
                    )
                  : SwipeDeck(session: s, live: _live, grading: widget.grading),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(children: [
                Expanded(
                  child: FilledButton(
                    onPressed: s.attempts.isEmpty ? null : s.undo,
                    child: const Text('ひとつ前'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: s.finished ? _restart : () => Navigator.maybePop(context),
                    child: Text(s.finished ? 'もう一回' : '終了'),
                  ),
                ),
              ]),
            ),
          ],
          ),
          if (debugSettings.debugMode && debugSettings.playOverlay)
            Positioned(bottom: 8, left: 8, child: PlayDebugOverlay(session: s)),
        ]),
      ),
    );
  }
}
