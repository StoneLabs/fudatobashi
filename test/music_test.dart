import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/ui/sound/sounds.dart';

void main() {
  group('Music.gainFor (the music volume slider\'s curve)', () {
    test('spans silence to full gain', () {
      expect(Music.gainFor(0), 0);
      expect(Music.gainFor(1), 1);
    });

    test('rises all along the slider', () {
      for (var i = 0; i < 10; i++) {
        expect(Music.gainFor((i + 1) / 10), greaterThan(Music.gainFor(i / 10)));
      }
    });

    test('halfway is at least 10 dB down, where it sounds about half as loud', () {
      expect(Music.gainFor(0.5), lessThan(0.32));
    });
  });
}
