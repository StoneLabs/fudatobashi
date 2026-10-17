import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../config/vector_art.dart';
import '../../l10n/match_timer_strings.dart';
import '../../l10n/strings.dart';
import '../cards/page_frame.dart';
import '../manga/manga.dart';
import '../sound/sounds.dart';

/// The match timer (Help › Tools): a ring that empties counter-clockwise
/// round the time left, which can be set before it starts. The ring turns
/// to the warning colour, with a sound, for the last two minutes, and a
/// second sound sounds at zero. Time comes from the wall clock, so it stays
/// right however late a tick lands.
class MatchTimerScreen extends StatefulWidget {
  const MatchTimerScreen({super.key, this.now = DateTime.now});

  /// The clock; replaced in tests.
  final DateTime Function() now;

  @override
  State<MatchTimerScreen> createState() => _MatchTimerScreenState();
}

class _MatchTimerScreenState extends State<MatchTimerScreen> {
  Duration _total = MatchTimerTuning.defaultTime;
  Duration _banked = Duration.zero;
  DateTime? _runningSince;
  bool _started = false;
  bool _warned = false;
  bool _ended = false;
  Timer? _ticker;

  bool get _running => _runningSince != null;

  Duration get _elapsed => _banked + (_runningSince == null ? Duration.zero : widget.now().difference(_runningSince!));

  Duration get _left {
    final left = _total - _elapsed;
    return left.isNegative ? Duration.zero : left;
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _play() {
    setState(() {
      _started = true;
      _runningSince = widget.now();
      _warned = _left <= MatchTimerTuning.warnAt;
    });
    _ticker = Timer.periodic(MatchTimerTuning.tick, (_) => _onTick());
  }

  void _togglePause() {
    if (_running) {
      setState(() {
        _banked = _elapsed;
        _runningSince = null;
      });
    } else {
      setState(() => _runningSince = widget.now());
    }
  }

  void _stop() {
    _ticker?.cancel();
    setState(() {
      _started = false;
      _banked = Duration.zero;
      _runningSince = null;
      _warned = false;
      _ended = false;
    });
  }

  void _onTick() {
    if (!mounted || !_running) return;
    final left = _left;
    if (!_warned && left <= MatchTimerTuning.warnAt) {
      _warned = true;
      playSound(context, MatchTimerTuning.warnSound);
    }
    if (left == Duration.zero) {
      _ended = true;
      _ticker?.cancel();
      _banked = _total;
      _runningSince = null;
      playSound(context, MatchTimerTuning.endSound);
    }
    setState(() {});
  }

  Future<void> _edit() async {
    final picked = await showMangaSheet<Duration>(
      context,
      barrierColor: MatchTimerLayout.sheetBarrier,
      barrierLabel: S.of(context).cancel,
      builder: (_) => _SetTimeSheet(initial: _total),
    );
    if (picked != null) setState(() => _total = picked);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final left = _left;
    final warn = left <= MatchTimerTuning.warnAt;
    final seconds = (left.inMilliseconds / 1000).ceil();
    final time = '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
    final fraction = _total.inMilliseconds == 0 ? 0.0 : left.inMilliseconds / _total.inMilliseconds;
    return PageFrame(
      title: s.matchTimerTitle,
      sub: s.other.matchTimerTitle,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox.square(
              dimension: MatchTimerLayout.ringSize,
              child: CustomPaint(
                painter: _RingPainter(fraction, warn ? MatchTimerLayout.ringWarn : MatchTimerLayout.ringNormal),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _started ? null : _edit,
                        child: Semantics(
                          button: !_started,
                          label: _started ? null : s.timerEdit,
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            Text(time,
                                style: const TextStyle(
                                    fontFamily: Fonts.display,
                                    fontSize: MatchTimerLayout.timeFont,
                                    fontFeatures: [FontFeature.tabularFigures()])),
                            if (!_started) ...[
                              const SizedBox(height: MatchTimerLayout.penGap),
                              MangaIcon(IconArt.pen, size: MatchTimerLayout.penSize),
                            ],
                          ]),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: MatchTimerLayout.sectionGap),
            if (!_started)
              _TimerButton(label: s.timerPlay, color: Palette.sun, onTap: _play)
            else
              Row(mainAxisSize: MainAxisSize.min, children: [
                if (!_ended) ...[
                  _TimerButton(label: _running ? s.timerPause : s.timerResume, onTap: _togglePause),
                  const SizedBox(width: MatchTimerLayout.buttonGap),
                ],
                _TimerButton(label: s.timerStop, onTap: _stop),
              ]),
          ],
        ),
      ),
    );
  }
}

