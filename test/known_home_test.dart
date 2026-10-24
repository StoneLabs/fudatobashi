// All-known Home in its four looks: unranked on the first day, unranked
// with some practice, placed and climbing, and in the top class with nothing
// weak. Each lays out on the user's phone with no layout error and shows
// what it is about. With RENDER_SCREENS=1 each is also written to
// build/screens/ as home_known_redo_B<N>_<look>.
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/data/fuda_sets.dart';
import 'package:fudatobashi/data/islands.dart';
import 'package:fudatobashi/data/poem.dart';
import 'package:fudatobashi/db/database.dart';
import 'package:fudatobashi/domain/play_session.dart';
import 'package:fudatobashi/domain/trainer.dart';
import 'package:fudatobashi/l10n/ranked_strings.dart';
import 'package:fudatobashi/l10n/strings.dart';
import 'package:fudatobashi/state/play_config.dart';
import 'package:fudatobashi/state/progress.dart';
import 'package:fudatobashi/ui/app.dart';
import 'package:fudatobashi/ui/home/rank_map.dart';
import 'package:fudatobashi/ui/home/ranked_hero.dart';
import 'package:fudatobashi/ui/manga/manga.dart';

import 'test_l10n.dart';
import 'test_screens.dart';
import 'test_vector_art.dart';

Future<void> _loadFont(String family, List<String> files) async {
  final loader = FontLoader(family);
  for (final f in files) {
    loader.addFont(Future.value(ByteData.sublistView(File('assets/fonts/$f').readAsBytesSync())));
  }
  await loader.load();
}

/// One look of the screen: [days] in a row of practice at [paceMs] a card,
/// missing [misses] cards each day, and the [rating] the ranked runs left.
class _Look {
  const _Look(this.name, {this.days = 0, this.paceMs = 0, this.misses = 0, this.rating});
  final String name;
  final int days, paceMs, misses;
  final double? rating;
}

const _looks = [
  _Look('B1_first_day'),
  _Look('B2_practising', days: 3, paceMs: 620, misses: 18),
  _Look('B3_climbing', days: 6, paceMs: 480, misses: 12, rating: 1388),
  _Look('B4_top', days: 23, paceMs: 290, rating: 2861),
];

void main() {
  loadTestVectorArt();
  loadTestL10n();
  poems = Poems.fromJsonString(File('assets/data/poems.json').readAsStringSync());
  fudaSets = FudaSets(poems);
  archipelago = Archipelago.fromJsonString(File('assets/data/islands.json').readAsStringSync());
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  setUpAll(() async {
    await _loadFont('Dela', ['DelaGothicOne-Regular.ttf']);
    await _loadFont('ZenKaku', [
      'ZenKakuGothicNew-Regular.ttf',
      'ZenKakuGothicNew-Medium.ttf',
      'ZenKakuGothicNew-Bold.ttf',
      'ZenKakuGothicNew-Black.ttf',
    ]);
  });

  final all = [for (final p in poems.all) CardRef(p.id)];

  // One training run of every card on [day], missing the first [misses].
  PlaySession play(DateTime day, int paceMs, int misses) {
    final session = PlaySession(all);
    var t = const Duration(seconds: 100);
    for (var i = 0; i < all.length; i++) {
      session.revealed(t);
      t += Duration(milliseconds: paceMs + i % 5 * 10);
      session.commit(responseTs: t, commitTs: t, outcome: i < misses ? Outcome.dontKnow : Outcome.known, at: day);
      t += const Duration(milliseconds: 100);
    }
    return session;
  }

  Future<Progress> player(WidgetTester tester, _Look look) async {
    late Progress p;
    await tester.runAsync(() async {
      p = await Progress.open(AppDatabase(NativeDatabase.memory()));
      p.tabsAlwaysOpen = true;
      await p.updateSettings(p.settings.copyWith(language: 'en', languagePicked: true, toured: true));
      await p.setLearningMode(LearningMode.allKnown);
      final now = DateTime.now();
      for (var d = look.days - 1; d >= 0; d--) {
        final day = now.subtract(Duration(days: d));
        final run = play(day, look.paceMs, look.misses);
        await p.recordRun(run, const PlayConfig(mode: PlayMode.training), day, now: day);
      }
    });
    p.rating = look.rating;
    return p;
  }

  for (final look in _looks) {
    testWidgets('all-known Home, ${look.name}', (tester) async {
      final p = await player(tester, look);
      useScreen(tester, usersPhone);
      await tester.pumpWidget(RepaintBoundary(key: screenKey, child: FudatobashiApp(progress: p)));
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
      expect(find.byType(RankMap), findsOneWidget);
      expect(find.byType(RankedHero), findsOneWidget);
      final rating = look.rating;
      expect(find.text(const S('en').rankUnplaced), rating == null ? findsOneWidget : findsNothing);
      if (rating != null) expect(find.text('${rating.round()}'), findsOneWidget);
      expect(find.byType(CountBadge), look.misses > 0 ? findsOneWidget : findsNothing, reason: 'the weak count');
      await captureScreen(tester, 'home_known_redo_${look.name}');
      await tester.pumpWidget(const SizedBox());
    });
  }
}
