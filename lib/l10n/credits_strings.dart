import 'strings.dart';

/// Strings for the "Licenses & credits" screen.
extension CreditsStrings on S {
  String get credits => t('Licenses & credits', 'ライセンス・クレジット');

  String get creditsFonts => t('Fonts', 'フォント');

  String get creditsCardKana => t('Card kana', '取り札のかな');
  String get creditsCardKanaBody => t(
        'The kana on the torifuda cards are pre-rendered images made from the '
            'font A-OTF 正楷書CB1 Std by Morisawa Inc. The font itself is not '
            'bundled with this app.',
        '取り札のかなは、モリサワのフォント「A-OTF 正楷書CB1 Std」を使って書き出した画像です。'
            'フォント自体はこのアプリには含まれていません。',
      );

  String get creditsSounds => t('Sounds', '効果音');
  String get creditsSoundsBody => t(
        'Sound effects by Kenney (www.kenney.nl): Music Jingles, Impact Sounds '
            'and Interface Sounds. Released under CC0 — credit is not required, '
            'but we give it gladly.',
        '効果音はKenney（www.kenney.nl）による提供です：Music Jingles、Impact Sounds、'
            'Interface Sounds。CC0で公開されており表記の義務はありませんが、感謝を込めて記載しています。',
      );

  String get creditsPoemData => t('Poem data', '歌のデータ');
  String get creditsPoemDataBody => t(
        "Poem text and readings come from StoneLabs' hyakuninissyu-csv "
            '(github.com/StoneLabs/hyakuninissyu-csv), released under the '
            'Unlicense (public domain). The 百人一首 poems themselves are in the '
            'public domain.',
        '歌の本文と読みは、StoneLabsの「hyakuninissyu-csv」'
            '（github.com/StoneLabs/hyakuninissyu-csv）を使用しています。'
            'Unlicense（パブリックドメイン）で公開されています。'
            '百人一首の歌そのものもパブリックドメインです。',
      );

  String get creditsInspiration => t('Inspiration', 'インスピレーション');
  String get creditsInspirationBody => t(
        'Inspired by the Fudaotoshi app (jp.excd.fudaotoshi). Not affiliated '
            'with or endorsed by its developer.',
        'Fudaotoshiアプリ（jp.excd.fudaotoshi）から着想を得ています。開発元とは関係ありません。',
      );

  String get creditsOpenSource => t('Open-source packages', 'オープンソース・パッケージ');
  String get creditsOpenSourceBody => t(
        'Flutter, Dart and every package this app is built on.',
        'Flutter・Dart、そしてこのアプリが利用しているすべてのパッケージ。',
      );
  String get creditsViewPackages => t('View package licenses', 'パッケージのライセンスを見る');
  String get creditsViewLicense => t('View full license text', 'ライセンス全文を見る');
}
