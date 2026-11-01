// Shared by the tests that step through a recorded game's Field review.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/l10n/ankiren_review_strings.dart';
import 'package:fudatobashi/l10n/strings.dart';
import 'package:fudatobashi/ui/history/review_parts.dart';
import 'package:fudatobashi/ui/results/run_summary.dart';

import 'test_screens.dart';

/// The Field's step box: the panel holding the forward button.
Finder stepBox(S s) => find.ancestor(of: find.bySemanticsLabel(s.ankirenStepNext), matching: find.byType(ReviewSlab));

/// [text] in the step box.
Finder inStepBox(S s, String text) => find.descendant(of: stepBox(s), matching: find.text(text));

/// Starts the review on the Field tab shown and steps forward through all
/// [calls], checking at each that the step box keeps its size and that it
/// and what lies under it keep their place; [check] looks at each call.
/// At the calls named in [shots] it renders the screen as [screen], that
/// name its variant, with the box at the bottom of the screen.
Future<void> stepThroughReview(WidgetTester tester, S s, int calls,
    {required String screen,
    required String lang,
    Map<int, String> shots = const {},
    void Function(int call)? check}) async {
  final start = find.text(s.ankirenStartReview.toUpperCase());
  await tester.ensureVisible(start);
  await tester.pumpAndSettle();
  await tester.tap(start);
  await tester.pumpAndSettle();
  await Scrollable.ensureVisible(tester.element(stepBox(s)), alignment: 1);
  await tester.pumpAndSettle();
  final box = tester.getRect(stepBox(s));
  final below = find.byType(TileBand).evaluate().isEmpty ? null : find.byType(TileBand).first;
  final belowTop = below == null ? null : tester.getTopLeft(below).dy;
  for (var call = 0; call < calls; call++) {
    expect(tester.takeException(), isNull, reason: 'call ${call + 1}');
    expect(tester.getRect(stepBox(s)), box, reason: 'call ${call + 1} keeps the box\'s size and place');
    if (below != null) expect(tester.getTopLeft(below).dy, belowTop, reason: 'call ${call + 1}');
    check?.call(call);
    if (shots[call] case final name?) await captureScreen(tester, screen, lang: lang, variant: name);
    if (call < calls - 1) {
      await tester.tap(find.bySemanticsLabel(s.ankirenStepNext));
      await tester.pumpAndSettle();
    }
  }
}
