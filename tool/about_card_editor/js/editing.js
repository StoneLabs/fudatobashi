/* The text box: the yellow marks behind the braces, and the toolbar that edits the text. */
Editor.editing = (() => {
  const { $, esc } = Editor.util;
  const ta = $('#ta');
  const hl = $('#hl');

  function renderHighlight() {
    let fenced = false;
    hl.innerHTML = ta.value.split('\n').map((line) => {
      if (/^ {0,3}(`{3,}|~{3,})/.test(line)) { fenced = !fenced; return esc(line); }
      if (fenced) return esc(line);
      return esc(line).replace(/\\[\s\S]|\{\s*\.[^{}\n]*\}|\{[^{}\n]+\}/g, (m) => {
        if (m[0] === '\\') return m;
        return `<mark${/^\{\s*\./.test(m) ? ' class="attr"' : ''}>${m}</mark>`;
      });
    }).join('\n') + '​';
    hl.scrollTop = ta.scrollTop;
  }


  /* Inserting through execCommand keeps the browser's own undo working. */
  function put(from, to, text, selectFrom = from, selectTo = from + text.length) {
    ta.focus();
    ta.setSelectionRange(from, to);
    if (!document.execCommand('insertText', false, text)) {
      ta.setRangeText(text, from, to, 'end');
      ta.dispatchEvent(new Event('input'));
    }
    ta.setSelectionRange(selectFrom, selectTo);
  }
  const lineSpan = () => {
    const v = ta.value;
    const from = v.lastIndexOf('\n', ta.selectionStart - 1) + 1;
    let to = v.indexOf('\n', ta.selectionEnd);
    if (to < 0) to = v.length;
    return [from, to];
  };
  const mapLines = (fn) => {
    const [from, to] = lineSpan();
    put(from, to, ta.value.slice(from, to).split('\n').map(fn).join('\n'), from, undefined);
  };
  function wrapSelection(open, close, sample) {
    const a = ta.selectionStart;
    const b = ta.selectionEnd;
    const chosen = ta.value.slice(a, b) || sample;
    put(a, b, open + chosen + close, a + open.length, a + open.length + chosen.length);
  }
  /* A block of its own: blank lines around it, as the app needs. */
  function insertBlock(text, selectText) {
    const [from, to] = lineSpan();
    const onBlank = ta.value.slice(from, to).trim() === '';
    const lead = onBlank ? '' : '\n\n';
    const start = (onBlank ? from : to) + lead.length;
    const picked = selectText ? start + text.indexOf(selectText) : start + text.length;
    put(onBlank ? from : to, to, lead + text + '\n\n', picked, selectText ? picked + selectText.length : picked);
  }
  /* [漢字|かな]: the selection becomes the kanji, and the reading is selected to type over. */
  function rubyAround() {
    const from = ta.selectionStart;
    const to = ta.selectionEnd;
    const base = ta.value.slice(from, to) || '漢字';
    const reading = 'かな';
    put(from, to, `[${base}|${reading}]`, from + base.length + 2, from + base.length + 2 + reading.length);
  }
  const FORMATS = {
    h1: () => mapLines((l) => (l.startsWith('# ') ? l.slice(2) : '# ' + l.replace(/^#{1,6}\s+/, ''))),
    h2: () => mapLines((l) => (l.startsWith('## ') ? l.slice(3) : '## ' + l.replace(/^#{1,6}\s+/, ''))),
    h3: () => mapLines((l) => (l.startsWith('### ') ? l.slice(4) : '### ' + l.replace(/^#{1,6}\s+/, ''))),
    bold: () => wrapSelection('**', '**', 'bold text'),
    em: () => wrapSelection('*', '*', 'highlighted text'),
    kana: () => wrapSelection('{', '}', 'あきの'),
    ul: () => mapLines((l) => (l.startsWith('- ') ? l.slice(2) : '- ' + l)),
    ol: () => { let i = 0; mapLines((l) => (/^\d+\.\s/.test(l) ? l.replace(/^\d+\.\s/, '') : `${++i}. ${l}`)); },
    quote: () => mapLines((l) => (l.startsWith('> ') ? l.slice(2) : '> ' + l)),
    alignRight: () => Editor.colours.alignRight(),
    ruby: () => rubyAround(),
    verse: () => insertBlock('```verse\n[秋|あき]の[田|た]の　かりほの[庵|いほ]の\n```', '[秋|あき]の[田|た]の　かりほの[庵|いほ]の'),
    rule: () => insertBlock('---'),
    picture: () => insertBlock('![caption](assets/pictures/name.png)', 'caption'),
    pictureLeft: () => insertBlock('![caption](assets/pictures/name.png){.left}', 'caption'),
    pictureRight: () => insertBlock('![caption](assets/pictures/name.png){.right}', 'caption'),
  };

  function wire() {
    ta.addEventListener('scroll', () => { hl.scrollTop = ta.scrollTop; });
    $('#toolbar').addEventListener('click', (e) => { const b = e.target.closest('button'); if (b) FORMATS[b.dataset.f](); });
  }

  return { renderHighlight, put, wire };
})();
