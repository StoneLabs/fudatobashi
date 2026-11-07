import 'dart:convert';

import 'package:flutter/services.dart';

/// One recording of the reader reading a card: its [file] under `assets/`,
/// the [card] it reads, and [onsets], the ms from the file's start at which
/// each sound of the card's kimariji starts, one per kana.
class ReaderRecording {
  const ReaderRecording({required this.file, required this.card, required this.onsets});

  final String file;
  final int card;
  final List<double> onsets;
}

/// When each sound starts in the reader's recordings, as [readerOnsetsAsset]
/// lists them: a card with none yet is read at an even pace instead
/// (`IkkiuchiCall`).
class ReaderOnsets {
  ReaderOnsets(Iterable<ReaderRecording> recordings) {
    for (final r in recordings) {
      (_byCard[r.card] ??= []).add(r);
    }
  }

  final Map<int, List<ReaderRecording>> _byCard = {};

  /// No recordings at all.
  static final none = ReaderOnsets(const []);

  /// The recordings in [json]: `{"recordings": [{"file": ..., "card": ...,
  /// "onsets": [...]}, ...]}`, any other keys aside.
  factory ReaderOnsets.fromJsonString(String json) => ReaderOnsets([
        for (final r in (jsonDecode(json) as Map<String, dynamic>)['recordings'] as List)
          ReaderRecording(
            file: (r as Map<String, dynamic>)['file'] as String,
            card: r['card'] as int,
            onsets: [for (final ms in r['onsets'] as List) (ms as num).toDouble()],
          ),
      ]);

  static Future<ReaderOnsets> load() async =>
      ReaderOnsets.fromJsonString(await rootBundle.loadString(readerOnsetsAsset));

  /// The recordings of [card], none when it has none yet.
  List<ReaderRecording> of(int card) => _byCard[card] ?? const [];
}

const readerOnsetsAsset = 'assets/data/reader_onsets.json';

/// Loaded once at startup in `main`; none until then.
var readerOnsets = ReaderOnsets.none;
