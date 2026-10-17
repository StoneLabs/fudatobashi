/// One kana sound in Hepburn romaji, split into its [consonant] (empty for
/// a vowel) and its [vowel] (empty for ん): し is sh + i, きょ is ky + o.
typedef KanaSound = ({String consonant, String vowel});

/// The sound that starts at [at] in [kana] and how many characters it
/// takes: two for a kana with a small ゃ, ゅ or ょ after it (きょ), else one.
/// Null for anything that is not a sound of its own (っ, punctuation).
({KanaSound sound, int length})? soundAt(String kana, int at) {
  if (at + 1 < kana.length) {
    final pair = _sounds[kana.substring(at, at + 2)];
    if (pair != null) return (sound: pair, length: 2);
  }
  final single = _sounds[kana[at]];
  return single == null ? null : (sound: single, length: 1);
}

/// [kana] in lowercase plain Hepburn romaji (いちひき → ichihiki,
/// きょう → kyou): っ doubles the next consonant, long vowels stay as written
/// (ou, uu), and anything that is not kana passes through.
String hepburn(String kana) {
  final out = StringBuffer();
  var doubled = false;
  for (var i = 0; i < kana.length;) {
    if (kana[i] == _sokuon) {
      doubled = true;
      i++;
      continue;
    }
    final at = soundAt(kana, i);
    if (at == null) {
      out.write(kana[i]);
      i++;
      continue;
    }
    final (:consonant, :vowel) = at.sound;
    if (doubled && consonant.isNotEmpty) out.write(consonant == 'ch' ? 't' : consonant[0]);
    doubled = false;
    out
      ..write(consonant)
      ..write(vowel);
    i += at.length;
  }
  return out.toString();
}

const _sokuon = 'っ';

