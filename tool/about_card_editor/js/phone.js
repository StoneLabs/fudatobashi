/* The phone on the left: the status bar, the title, the card for reference
   and the poem box, with the Markdown area inside it. */
Editor.phone = (() => {
  const { GROUP_COLORS, NEUTRAL_COLOR, EMPHASIS_TINT, WORDS, ICON_BACK } = Editor.config;
  const { $, esc, cardName, mix } = Editor.util;
  const { hepburn } = Editor.Romaji;
  const state = Editor.state;
  const { paint } = Editor.classes;
  const { poemOf, script } = state;

  /* Phrases end at a full-width space. */
  const phrasesOf = (runs) => {
    const phrases = [[]];
    for (const r of runs) {
      if (r.reading) { phrases[phrases.length - 1].push(r); continue; }
      r.base.split('　').forEach((piece, i) => {
        if (i) phrases.push([]);
        if (piece) phrases[phrases.length - 1].push({ ...r, base: piece });
      });
    }
    return phrases.filter((phrase) => phrase.length);
  };
  const runHtml = (r, marked) => {
    const base = r.reading ? `<ruby>${esc(r.base)}<rt>${esc(r.reading)}</rt></ruby>` : esc(r.base);
    return paint(marked ? `<span class="kh">${base}</span>` : base, r.style);
  };
  /* One line of furigana markup. [kimariji] is how many kana at the start are
     the kimariji (shown in pink). [align] is 'right' for a line set to the right. */
  function rubyLine(markup, kimariji = 0, align = null) {
    let left = kimariji;
    const phrases = phrasesOf(Editor.verse.runs(markup)).map((phrase) => {
      const html = phrase.flatMap((r) => {
        if (left <= 0) return [runHtml(r)];
        if (r.reading || r.base.length <= left) { left -= (r.reading ?? r.base).length; return [runHtml(r, true)]; }
        const cut = left;
        left = 0;
        return [runHtml({ base: r.base.slice(0, cut), style: r.style }, true), runHtml({ base: r.base.slice(cut), style: r.style })];
      }).join('');
      return `<span class="ph">${html}</span>`;
    });
    return `<div class="vl${/\[[^|\]]+\|/.test(markup) ? '' : ' plain'}${align ? ' align-' + align : ''}">${phrases.join('')}</div>`;
  }

  function renderPoem(p, romaji) {
    const w = WORDS[state.lang];
    let lines;
    if (romaji) {
      let left = hepburn(p.kimarijiReading).length;
      const verses = p.versesRomaji.map((v) => {
        const cut = Math.min(left, v.length);
        left -= cut;
        return `<span class="v">${cut ? `<span class="kh">${esc(v.slice(0, cut))}</span>` : ''}${esc(v.slice(cut))}</span>`;
      });
      lines = [verses.slice(0, 3).join(''), verses.slice(3).join('')].map((l) => `<div class="lines">${l}</div>`);
    } else {
      lines = [rubyLine(p.kamiRuby, p.kimariji.length), rubyLine(p.shimoRuby)];
    }
    const by = romaji ? esc(p.authorRomaji) : `<ruby>${esc(p.author)}<rt>${esc(p.authorKana)}</rt></ruby>`;
    return `<div class="poem${romaji ? ' roma' : ''}"><span class="tag2">${w.first}</span>${lines[0]}<span class="tag2 pink">${w.second}</span>${lines[1]}<div class="by">${by}</div></div>`;
  }

  /* Where the preview leaves out part of the real page: a marker, not content. */
  const omitted = (what, cls) => `<div class="omit ${cls}" role="note"><b>${WORDS[state.lang].omitted}</b><span>${what}</span></div>`;

  function renderShell() {
    const p = poemOf(state.n);
    const w = WORDS[state.lang];
    const romaji = script() === 'romaji';
    const accent = GROUP_COLORS[p?.color] ?? NEUTRAL_COLOR;
    const screen = $('#screen');
    screen.style.setProperty('--accent', accent);
    screen.style.setProperty('--em', mix(accent, EMPHASIS_TINT));
    screen.innerHTML =
      `<div class="sbar"><span>9:41</span><span>5G<i></i></span></div>` +
      `<div class="app"><div class="hdr"><div class="ttl">${w.title}</div><span class="iconbtn" aria-hidden="true">${ICON_BACK}</span></div>` +
      `<div class="body" id="scr">` +
      (p ? `<div class="refnote">${w.reference}</div>` +
        (p.kimariji ? `<div class="kmrow"><span class="big">${esc(romaji ? hepburn(p.kimarijiReading) : p.kimariji)}</span><span class="numtag">#${p.n}</span></div>` : '') +
        renderPoem(p, romaji) : `<div class="refnote">#${cardName(state.n)}</div>`) +
      omitted(w.omittedTop, 'omit-top') +
      `<h2 class="part" id="part">${w.part}${w.partSub ? `<small>${w.partSub}</small>` : ''}</h2>` +
      `<div class="md" id="md"></div>` +
      omitted(w.omittedEnd, 'omit-end') +
      `</div></div>`;
    $('#scriptSeg').querySelectorAll('button').forEach((b) => b.setAttribute('aria-pressed', String(b.dataset.s === script())));
    Editor.preview.renderMd();
  }

  return { renderShell, rubyLine };
})();
