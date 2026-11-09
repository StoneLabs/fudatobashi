// The labels along a hero's bar: one too wide for its part and for the
// bar's rest is left out, unless it is to be kept, when it lies over the
// wider of the two.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/config/design.dart';
import 'package:fudatobashi/ui/results/run_summary.dart';

import 'test_vector_art.dart';

void main() {
  loadTestVectorArt();

  // In the test font every letter is a square as wide as the font is tall:
  // 22 letters are wider than either half of a 352 dp bar, narrower than it.
  const text = 'ABCDEFGHIJKLMNOPQRSTUV';
  const width = 352.0;

  Future<Rect?> placed(WidgetTester tester, {required double share, required bool keep}) async {
    await tester.pumpWidget(MaterialApp(
      home: Center(
        child: SizedBox(
          width: width,
          height: 188,
          child: HeroPanel(SummaryHero(
            banner: 'RATING',
            body: const SizedBox(),
            bar: [BarPart(Palette.sea, share), BarPart(Palette.paper, 1 - share)],
            labels: [BarLabel(text, keep: keep)],
            pose: null,
          )),
        ),
      ),
    ));
    final label = find.text(text);
    return label.evaluate().isEmpty ? null : tester.getRect(label);
  }

  testWidgets('a label that fits neither part is left out', (tester) async {
    expect(await placed(tester, share: 0.5, keep: false), isNull);
  });

  testWidgets('a label kept lies over the wider part, from the bar\'s start or to its end', (tester) async {
    final overSea = await placed(tester, share: 0.55, keep: true);
    final bar = tester.getRect(find.byType(HeroPanel));
    expect(overSea, isNotNull);
    expect(overSea!.left, closeTo(bar.left + SummaryHeroLayout.labelStart, 1));

    final overRest = await placed(tester, share: 0.45, keep: true);
    expect(overRest, isNotNull);
    expect(overRest!.right, closeTo(bar.right - SummaryHeroLayout.labelStart, 1));
  });
}