const _sounds = <String, KanaSound>{
  'あ': (consonant: '', vowel: 'a'), 'い': (consonant: '', vowel: 'i'), 'う': (consonant: '', vowel: 'u'),
  'え': (consonant: '', vowel: 'e'), 'お': (consonant: '', vowel: 'o'),
  'か': (consonant: 'k', vowel: 'a'), 'き': (consonant: 'k', vowel: 'i'), 'く': (consonant: 'k', vowel: 'u'),
  'け': (consonant: 'k', vowel: 'e'), 'こ': (consonant: 'k', vowel: 'o'),
  'が': (consonant: 'g', vowel: 'a'), 'ぎ': (consonant: 'g', vowel: 'i'), 'ぐ': (consonant: 'g', vowel: 'u'),
  'げ': (consonant: 'g', vowel: 'e'), 'ご': (consonant: 'g', vowel: 'o'),
  'さ': (consonant: 's', vowel: 'a'), 'し': (consonant: 'sh', vowel: 'i'), 'す': (consonant: 's', vowel: 'u'),
  'せ': (consonant: 's', vowel: 'e'), 'そ': (consonant: 's', vowel: 'o'),
  'ざ': (consonant: 'z', vowel: 'a'), 'じ': (consonant: 'j', vowel: 'i'), 'ず': (consonant: 'z', vowel: 'u'),
  'ぜ': (consonant: 'z', vowel: 'e'), 'ぞ': (consonant: 'z', vowel: 'o'),
  'た': (consonant: 't', vowel: 'a'), 'ち': (consonant: 'ch', vowel: 'i'), 'つ': (consonant: 'ts', vowel: 'u'),
  'て': (consonant: 't', vowel: 'e'), 'と': (consonant: 't', vowel: 'o'),
  'だ': (consonant: 'd', vowel: 'a'), 'ぢ': (consonant: 'j', vowel: 'i'), 'づ': (consonant: 'z', vowel: 'u'),
  'で': (consonant: 'd', vowel: 'e'), 'ど': (consonant: 'd', vowel: 'o'),
  'な': (consonant: 'n', vowel: 'a'), 'に': (consonant: 'n', vowel: 'i'), 'ぬ': (consonant: 'n', vowel: 'u'),
  'ね': (consonant: 'n', vowel: 'e'), 'の': (consonant: 'n', vowel: 'o'),
  'は': (consonant: 'h', vowel: 'a'), 'ひ': (consonant: 'h', vowel: 'i'), 'ふ': (consonant: 'f', vowel: 'u'),
  'へ': (consonant: 'h', vowel: 'e'), 'ほ': (consonant: 'h', vowel: 'o'),
  'ば': (consonant: 'b', vowel: 'a'), 'び': (consonant: 'b', vowel: 'i'), 'ぶ': (consonant: 'b', vowel: 'u'),
  'べ': (consonant: 'b', vowel: 'e'), 'ぼ': (consonant: 'b', vowel: 'o'),
  'ぱ': (consonant: 'p', vowel: 'a'), 'ぴ': (consonant: 'p', vowel: 'i'), 'ぷ': (consonant: 'p', vowel: 'u'),
  'ぺ': (consonant: 'p', vowel: 'e'), 'ぽ': (consonant: 'p', vowel: 'o'),
  'ま': (consonant: 'm', vowel: 'a'), 'み': (consonant: 'm', vowel: 'i'), 'む': (consonant: 'm', vowel: 'u'),
  'め': (consonant: 'm', vowel: 'e'), 'も': (consonant: 'm', vowel: 'o'),
  'や': (consonant: 'y', vowel: 'a'), 'ゆ': (consonant: 'y', vowel: 'u'), 'よ': (consonant: 'y', vowel: 'o'),
  'ら': (consonant: 'r', vowel: 'a'), 'り': (consonant: 'r', vowel: 'i'), 'る': (consonant: 'r', vowel: 'u'),
  'れ': (consonant: 'r', vowel: 'e'), 'ろ': (consonant: 'r', vowel: 'o'),
  'わ': (consonant: 'w', vowel: 'a'), 'ゐ': (consonant: '', vowel: 'i'), 'ゑ': (consonant: '', vowel: 'e'),
  'を': (consonant: '', vowel: 'o'), 'ん': (consonant: 'n', vowel: ''),
  'きゃ': (consonant: 'ky', vowel: 'a'), 'きゅ': (consonant: 'ky', vowel: 'u'), 'きょ': (consonant: 'ky', vowel: 'o'),
  'ぎゃ': (consonant: 'gy', vowel: 'a'), 'ぎゅ': (consonant: 'gy', vowel: 'u'), 'ぎょ': (consonant: 'gy', vowel: 'o'),
  'しゃ': (consonant: 'sh', vowel: 'a'), 'しゅ': (consonant: 'sh', vowel: 'u'), 'しょ': (consonant: 'sh', vowel: 'o'),
  'じゃ': (consonant: 'j', vowel: 'a'), 'じゅ': (consonant: 'j', vowel: 'u'), 'じょ': (consonant: 'j', vowel: 'o'),
  'ちゃ': (consonant: 'ch', vowel: 'a'), 'ちゅ': (consonant: 'ch', vowel: 'u'), 'ちょ': (consonant: 'ch', vowel: 'o'),
  'ぢゃ': (consonant: 'j', vowel: 'a'), 'ぢゅ': (consonant: 'j', vowel: 'u'), 'ぢょ': (consonant: 'j', vowel: 'o'),
  'にゃ': (consonant: 'ny', vowel: 'a'), 'にゅ': (consonant: 'ny', vowel: 'u'), 'にょ': (consonant: 'ny', vowel: 'o'),
  'ひゃ': (consonant: 'hy', vowel: 'a'), 'ひゅ': (consonant: 'hy', vowel: 'u'), 'ひょ': (consonant: 'hy', vowel: 'o'),
  'びゃ': (consonant: 'by', vowel: 'a'), 'びゅ': (consonant: 'by', vowel: 'u'), 'びょ': (consonant: 'by', vowel: 'o'),
  'ぴゃ': (consonant: 'py', vowel: 'a'), 'ぴゅ': (consonant: 'py', vowel: 'u'), 'ぴょ': (consonant: 'py', vowel: 'o'),
  'みゃ': (consonant: 'my', vowel: 'a'), 'みゅ': (consonant: 'my', vowel: 'u'), 'みょ': (consonant: 'my', vowel: 'o'),
  'りゃ': (consonant: 'ry', vowel: 'a'), 'りゅ': (consonant: 'ry', vowel: 'u'), 'りょ': (consonant: 'ry', vowel: 'o'),
};
