/* The card data (kimariji, poem, colour group) read from the StoneLabs CSV,
   which only the preview's card on top needs. */
Editor.carddata = (() => {
  const { CARD_COUNT, JOKA_LABEL, CSV_URL } = Editor.config;
  const { $ } = Editor.util;
  const { hepburn } = Editor.Romaji;
  const state = Editor.state;

  /* Splits CSV text into rows of fields; quoted fields may hold commas, quotes ("") and newlines. */
  function parseCsv(text) {
    const rows = [];
    let row = [];
    let field = '';
    let quoted = false;
    for (let i = 0; i < text.length; i++) {
      const c = text[i];
      if (quoted) {
        if (c === '"' && text[i + 1] === '"') { field += '"'; i++; } else if (c === '"') quoted = false; else field += c;
      } else if (c === '"') quoted = true;
      else if (c === ',') { row.push(field); field = ''; } else if (c === '\n' || c === '\r') {
        if (c === '\r' && text[i + 1] === '\n') i++;
        row.push(field); field = '';
        rows.push(row); row = [];
      } else field += c;
    }
    if (field || row.length) { row.push(field); rows.push(row); }
    return rows.filter((r) => r.some((f) => f !== ''));
  }

  function readCsv(text) {
    const rows = parseCsv(text.replace(/^\uFEFF/, ''));
    const head = rows.shift() || [];
    const col = (r, name) => r[head.indexOf(name)] ?? '';
    const out = {};
    for (const r of rows) {
      const label = col(r, 'number');
      const num = label === JOKA_LABEL ? 0 : +label;
      if (!label || !Number.isInteger(num) || num < 0 || num > CARD_COUNT) continue;
      const verse = (i) => col(r, `verse_${i}`);
      const yomi = (i) => col(r, `verse_${i}_hiragana_yomi`);
      out[num] = {
        n: num,
        kimariji: col(r, 'kimariji_kami'),
        kimarijiReading: col(r, 'kimariji_kami_yomi'),
        color: col(r, 'color'),
        author: col(r, 'author_kanji'),
        authorKana: col(r, 'author_hiragana'),
        authorRomaji: hepburn(col(r, 'author_hiragana')).replace(/^./, (c) => c.toUpperCase()),
        kamiRuby: [1, 2, 3].map(verse).join('　'),
        shimoRuby: [4, 5].map(verse).join('　'),
        versesRomaji: [1, 2, 3, 4, 5].map((i) => hepburn(yomi(i))),
      };
    }
    if (!Object.keys(out).length) throw new Error('No cards found in that text.');
    return out;
  }

  function useCsv(text, remember) {
    const msg = $('#csvMsg');
    try {
      state.poems = readCsv(text);
      if (remember) { state.store.csv = text; state.save(); }
      msg.textContent = `Card data loaded for ${Object.keys(state.poems).length} cards.`;
    } catch (e) {
      msg.textContent = `Could not read that CSV: ${e.message}`;
      return false;
    }
    Editor.app.load(state.lang, state.n);
    return true;
  }

  async function loadFromGithub() {
    const msg = $('#csvMsg');
    msg.textContent = 'Loading…';
    try {
      const res = await fetch(CSV_URL);
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      const text = await res.text();
      if (useCsv(text, true)) $('#csv').value = text;
    } catch (e) {
      msg.textContent = 'Could not load from GitHub (' + e.message + '). Please open the link above, copy the whole file, and paste it into the box instead.';
    }
  }

  function wire() {
    $('#csvUse').addEventListener('click', () => useCsv($('#csv').value, true));
    $('#csvGit').addEventListener('click', loadFromGithub);
    $('#csvDrop').addEventListener('click', () => {
      state.store.csv = ''; state.poems = {}; $('#csv').value = ''; state.save();
      $('#csvMsg').textContent = 'Card data removed.';
      Editor.app.load(state.lang, state.n);
    });
  }

  return { useCsv, wire };
})();
