// HoldToConfirmButton's hint: tapped (pressed and let go before the hold is
// done) enough times in a row, it says to hold, in a balloon beside the
// button that stays on screen at the right edge; one tap, taps too far
// apart, or no hint given says nothing; a full hold still confirms. Then
// 一騎打ち's 終了 gives it, with its hold in seconds.
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/config/config.dart';
import 'package:fudatobashi/config/design.dart';
import 'package:fudatobashi/data/fuda_sets.dart';
import 'package:fudatobashi/data/islands.dart';
import 'package:fudatobashi/data/poem.dart';
import 'package:fudatobashi/db/database.dart';
import 'package:fudatobashi/l10n/ikkiuchi_strings.dart';
import 'package:fudatobashi/l10n/strings.dart';
import 'package:fudatobashi/state/progress.dart';
import 'package:fudatobashi/state/scope.dart';
import 'package:fudatobashi/ui/ikkiuchi/ikkiuchi_match_column.dart';
import 'package:fudatobashi/ui/manga/manga.dart';

import 'test_l10n.dart';
import 'test_vector_art.dart';

void main() {
  loadTestVectorArt();
  loadTestL10n();
  poems = Poems.fromJsonString(File('assets/data/poems.json').readAsStringSync());
  fudaSets = FudaSets(poems);
  archipelago = Archipelago.fromJsonString(File('assets/data/islands.json').readAsStringSync());
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  const hold = Duration(seconds: 1);
  const hint = 'Hold it down';
  const landscape = Size(800, 400);
  const quick = Duration(milliseconds: 200);
  var confirmed = 0;

  Future<void> show(WidgetTester tester, {String? hint = hint}) async {
    confirmed = 0;
    await tester.binding.setSurfaceSize(landscape);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(
      home: Align(
        alignment: Alignment.topRight,
        child: HoldToConfirmButton(
          duration: hold,
          label: 'End',
          hint: hint,
          haptics: false,
          look: IkkiuchiColumnStyle.end,
          onConfirmed: () => confirmed++,
        ),
      ),
    ));
  }

  Future<void> tap(WidgetTester tester, [Duration then = quick]) async {
    await tester.tap(find.byType(HoldToConfirmButton));
    await tester.pump(then);
  }

  Finder said(String text) => find.descendant(of: find.byType(SpeechBalloon), matching: find.text(text));

  testWidgets('two quick taps say to hold, beside the button and on screen', (tester) async {
    await show(tester);
    await tap(tester);
    expect(said(hint), findsNothing);
    await tap(tester);
    expect(said(hint), findsOneWidget);
    expect(confirmed, 0);

    await tester.pump(BalloonPopStyle.pop.duration);
    final balloon = tester.getRect(find.byType(SpeechBalloon));
    final button = tester.getRect(find.byType(HoldToConfirmButton));
    expect([balloon.left, balloon.top], everyElement(greaterThanOrEqualTo(0)));
    expect(balloon.right, lessThanOrEqualTo(landscape.width), reason: 'not cut off at the right edge');
    expect(balloon.bottom, lessThanOrEqualTo(landscape.height));
    expect(balloon.overlaps(button), isFalse, reason: 'beside the button, not over it');
    expect(balloon.top - button.bottom, closeTo(BalloonPopStyle.gap, 0.5), reason: 'right next to it');

    await tester.pump(HoldConfirmTuning.hintLife);
    expect(find.byType(SpeechBalloon), findsNothing, reason: 'gone after its life');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('one tap, or taps too far apart, say nothing; the count starts over after a hint', (tester) async {
    await show(tester);
    await tap(tester, HoldConfirmTuning.hintWindow + quick);
    expect(find.byType(SpeechBalloon), findsNothing, reason: 'one tap');
    await tap(tester, HoldConfirmTuning.hintWindow + quick);
    expect(find.byType(SpeechBalloon), findsNothing, reason: 'the second came after the window');

    await tap(tester);
    await tap(tester);
    expect(said(hint), findsOneWidget, reason: 'two within it');
    await tester.pump(HoldConfirmTuning.hintLife + quick);
    expect(find.byType(SpeechBalloon), findsNothing);
    await tap(tester);
    expect(find.byType(SpeechBalloon), findsNothing, reason: 'the first of the next two');
    await tap(tester);
    expect(said(hint), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('no hint given, taps say nothing', (tester) async {
    await show(tester, hint: null);
    await tap(tester);
    await tap(tester);
    expect(find.byType(SpeechBalloon), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a full hold still confirms, after a tap too, and says nothing', (tester) async {
    await show(tester);
    await tap(tester);
    final press = await tester.startGesture(tester.getCenter(find.byType(HoldToConfirmButton)));
    await tester.pump(quick);
    await tester.pump(hold + quick);
    expect(confirmed, 1);
    await press.up();
    await tester.pump();
    expect(find.byType(SpeechBalloon), findsNothing, reason: 'a hold is not a tap');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets("一騎打ち's 終了 says to hold it, for as many seconds as it takes", (tester) async {
    late Progress p;
    await tester.runAsync(() async {
      p = await Progress.open(AppDatabase(NativeDatabase.memory()));
    });
    await tester.binding.setSurfaceSize(landscape);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var ended = 0;
    await tester.pumpWidget(ProgressScope(
      progress: p,
      child: MaterialApp(
        home: Align(
          alignment: Alignment.centerRight,
          child: SizedBox(
            width: IkkiuchiColumnStyle.width,
            height: landscape.height,
            child: IkkiuchiMatchColumn(
              tobi: 3,
              player: 3,
              split: landscape.height / 2,
              arranging: false,
              onArrange: null,
              onDone: () {},
              onEnd: () => ended++,
            ),
          ),
        ),
      ),
    ));
    final end = find.byType(HoldToConfirmButton);
    await tester.tap(end);
    await tester.pump(quick);
    await tester.tap(end);
    await tester.pump(quick);
    final seconds = (IkkiuchiMatchTuning.endHold.inMilliseconds / Duration.millisecondsPerSecond).round();
    expect(find.descendant(of: find.byType(SpeechBalloon), matching: find.text(const S('en').ikkiuchiEndHint(seconds))),
        findsOneWidget);
    expect(ended, 0);
    await tester.pumpWidget(const SizedBox());
  });
}