class _TimerButton extends StatelessWidget {
  const _TimerButton({required this.label, required this.onTap, this.color = Palette.paper});

  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: MatchTimerLayout.buttonWidth,
        height: MatchTimerLayout.buttonHeight,
        child: InkButton(
          onTap: onTap,
          color: color,
          child: Text(label,
              style: const TextStyle(fontWeight: Weights.black, fontSize: MatchTimerLayout.buttonFont)),
        ),
      );
}

/// A ring full at [fraction] 1, its arc from 12 o'clock shortening back
/// towards it: the end retreats counter-clockwise.
class _RingPainter extends CustomPainter {
  const _RingPainter(this.fraction, this.color);

  final double fraction;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = MatchTimerLayout.ringStroke;
    final rect = (Offset.zero & size).deflate(stroke / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;
    canvas.drawArc(rect, 0, math.pi * 2, false, paint..color = MatchTimerLayout.track);
    if (fraction > 0) canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * fraction, false, paint..color = color);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.fraction != fraction || old.color != color;
}

class _SetTimeSheet extends StatefulWidget {
  const _SetTimeSheet({required this.initial});

  final Duration initial;

  @override
  State<_SetTimeSheet> createState() => _SetTimeSheetState();
}

class _SetTimeSheetState extends State<_SetTimeSheet> {
  late final _minutes = TextEditingController(text: '${widget.initial.inMinutes}');
  late final _seconds = TextEditingController(text: '${widget.initial.inSeconds % 60}');

  @override
  void dispose() {
    _minutes.dispose();
    _seconds.dispose();
    super.dispose();
  }

  void _set() {
    final m = (int.tryParse(_minutes.text) ?? 0).clamp(0, MatchTimerTuning.maxMinutes);
    final sec = (int.tryParse(_seconds.text) ?? 0).clamp(0, MatchTimerTuning.maxSeconds);
    final total = Duration(minutes: m, seconds: sec);
    if (total > Duration.zero) Navigator.pop(context, total);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: EdgeInsets.fromLTRB(Gaps.gutter, Gaps.gutter, Gaps.gutter, Gaps.gutter + MediaQuery.viewInsetsOf(context).bottom),
          child: Material(
            type: MaterialType.transparency,
            child: MangaPanel(
              padding: MatchTimerLayout.sheetPadding,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(s.timerSetTitle,
                      style: const TextStyle(
                          fontFamily: Fonts.display,
                          fontSize: MatchTimerLayout.sheetTitle,
                          height: TypeScale.displayLineHeight)),
                  const SizedBox(height: MatchTimerLayout.sheetGap),
                  Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _Field(controller: _minutes, label: s.timerMinutes, autofocus: true),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text(':', style: TextStyle(fontFamily: Fonts.display, fontSize: MatchTimerLayout.colonFont)),
                    ),
                    _Field(controller: _seconds, label: s.timerSeconds),
                  ]),
                  const SizedBox(height: MatchTimerLayout.sheetGap),
                  SizedBox(
                    height: MatchTimerLayout.buttonHeight,
                    child: InkButton(
                      onTap: _set,
                      color: Palette.sun,
                      child: Text(s.done,
                          style: const TextStyle(fontWeight: Weights.black, fontSize: MatchTimerLayout.buttonFont)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.controller, required this.label, this.autofocus = false});

  final TextEditingController controller;
  final String label;
  final bool autofocus;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: MatchTimerLayout.fieldWidth,
        child: Column(children: [
          DecoratedBox(
            decoration: BoxDecoration(border: Border.all(color: Palette.ink, width: MatchTimerLayout.fieldBorder)),
            child: TextField(
              controller: controller,
              autofocus: autofocus,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(2)],
              onTap: () => controller.selection = TextSelection(baseOffset: 0, extentOffset: controller.text.length),
              style: const TextStyle(fontFamily: Fonts.display, fontSize: MatchTimerLayout.fieldFont),
              decoration: const InputDecoration(border: InputBorder.none, isDense: true),
            ),
          ),
          Text(label,
              style: const TextStyle(
                  fontWeight: Weights.black, fontSize: MatchTimerLayout.fieldLabelFont, color: Palette.inkSoft)),
        ]),
      );
}
