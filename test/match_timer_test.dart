// Help lists the match timer; Play shows Pause and Stop, the sheet sets a new
// time, Stop resets. With RENDER_SCREENS=1 it writes build/screens/cards/.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/l10n/match_timer_strings.dart';
import 'package:fudatobashi/l10n/strings.dart';
import 'package:fudatobashi/ui/help/help_screen.dart';
import 'package:fudatobashi/ui/tools/match_timer_screen.dart';

import 'test_card_pages.dart';

final _render = Platform.environment['RENDER_SCREENS'] == '1';

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
    if (_render) await capture(tester, 'match_timer_idle');

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
    if (_render) await capture(tester, 'match_timer_running');
    now = now.add(const Duration(minutes: 4));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('01:00'), findsOneWidget);
    if (_render) await capture(tester, 'match_timer_warn');
    await tapOn(tester, find.text(s.timerStop));
  });
}
