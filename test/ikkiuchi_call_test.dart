// 一騎打ち's call: when the reader's sounds are heard, from a recording's
// onsets or at the even pace, and the recordings' data file.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/config/config.dart';
import 'package:fudatobashi/data/reader_onsets.dart';
import 'package:fudatobashi/domain/ikkiuchi_call.dart';

void main() {
  double ms(Duration d) => d.inMicroseconds / Duration.microsecondsPerMillisecond;
  final lead = ms(IkkiuchiReaderTuning.lead), step = ms(IkkiuchiReaderTuning.perSound);

  group('A call', () {
    test('without a recording is heard sound by sound at the even pace', () {
      final call = IkkiuchiCall(15, ['き', 'み', 'が', 'た', 'め', 'は']);
      expect(call.onsets, [for (var i = 0; i < 6; i++) lead + i * step]);
      expect(call.heardAt(0), lead > 0 ? 0 : 1);
      for (var i = 0; i < 6; i++) {
        expect(call.heardAt(call.onsets[i] - 1), i, reason: 'just before sound ${i + 1}');
        expect(call.heardAt(call.onsets[i]), i + 1, reason: 'as sound ${i + 1} starts');
      }
      expect(call.heardAt(call.onsets.last + 10 * step), 6, reason: 'never more than its sounds');
      expect(call.decidedAt, call.onsets.last);
    });

    test("with a recording is heard at its onsets, the sounds it doesn't time at the even pace after them", () {
      expect(IkkiuchiCall(1, ['あ', 'き', 'の'], recorded: [120, 480, 900]).onsets, [120, 480, 900]);
      expect(IkkiuchiCall(1, ['あ', 'き', 'の'], recorded: [120]).onsets, [120, 120 + step, 120 + 2 * step]);
      expect(IkkiuchiCall(87, ['む'], recorded: [200, 500]).onsets, [200], reason: 'only its own sounds');
    });
  });

  group('The recordings', () {
    test('are read from their file, by card, in order; a card with none has none', () {
      final onsets = ReaderOnsets.fromJsonString('''
        {"about": "a note", "recordings": [
          {"file": "voice/reader/001.m4a", "card": 1, "onsets": [180, 520, 860]},
          {"file": "voice/reader/002.m4a", "card": 2, "onsets": [90.5, 400]},
          {"file": "voice/reader/001b.m4a", "card": 1, "onsets": [200, 600, 950]}
        ]}''');
      expect([for (final r in onsets.of(1)) r.file], ['voice/reader/001.m4a', 'voice/reader/001b.m4a']);
      expect(onsets.of(1).first.onsets, [180, 520, 860]);
      expect(onsets.of(2).single.onsets, [90.5, 400]);
      expect(onsets.of(3), isEmpty);
      expect(ReaderOnsets.none.of(1), isEmpty);
    });

    test('the bundled file reads', () {
      expect(() => ReaderOnsets.fromJsonString(File(readerOnsetsAsset).readAsStringSync()), returnsNormally);
    });
  });
}
