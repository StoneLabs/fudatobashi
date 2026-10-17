/* Hepburn romaji, ported from lib/l10n/romaji.dart (hepburn): っ doubles the
   next consonant, long vowels stay as written (ou, uu), anything that is not
   kana passes through. One addition, as asked for the marked kana: ん before
   a vowel or y is written n' (the app's hepburn() does not do this yet). */
const Romaji = (() => {
  const SOUNDS = {};
  const row = (kana, consonants, vowels = 'aiueo') =>
    [...kana].forEach((k, i) => { SOUNDS[k] = [Array.isArray(consonants) ? consonants[i] : consonants, vowels[i]]; });
  row('あいうえお', '');
  row('かきくけこ', 'k');
  row('がぎぐげご', 'g');
  row('さしすせそ', ['s', 'sh', 's', 's', 's']);
  row('ざじずぜぞ', ['z', 'j', 'z', 'z', 'z']);
  row('たちつてと', ['t', 'ch', 'ts', 't', 't']);
  row('だぢづでど', ['d', 'j', 'z', 'd', 'd']);
  row('なにぬねの', 'n');
  row('はひふへほ', ['h', 'h', 'f', 'h', 'h']);
  row('ばびぶべぼ', 'b');
  row('ぱぴぷぺぽ', 'p');
  row('まみむめも', 'm');
  row('やゆよ', 'y', 'auo');
  row('らりるれろ', 'r');
  SOUNDS['わ'] = ['w', 'a'];
  SOUNDS['ゐ'] = ['', 'i'];
  SOUNDS['ゑ'] = ['', 'e'];
  SOUNDS['を'] = ['', 'o'];
  SOUNDS['ん'] = ['n', ''];
  const COMBOS = { き: 'ky', ぎ: 'gy', し: 'sh', じ: 'j', ち: 'ch', ぢ: 'j', に: 'ny', ひ: 'hy', び: 'by', ぴ: 'py', み: 'my', り: 'ry' };
  for (const [base, consonant] of Object.entries(COMBOS)) {
    [['ゃ', 'a'], ['ゅ', 'u'], ['ょ', 'o']].forEach(([small, vowel]) => { SOUNDS[base + small] = [consonant, vowel]; });
  }

  const soundAt = (kana, i) => {
    const pair = SOUNDS[kana.slice(i, i + 2)];
    if (pair && kana.length - i >= 2) return { sound: pair, length: 2 };
    const single = SOUNDS[kana[i]];
    return single ? { sound: single, length: 1 } : null;
  };

  function hepburn(kana) {
    let out = '';
    let doubled = false;
    for (let i = 0; i < kana.length;) {
      if (kana[i] === 'っ') { doubled = true; i++; continue; }
      const at = soundAt(kana, i);
      if (!at) { out += kana[i]; i++; continue; }
      const [consonant, vowel] = at.sound;
      if (doubled && consonant) out += consonant === 'ch' ? 't' : consonant[0];
      doubled = false;
      out += consonant + vowel;
      i += at.length;
      if (consonant === 'n' && vowel === '') {
        const next = soundAt(kana, i);
        if (next && (next.sound[0] === '' || next.sound[0] === 'y')) out += "'";
      }
    }
    return out;
  }
  return { hepburn };
})();
if (typeof module !== 'undefined') module.exports = Romaji;
