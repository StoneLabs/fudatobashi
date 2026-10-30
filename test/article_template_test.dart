import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/l10n/article_template.dart';

void main() {
  String fill(String source, {bool romaji = false}) => ArticleTemplate.fill(source, romaji: romaji);

  test('an expression follows the kana setting', () {
    const source = 'Stairs: {{ "romaji" if env.romaji_mode else "hiragana" }}.';
    expect(fill(source), 'Stairs: hiragana.');
    expect(fill(source, romaji: true), 'Stairs: romaji.');
  });

  test('a block on its own lines leaves no blank line', () {
    const source = 'One\n{% if env.romaji_mode %}\nRomaji\n{% else %}\nKana\n{% endif %}\nTwo';
    expect(fill(source), 'One\nKana\nTwo');
    expect(fill(source, romaji: true), 'One\nRomaji\nTwo');
  });

  test('our own marks pass through unchanged', () {
    const source = '{はるすぎて} and \\{x}\n\n>{.tobi pose=waving} Hi {わ}\n\n![](a.webp){.left}\n\n<!-- picture: a -->\n';
    expect(fill(source), source);
  });

  test('text is not escaped', () {
    expect(fill('{{ "<b>&" }}'), '<b>&');
  });

  test('a name that is not defined is an error', () {
    expect(() => fill('{{ nothing }}'), throwsA(anything));
    expect(() => fill('{{ env.romaji_modee }}'), throwsA(anything));
  });
}
