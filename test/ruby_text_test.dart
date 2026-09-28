import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/config/design.dart';
import 'package:fudatobashi/data/poem.dart';
import 'package:fudatobashi/ui/manga/ruby_text.dart';

void main() {
  group('Ruby.phrases', () {
    test('splits phrases at full-width spaces and readings off their kanji', () {
      expect(Ruby.phrases('[巡|めぐ]り[逢|あ]ひて　[見|み]しやそれとも'), [
        const [RubyRun('巡', 'めぐ'), RubyRun('り'), RubyRun('逢', 'あ'), RubyRun('ひて')],
        const [RubyRun('見', 'み'), RubyRun('しやそれとも')],
      ]);
    });

    test('keeps back-to-back annotated runs apart and multi-kanji runs whole', () {
      expect(Ruby.runs('[春|はる][過|す]ぎて'), const [RubyRun('春', 'はる'), RubyRun('過', 'す'), RubyRun('ぎて')]);
      expect(Ruby.runs('[天|あま]の[香具山|かぐやま]'), const [RubyRun('天', 'あま'), RubyRun('の'), RubyRun('香具山', 'かぐやま')]);
    });

    test('plain kana is one run; empty markup and stray spaces give no empty phrases', () {
      expect(Ruby.phrases('かりほの'), [const [RubyRun('かりほの')]]);
      expect(Ruby.phrases(''), isEmpty);
      expect(Ruby.phrases('　あ　　い　'), [const [RubyRun('あ')], const [RubyRun('い')]]);
    });

    test('an unclosed bracket stays plain text', () {
      expect(Ruby.runs('[巡|めぐり'), const [RubyRun('[巡|めぐり')]);
    });

    test('every poem verse reads back as its plain text', () {
      final poems = Poems.fromJsonString(File('assets/data/poems.json').readAsStringSync());
      for (final poem in poems.all) {
        expect(Ruby.plain(poem.kamiRuby), poem.kami, reason: '#${poem.id}');
        expect(Ruby.plain(poem.shimoRuby), poem.shimo, reason: '#${poem.id}');
        final runs = Ruby.phrases(poem.kamiRuby).expand((p) => p);
        expect(runs.map((r) => r.base).join(), poem.kami.replaceAll(Ruby.phraseBreak, ''), reason: '#${poem.id}');
      }
    });
  });

  group('RubyText', () {
    Future<void> pump(WidgetTester tester, Widget child, {double fontScale = 1}) => tester.pumpWidget(MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(fontScale)),
            child: Scaffold(body: Align(alignment: Alignment.topLeft, child: SizedBox(width: 200, child: child))),
          ),
        ));

    const style = TextStyle(fontSize: 16, height: 1.2);

    testWidgets('lines with and without readings are equally tall, and it sizes to its content', (tester) async {
      await pump(tester, const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        RubyText('かりほの', key: ValueKey('kana'), style: style),
        RubyText('[庵|いほ]の', key: ValueKey('kanji'), style: style),
      ]));
      final kana = tester.getSize(find.byKey(const ValueKey('kana')));
      final kanji = tester.getSize(find.byKey(const ValueKey('kanji')));
      expect(kana.height, kanji.height);
      expect(kana.height, greaterThan(style.fontSize! * (style.height! + RubyStyle.readingScale)));
      expect(kanji.width, lessThan(200));
    });

    testWidgets('a reading is centred over its kanji', (tester) async {
      await pump(tester, const RubyText('[衣|ころも]', style: style));
      final reading = tester.getRect(find.text('ころも'));
      final base = tester.getRect(find.text('衣'));
      expect(reading.center.dx, moreOrLessEquals(base.center.dx, epsilon: 0.01));
      expect(reading.bottom, lessThanOrEqualTo(base.top + 0.01));
    });

    testWidgets('wraps only between phrases, and holds at font scale 1.3', (tester) async {
      const poem = '[巡|めぐ]り[逢|あ]ひて　[見|み]しやそれとも　わかぬ[間|ま]に';
      await pump(tester, const RubyText(poem, style: style), fontScale: 1.3);
      expect(tester.takeException(), isNull);
      final phrases = [find.text('ひて'), find.text('しやそれとも'), find.text('わかぬ')];
      final tops = [for (final f in phrases) tester.getRect(f).top];
      expect(tops.toSet().length, greaterThan(1), reason: 'three phrases of 16 pt × 1.3 need more than one 200 px line');
      expect(tester.getRect(find.text('わかぬ')).top, tester.getRect(find.text('間')).top, reason: 'a phrase never breaks');
    });

    testWidgets('screen readers get the plain verse', (tester) async {
      final semantics = tester.ensureSemantics();
      await pump(tester, const RubyText('[秋|あき]の[田|た]の　かりほの', style: style));
      expect(find.bySemanticsLabel('秋の田の かりほの'), findsOneWidget);
      semantics.dispose();
    });
  });
}
