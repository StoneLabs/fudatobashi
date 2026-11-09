// Help lists the match timer; Play shows Pause and Stop, the sheet sets a new
// time, Stop resets. With RENDER_SCREENS=1 it writes build/screens/cards/.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/l10n/match_timer_strings.dart';
import 'package:fudatobashi/l10n/strings.dart';
import 'package:fudatobashi/ui/help/help_screen.dart';
import 'package:fudatobashi/ui/sound/sounds.dart';
import 'package:fudatobashi/ui/tools/match_timer_screen.dart';

import 'test_card_pages.dart';
import 'test_screens.dart';

class _MusicSpy extends Music {
  final calls = <String>[];

  @override
  void leaveMenu() => calls.add('leave');

  @override
  void enterMenu() => calls.add('enter');
}

/// A page with one button that opens the match timer on top of it.
Widget _timerLauncher(DateTime Function() now) => Builder(
    builder: (context) => TextButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => MatchTimerScreen(now: now))),
        child: const Text('open timer')));

void main() {
  loadCardPageData();
  setUpAll(loadAppFonts);
  final s = S('en');

  testWidgets('match timer: from Help, play, set the time, stop', (tester) async {
    final p = await openPlayer(tester, 'en');
    await showPage(tester, p, const HelpScreen());
    expect(find.text(s.matchTimerTitle), findsOneWidget);
    await tapOn(tester, find.text(s.matchTimerTitle));
    expect(find.text('15:00'), findsOneWidget);
    expect(find.text(s.timerPlay), findsOneWidget);
    await captureScreen(tester, 'cards/match_timer_idle');

    await tapOn(tester, find.text('15:00'));
    await tester.enterText(find.byType(TextField).first, '3');
    await tester.enterText(find.byType(TextField).last, '30');
    await tapOn(tester, find.text(s.done));
    expect(find.text('03:30'), findsOneWidget);

    await tapOn(tester, find.text(s.timerPlay));
    expect(find.text(s.timerPause), findsOneWidget);
    expect(find.text(s.timerStop), findsOneWidget);
    await tapOn(tester, find.text(s.timerPause));
    expect(find.text(s.timerResume), findsOneWidget);

    await tapOn(tester, find.text(s.timerStop));
    expect(find.text('03:30'), findsOneWidget);
    expect(find.text(s.timerPlay), findsOneWidget);
  });

  testWidgets('match timer: running down, on a fake clock', (tester) async {
    final p = await openPlayer(tester, 'en');
    var now = DateTime(2026);
    await showPage(tester, p, MatchTimerScreen(now: () => now));
    await tapOn(tester, find.text(s.timerPlay));
    now = now.add(const Duration(minutes: 10));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('05:00'), findsOneWidget);
    await captureScreen(tester, 'cards/match_timer_running');
    now = now.add(const Duration(minutes: 4));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('01:00'), findsOneWidget);
    await captureScreen(tester, 'cards/match_timer_warn');
    await tapOn(tester, find.text(s.timerStop));
  });

  testWidgets('match timer: the menu music is out while it is open and back after', (tester) async {
    final spy = _MusicSpy();
    final before = music;
    music = spy;
    addTearDown(() => music = before);
    final p = await openPlayer(tester, 'en');
    await showPage(tester, p, _timerLauncher(DateTime.now));
    await tapOn(tester, find.text('open timer'));
    expect(spy.calls, ['leave']);
    await tapOn(tester, find.bySemanticsLabel(s.back));
    expect(find.text('open timer'), findsOneWidget);
    expect(spy.calls, ['leave', 'enter']);
  });

  testWidgets('match timer: leaving asks once it has started, not before or after it ran out', (tester) async {
    final p = await openPlayer(tester, 'en');
    var now = DateTime(2026);
    await showPage(tester, p, _timerLauncher(() => now));

    await tapOn(tester, find.text('open timer'));
    await tapOn(tester, find.bySemanticsLabel(s.back));
    expect(find.text(s.timerLeaveTitle), findsNothing);
    expect(find.text('open timer'), findsOneWidget);

    await tapOn(tester, find.text('open timer'));
    await tapOn(tester, find.text(s.timerPlay));
    await tapOn(tester, find.bySemanticsLabel(s.back));
    expect(find.text(s.timerLeaveTitle), findsOneWidget);
    await captureScreen(tester, 'cards/match_timer_leave');
    await tapOn(tester, find.text(s.timerKeep));
    expect(find.text(s.timerPause), findsOneWidget);

    await tester.binding.handlePopRoute();
    await settle(tester);
    expect(find.text(s.timerLeaveTitle), findsOneWidget);
    await tapOn(tester, find.text(s.timerLeave));
    expect(find.text('open timer'), findsOneWidget);

    await tapOn(tester, find.text('open timer'));
    await tapOn(tester, find.text(s.timerPlay));
    now = now.add(const Duration(minutes: 16));
    await tester.pump(const Duration(milliseconds: 300));
    await tapOn(tester, find.bySemanticsLabel(s.back));
    expect(find.text(s.timerLeaveTitle), findsNothing);
    expect(find.text('open timer'), findsOneWidget);
  });
}
