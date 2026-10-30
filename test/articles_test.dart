// The article files: every article in every language, every picture an
// article names in some version, and the about-card editor's idea of where
// the card files are and which poses Tobi has.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/data/joka.dart';
import 'package:fudatobashi/l10n/articles.dart';
import 'package:fudatobashi/l10n/card_explanations.dart';
import 'package:fudatobashi/ui/manga/tobi.dart';

const _languages = ['en', 'ja'];

const _articles = [Articles.rules, Articles.karutaGuide, Articles.teiichiGuide];

final _cards = [jokaNumber, for (var id = 1; id <= 100; id++) id];

/// The pictures [source] names, `![…](path)` on a line of its own.
Iterable<String> _pictures(String source) =>
    RegExp(r'^!\[[^\]]*\]\(([^)\s]+)\)\s*$', multiLine: true).allMatches(source).map((m) => m[1]!);

void main() {
  test('every article and card is there in every language', () {
    for (final code in _languages) {
      for (final name in [..._articles, for (final id in _cards) CardExplanations.article(id)]) {
        expect(File(Articles.asset(code, name)).existsSync(), isTrue, reason: '$code $name');
      }
    }
  });

  test('every picture an article names is in the pictures folder, in some version for every reader', () {
    final files = {
      for (final f in Directory(ArticlePictures.folder).existsSync() ? Directory(ArticlePictures.folder).listSync() : <FileSystemEntity>[])
        f.path,
    };
    for (final code in _languages) {
      for (final file in Directory('assets/l10n/${code}_articles').listSync(recursive: true).whereType<File>()) {
        for (final src in _pictures(file.readAsStringSync())) {
          expect(src, startsWith(ArticlePictures.folder), reason: '${file.path}: $src');
          for (final romaji in [false, true]) {
            expect(files, contains(ArticlePictures.pick(src, files, language: code, romaji: romaji)),
                reason: '${file.path}: $src, ${romaji ? 'romaji' : 'kana'}');
          }
        }
      }
    }
  });

  group('the about-card editor', () {
    final config = File('tool/about_card_editor/js/config.js').readAsStringSync();

    test('keeps the card files where the app reads them', () {
      final folders = RegExp(r"FOLDERS: \{([^}]*)\}").firstMatch(config)![1]!;
      for (final code in _languages) {
        final folder = RegExp("$code: '([^']*)'").firstMatch(folders)![1]!;
        for (final id in _cards) {
          expect('$folder${id.toString().padLeft(3, '0')}.md', CardExplanations.asset(code, id));
        }
      }
      expect(int.parse(RegExp(r'CARD_COUNT: (\d+)').firstMatch(config)![1]!), _cards.length - 1, reason: 'and the 序歌');
    });

    test('knows Tobi\'s poses', () {
      final poses = jsonDecode(RegExp(r'TOBI_POSES: (\[[^\]]*\])').firstMatch(config)![1]!.replaceAll("'", '"')) as List;
      expect(poses.toSet(), {for (final p in TobiPose.values) p.fileName});
    });
  });
}
