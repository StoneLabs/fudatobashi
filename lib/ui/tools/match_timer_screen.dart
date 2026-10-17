import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../config/vector_art.dart';
import '../../l10n/match_timer_strings.dart';
import '../../l10n/strings.dart';
import '../../state/match_timer_alerts.dart';
import '../../state/scope.dart';
import '../cards/page_frame.dart';
import '../manga/manga.dart';
import '../sound/sounds.dart';

/// The match timer (Help › Tools): a dial on a desk panel whose ring empties
/// counter-clockwise round the time left, which can be set before it starts.
/// The last two minutes of the ring are always red; a sound marks reaching
/// them, and a second one zero. Time comes from the wall clock, so it stays
/// right however late a tick lands, and [MatchTimerAlerts] keeps the screen
/// on and the sounds coming while it runs.
class MatchTimerScreen extends StatefulWidget {
  const MatchTimerScreen({super.key, this.now = DateTime.now});

  /// The clock; replaced in tests.
  final DateTime Function() now;

  @override
  State<MatchTimerScreen> createState() => _MatchTimerScreenState();
}

class _MatchTimerScreenState extends State<MatchTimerScreen> {
  late final _alerts = MatchTimerAlerts(now: widget.now);
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

  MatchTimerNotice get _notice {
    final s = S.of(context);
    return (
      title: s.matchTimerTitle,
      text: s.timerNoticeText(MatchTimerTuning.warnAt.inMinutes),
      channel: s.matchTimerTitle,
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _alerts.release();
    super.dispose();
  }

  void _play() {
    setState(() {
      _started = true;
      _runningSince = widget.now();
      _warned = _left <= MatchTimerTuning.warnAt;
    });
    _ticker = Timer.periodic(MatchTimerTuning.tick, (_) => _onTick());
    unawaited(_startAlerts());
  }

  /// The timer is already running behind the question, so asking costs the
  /// match no time.
  Future<void> _startAlerts() async {
    await _askForNotificationsOnce();
    if (mounted && _running) _alerts.run(_left, _notice);
  }

  Future<void> _askForNotificationsOnce() async {
    final progress = ProgressScope.read(context);
    if (progress.settings.timerNotificationsAsked || !await _alerts.needsNotificationPermission() || !mounted) return;
    unawaited(progress.updateSettings(progress.settings.copyWith(timerNotificationsAsked: true)));
    final go = await showMangaSheet<bool>(
      context,
      barrierColor: MatchTimerLayout.sheetBarrier,
      barrierLabel: S.of(context).cancel,
      builder: (_) => const _NotifySheet(),
    );
    if (go == true) await _alerts.askNotificationPermission();
  }

  void _togglePause() {
    if (_running) {
      setState(() {
        _banked = _elapsed;
        _runningSince = null;
      });
      _alerts.release();
    } else {
      setState(() => _runningSince = widget.now());
      _alerts.run(_left, _notice);
    }
  }

  void _stop() {
    _ticker?.cancel();
    _alerts.release();
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
      if (MatchTimerTuning.warnAt - left <= MatchTimerTuning.lateSoundGrace) {
        playSound(context, MatchTimerTuning.warnSound);
      }
    }
    if (left == Duration.zero) {
      final overdue = _elapsed - _total;
      _ended = true;
      _ticker?.cancel();
      _banked = _total;
      _runningSince = null;
      _alerts.finish();
      if (overdue <= MatchTimerTuning.lateSoundGrace) playSound(context, MatchTimerTuning.endSound);
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
    final seconds = (left.inMilliseconds / 1000).ceil();
    final time = '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
    return PageFrame(
      title: s.matchTimerTitle,
      sub: s.other.matchTimerTitle,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(Gaps.gutter, 0, Gaps.gutter, Gaps.gutter),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: MangaPanel(
              color: Palette.desk,
              tone: MatchTimerLayout.panelTone,
              shadow: const Offset(MatchTimerLayout.panelShadow, MatchTimerLayout.panelShadow),
              padding: MatchTimerLayout.panelPadding,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox.square(
                    dimension: MatchTimerLayout.dialSize,
                    child: CustomPaint(
                      painter: _DialPainter(left: left, total: _total),
                      child: Center(
                        child: GestureDetector(
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
                                      color: Palette.ink,
                                      fontFeatures: [FontFeature.tabularFigures()])),
                              if (!_started) ...[
                                const SizedBox(height: MatchTimerLayout.penGap),
                                MangaIcon(IconArt.pen, size: MatchTimerLayout.penSize),
                              ],
                            ]),
                          ),
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
          ),
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

/// The dial: a paper face inside a ring of the time left, with a tick
/// outside it for every minute of [total] (a longer one every five) from 0
/// at 12 o'clock. The ring runs clockwise from 12 o'clock to the share of
/// [total] still [left]; its first stretch, the last [MatchTimerTuning.warnAt]
/// of the match, is red, the rest blue, so the blue end retreats first.
class _DialPainter extends CustomPainter {
  const _DialPainter({required this.left, required this.total});

  final Duration left;
  final Duration total;

  static const _top = -math.pi / 2;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = size.center(Offset.zero);
    final outer = size.shortestSide / 2 - MatchTimerLayout.tickGap - MatchTimerLayout.majorTick;
    final inner = outer - MatchTimerLayout.ringStroke;
    final band = Rect.fromCircle(center: centre, radius: outer - MatchTimerLayout.ringStroke / 2);
    final ink = Paint()
      ..style = PaintingStyle.stroke
      ..color = Palette.ink;

    canvas.drawCircle(centre, outer, Paint()..color = Palette.paper);
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = MatchTimerLayout.ringStroke
      ..strokeCap = StrokeCap.butt;
    canvas.drawArc(band, 0, math.pi * 2, false, ring..color = MatchTimerLayout.track);
    final totalMs = total.inMilliseconds;
    if (totalMs > 0) {
      final leftShare = left.inMilliseconds / totalMs;
      final warnShare = math.min(MatchTimerTuning.warnAt.inMilliseconds / totalMs, 1.0);
      // The red is drawn over the whole blue, so the two meet edge to edge
      // with no track showing through the seam.
      if (leftShare > 0) {
        final warnSweep = math.pi * 2 * math.min(leftShare, warnShare);
        canvas.drawArc(band, _top, math.pi * 2 * leftShare, false, ring..color = MatchTimerLayout.ringNormal);
        canvas.drawArc(band, _top, warnSweep, false, ring..color = MatchTimerLayout.ringWarn);
      }
      final from = outer + MatchTimerLayout.tickGap;
      for (var minute = 0; minute * Duration.millisecondsPerMinute < totalMs; minute++) {
        final major = minute % MatchTimerLayout.majorEvery == 0;
        final angle = _top + math.pi * 2 * minute * Duration.millisecondsPerMinute / totalMs;
        final along = Offset(math.cos(angle), math.sin(angle));
        final to = from + (major ? MatchTimerLayout.majorTick : MatchTimerLayout.minorTick);
        canvas.drawLine(centre + along * from, centre + along * to,
            ink..strokeWidth = major ? MatchTimerLayout.majorTickWidth : MatchTimerLayout.minorTickWidth);
      }
    }
    // The 12 o'clock line across the band covers the seam where the ring
    // starts and, when full, ends.
    canvas.drawLine(centre + Offset(0, -inner), centre + Offset(0, -outer), ink..strokeWidth = MatchTimerLayout.startLine);
    canvas.drawCircle(centre, outer, ink..strokeWidth = MatchTimerLayout.ringOutline);
    canvas.drawCircle(centre, inner, ink..strokeWidth = MatchTimerLayout.ringOutline);
  }

  @override
  bool shouldRepaint(_DialPainter old) => old.left != left || old.total != total;
}

/// A bottom sheet panel: a title over [children].
class _Sheet extends StatelessWidget {
  const _Sheet({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
                Gaps.gutter, Gaps.gutter, Gaps.gutter, Gaps.gutter + MediaQuery.viewInsetsOf(context).bottom),
            child: Material(
              type: MaterialType.transparency,
              child: MangaPanel(
                padding: MatchTimerLayout.sheetPadding,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontFamily: Fonts.display,
                            fontSize: MatchTimerLayout.sheetTitle,
                            height: TypeScale.displayLineHeight)),
                    const SizedBox(height: MatchTimerLayout.sheetGap),
                    ...children,
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

class _SheetButton extends StatelessWidget {
  const _SheetButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: MatchTimerLayout.buttonHeight,
        child: InkButton(
          onTap: onTap,
          color: Palette.sun,
          child: Text(label, style: const TextStyle(fontWeight: Weights.black, fontSize: MatchTimerLayout.buttonFont)),
        ),
      );
}

/// Why the timer would like to show a notification, before Android asks.
class _NotifySheet extends StatelessWidget {
  const _NotifySheet();

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return _Sheet(title: s.timerNotifyTitle, children: [
      Text(s.timerNotifyReason,
          style: const TextStyle(
              fontWeight: Weights.bold, fontSize: MatchTimerLayout.sheetBody, height: MatchTimerLayout.sheetLineHeight)),
      const SizedBox(height: MatchTimerLayout.sheetGap),
      _SheetButton(label: s.timerNotifyContinue, onTap: () => Navigator.pop(context, true)),
    ]);
  }
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
    return _Sheet(title: s.timerSetTitle, children: [
      Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
        _Field(controller: _minutes, label: s.timerMinutes, autofocus: true),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Text(':', style: TextStyle(fontFamily: Fonts.display, fontSize: MatchTimerLayout.colonFont)),
        ),
        _Field(controller: _seconds, label: s.timerSeconds),
      ]),
      const SizedBox(height: MatchTimerLayout.sheetGap),
      _SheetButton(label: s.done, onTap: _set),
    ]);
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
