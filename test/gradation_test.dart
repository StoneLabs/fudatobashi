import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/config/design.dart';
import 'package:fudatobashi/ui/manga/screentone.dart';

void main() {
  const spec = GradationSpec(
    dot: Palette.sun,
    spacing: 6,
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    radii: [0, 0, 2],
    stops: [0, 0.5, 1],
  );

  test('the dot radius runs through its stops and holds past the ends', () {
    expect(spec.radiusAt(-1), 0);
    expect(spec.radiusAt(0.25), 0);
    expect(spec.radiusAt(0.75), moreOrLessEquals(1));
    expect(spec.radiusAt(1), 2);
    expect(spec.radiusAt(2), 2);
  });

  testWidgets('a gradation rasterises only its toned part, once per size and density', (tester) async {
    const size = Size(120, 200);
    final (image, origin) = Gradation.image(spec, size, 2);
    expect(origin.dy, greaterThan(size.height / 2 - spec.spacing), reason: 'the untoned top half is left out');
    expect(image.width, lessThanOrEqualTo(size.width * 2));
    expect(image.height, lessThanOrEqualTo(((size.height - origin.dy) * 2).ceil()));
    expect(identical(Gradation.image(spec, size, 2).$1, image), isTrue);
    expect(identical(Gradation.image(spec, size, 3).$1, image), isFalse);
  });
}
