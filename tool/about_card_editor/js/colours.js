/* The colour buttons under the toolbar. They wrap the selected words in
   [words]{.red}, or the selected lines in a ::: {.bg-yellow} box, or in a verse
   block each selected line in its own span. Choosing the same colour again
   takes it off. */
Editor.colours = (() => {
  const { PALETTE } = Editor.config;
  const { $, esc } = Editor.util;
  const { kindOf } = Editor.classes;
  const ta = $('#ta');

  const BRACES_ONLY = /^\{\s*((?:\.[^\s{}]+\s*)+)\}$/;
  const BRACES_AT = /^\]\{\s*((?:\.[^\s{}]+\s*)+)\}/;
  const BOX_OPEN = /^ {0,3}:{3,}[ \t]*\{\s*((?:\.[^\s{}]+\s*)+)\}[ \t]*$/;
  const BOX_CLOSE = /^ {0,3}:{3,}[ \t]*$/;
  const FENCE = /^ {0,3}(?:`{3,}|~{3,})\s*(\S*)/;
  const RUBY_WORDS = /^[^|[\]]+\|[^\]]+$/;
  const SAMPLE_WORDS = 'coloured words';

  const namesOf = (dotted) => dotted.trim().split(/\s+/).map((c) => c.slice(1));
  const bracesOf = (names) => `{${names.map((c) => '.' + c).join(' ')}}`;
  const className = (kind, name) => (kind === 'background' ? PALETTE.backgroundPrefix + name : name);

  /* [names] with [name] added, or removed when it is already there. One colour per kind. */
  function toggled(names, name) {
    if (names.includes(name)) return names.filter((c) => c !== name);
    return [...names.filter((c) => kindOf(c) !== kindOf(name)), name];
  }

  /* [words] in a span with [names], or the plain words when no class is left.
     A verse reading, [漢字|かな], keeps its own brackets. */
  function spanned(words, names) {
    if (names.length) return `[${words}]${bracesOf(names)}`;
    return RUBY_WORDS.test(words) ? `[${words}]` : words;
  }

  /* [text] as one span: its words and class names, or null. */
  function parseSpan(text) {
    if (text[0] !== '[') return null;
    let depth = 0;
    for (let i = 0; i < text.length; i++) {
      if (text[i] === '[') depth++;
      else if (text[i] === ']' && --depth === 0) {
        const braces = BRACES_ONLY.exec(text.slice(i + 1));
        return braces ? { words: text.slice(1, i), names: namesOf(braces[1]) } : null;
      }
    }
    return null;
  }

  /* The span the selection is in: the whole [words]{.x}, or just its words,
     or the words of a verse reading with no braces yet. */
  function spanAround(a, b) {
    const v = ta.value;
    const whole = parseSpan(v.slice(a, b));
    if (whole) return { start: a, end: b, ...whole };
    const words = v.slice(a, b);
    const tail = v[a - 1] === '[' && BRACES_AT.exec(v.slice(b));
    if (tail) return { start: a - 1, end: b + tail[0].length, words, names: namesOf(tail[1]) };
    if (v[a - 1] === '[' && v[b] === ']' && RUBY_WORDS.test(words)) return { start: a - 1, end: b + 1, words, names: [] };
    return null;
  }

  /* The words stay selected, so choosing another colour right away changes the same span. */
  function applyToWords(name) {
    const a = ta.selectionStart;
    const b = ta.selectionEnd;
    const span = spanAround(a, b) ?? { start: a, end: b, words: ta.value.slice(a, b) || SAMPLE_WORDS, names: [] };
    const names = toggled(span.names, name);
    const text = spanned(span.words, names);
    const from = span.start + (names.length || RUBY_WORDS.test(span.words) ? 1 : 0);
    Editor.editing.put(span.start, span.end, text, from, from + span.words.length);
  }

  /* Whole lines: the selection starts at a line start and ends at a line end. */
  function selectedLines() {
    const v = ta.value;
    const from = ta.selectionStart;
    const to = v[ta.selectionEnd - 1] === '\n' ? ta.selectionEnd - 1 : ta.selectionEnd;
    const whole = to > from && v.slice(from, to).trim() !== '' && (from === 0 || v[from - 1] === '\n') && (to === v.length || v[to] === '\n');
    return whole ? { from, to } : null;
  }

  /* The opening line of the code block the position is in, as the language word, or null. */
  function fenceAt(pos) {
    let open = null;
    ta.value.slice(0, pos).split('\n').slice(0, -1).forEach((line) => {
      const m = FENCE.exec(line);
      if (m) open = open === null ? m[1] : null;
    });
    return open;
  }

  const lineAt = (v, index) => {
    const end = v.indexOf('\n', index);
    return v.slice(v.lastIndexOf('\n', index - 1) + 1, end < 0 ? v.length : end);
  };

  /* In a verse block a box would only be text, so each line gets a span of its own. */
  function applyToVerseLines({ from, to }, name) {
    const lines = ta.value.slice(from, to).split('\n').map((line) => {
      if (!line.trim()) return line;
      const span = parseSpan(line);
      return spanned(span ? span.words : line, toggled(span ? span.names : [], name));
    });
    const text = lines.join('\n');
    Editor.editing.put(from, to, text, from, from + text.length);
  }

  function applyToBox({ from, to }, name) {
    const v = ta.value;
    const lines = v.slice(from, to).split('\n');
    const open = BOX_OPEN.exec(lines[0]);
    if (open && lines.length > 1 && BOX_CLOSE.test(lines[lines.length - 1])) {
      const names = toggled(namesOf(open[1]), name);
      const inner = lines.slice(1, -1).join('\n');
      const text = names.length ? `::: ${bracesOf(names)}\n${inner}\n:::` : inner;
      return Editor.editing.put(from, to, text, from, from + text.length);
    }
    const before = from > 0 && lineAt(v, from - 1).trim() !== '' ? '\n' : '';
    const after = to < v.length && lineAt(v, to + 1).trim() !== '' ? '\n' : '';
    const text = `::: ${bracesOf([name])}\n${lines.join('\n')}\n:::`;
    Editor.editing.put(from, to, before + text + after, from + before.length, from + before.length + text.length);
  }

  function apply(name) {
    const lines = selectedLines();
    if (!lines) return applyToWords(name);
    if (fenceAt(lines.from) === 'verse') return applyToVerseLines(lines, name);
    return applyToBox(lines, name);
  }

  const swatch = (kind, { name, hex, token }) => {
    const shown = kind === 'text' ? `color:${hex}` : `background:${hex}`;
    const what = kind === 'text' ? 'Text colour' : 'Background';
    return `<button type="button" class="sw" data-class="${esc(className(kind, name))}" title="${what} ${name} (${hex}, ${esc(token)}). Click again to take it off." style="${shown}">A</button>`;
  };

  function wire() {
    $('#textColours').innerHTML = PALETTE.text.map((c) => swatch('text', c)).join('');
    $('#bgColours').innerHTML = PALETTE.background.map((c) => swatch('background', c)).join('');
    $('#colours').addEventListener('click', (e) => {
      const b = e.target.closest('button[data-class]');
      if (b) apply(b.dataset.class);
    });
    document.querySelectorAll('[data-palette]').forEach((el) => {
      const names = el.dataset.palette === 'text' ? PALETTE.text.map((c) => c.name) : PALETTE.background.map((c) => PALETTE.backgroundPrefix + c.name);
      el.textContent = names.map((n) => '.' + n).join(' ');
    });
  }

  return { wire };
})();
