// Renders the guides' pictures that are drawn from the app's own cards and
// widgets to PNGs in build/article_figures/, named as the articles expect
// them (the articles name them): one file each, or a version per language
// and kana setting where the picture differs by them.
//
//   ./scripts/article_figures.sh      renders them and converts them to WebP
//                                     in assets/artworks/articles/
//
// Run on its own, `flutter test tool/article_figures/render_figures_test.dart`
// only writes the PNGs.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/data/poem.dart';
import 'package:fudatobashi/state/scope.dart';
import 'package:fudatobashi/state/settings.dart';
import 'package:fudatobashi/ui/app.dart';
import 'package:fudatobashi/ui/manga/manga.dart';

import '../../test/test_card_pages.dart';
import 'figure_layout.dart';
import 'karuta_figures.dart';
import 'kimariji_figures.dart';

const _out = 'build/article_figures';

/// A picture: its file [name], whether it has a version per language and
/// per kana setting, and what it shows.
typedef _Figure = ({String name, bool byLanguage, bool byScript, Widget Function() build});

final List<_Figure> _figures = [
  (name: 'karuta_fan', byLanguage: false, byScript: false, build: () => const FanFigure()),
  (
    name: 'karuta_poem_halves',
    byLanguage: false,
    byScript: false,
    build: () => PoemHalvesFigure(poem: poems[KarutaGuideExamples.poem]),
  ),
  (
    name: 'karuta_two_cards',
    byLanguage: false,
    byScript: false,
    build: () => TwoCardsFigure(poem: poems[KarutaGuideExamples.poem]),
  ),
  (name: 'karuta_field', byLanguage: false, byScript: false, build: () => const FieldFigure()),
  (name: 'karuta_one_sound', byLanguage: false, byScript: true, build: () => const OneSoundFigure()),
  (name: 'karuta_kimariji_long', byLanguage: false, byScript: true, build: () => const KimarijiLongFigure()),
  (name: 'karuta_kimariji_change', byLanguage: true, byScript: true, build: () => const KimarijiChangeFigure()),
  (name: 'kimariji_pair', byLanguage: false, byScript: true, build: () => const PairFigure()),
  (name: 'kimariji_read', byLanguage: true, byScript: true, build: () => const ReadFigure()),
  (
    name: 'kimariji_stairs',
    byLanguage: true,
    byScript: true,
    build: () => const StairsFigure(FirstSoundsExamples.card),
  ),
  (
    name: 'kimariji_stairs_consonant',
    byLanguage: true,
    byScript: true,
    build: () => const StairsFigure(FirstSoundsExamples.consonant),
  ),
  (
    name: 'kimariji_stairs_whole_kana',
    byLanguage: true,
    byScript: true,
    build: () => const StairsFigure(FirstSoundsExamples.card, kanaOnly: true),
  ),
];

const _languages = ['en', 'ja'];
const _scripts = [KimarijiScript.hiragana, KimarijiScript.romaji];

void main() {
  loadCardPageData();
  setUpAll(loadAppFonts);

  for (final figure in _figures) {
    testWidgets(figure.name, (tester) async {
      await tester.binding.setSurfaceSize(const Size(FigureFile.width, FigureFile.maxHeight));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await loadCardArt(tester);
      for (final lang in figure.byLanguage ? _languages : [_languages.first]) {
        for (final script in figure.byScript ? _scripts : [_scripts.first]) {
          final p = await openPlayer(tester, lang);
          await tester.runAsync(() => p.updateSettings(p.settings.copyWith(kimarijiScript: script)));
          await tester.pumpWidget(ProgressScope(
            progress: p,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: buildMangaTheme(),
              builder: withUiFont,
              home: UnconstrainedBox(
                constrainedAxis: Axis.horizontal,
                alignment: Alignment.topLeft,
                child: Align(
                  alignment: Alignment.topLeft,
                  child: RepaintBoundary(
                    key: const ValueKey('figure'),
                    child: SizedBox(width: FigureFile.width, child: TickerMode(enabled: false, child: figure.build())),
                  ),
                ),
              ),
            ),
          ));
          await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
          await tester.pump();
          expect(tester.takeException(), isNull);
          final name = [
            figure.name,
            if (figure.byScript) '_${script.name}',
            if (figure.byLanguage) '.$lang',
          ].join();
          await _write(tester, '$_out/$name.png');
        }
      }
      await tester.pumpWidget(const SizedBox());
    });
  }
}

Future<void> _write(WidgetTester tester, String path) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(const ValueKey('figure')));
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: FigureFile.pixelRatio);
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    File(path)
      ..createSync(recursive: true)
      ..writeAsBytesSync(png!.buffer.asUint8List());
  });
}
