/* One line of a verse block as runs of text: [秋|あき] is a run with a reading
   and [words]{.red} gives the runs inside it a colour (spans may nest). */
Editor.verse = (() => {
  const classes = Editor.classes;

  const RUBY_AT = /\[([^|[\]]+)\|([^\]]+)\]/y;
  const BRACES_AT = /\{\s*(\.[^\s{}]+(?:\s+\.[^\s{}]+)*)\s*\}/y;
  const ORPHAN_AT = /\{\s*\.[^{}]*\}/y;

  const matchAt = (re, text, at) => { re.lastIndex = at; return re.exec(text); };

  /* The index of the ] that closes the [ at [open], or -1. */
  function closingBracket(text, open) {
    let depth = 0;
    for (let i = open; i < text.length; i++) {
      if (text[i] === '[') depth++;
      else if (text[i] === ']' && --depth === 0) return i;
    }
    return -1;
  }

  const withStyle = (run, style) => (style.text || style.background ? { ...run, style } : run);

  /* [notes] collects what the checks need: spans and braces that follow nothing.
     Braces with a class name that does not exist stay in the text, as typed. */
  function runs(markup, notes = [], inherited = {}) {
    const out = [];
    let text = '';
    const flush = () => {
      if (text) out.push(withStyle({ base: text }, inherited));
      text = '';
    };
    /* The braces after a span or a ruby: their classes, noted, and the style they give. */
    const bracesStyle = (braces) => {
      const names = braces[1].split(/\s+/).map((c) => c.slice(1));
      notes.push({ kind: 'span', classes: names, raw: braces[0] });
      if (classes.unknownIn(names, classes.COLOUR_CLASSES).length) return null;
      const own = classes.colourOf(names);
      return { text: own.text ?? inherited.text, background: own.background ?? inherited.background };
    };

    for (let at = 0; at < markup.length;) {
      const ruby = markup[at] === '[' && matchAt(RUBY_AT, markup, at);
      if (ruby) {
        flush();
        const braces = matchAt(BRACES_AT, markup, at + ruby[0].length);
        const style = braces && bracesStyle(braces);
        out.push(withStyle({ base: ruby[1], reading: ruby[2] }, style ?? inherited));
        at += ruby[0].length;
        if (braces) {
          if (!style) out.push(withStyle({ base: braces[0] }, inherited));
          at += braces[0].length;
        }
        continue;
      }
      const end = markup[at] === '[' ? closingBracket(markup, at) : -1;
      const braces = end > 0 && matchAt(BRACES_AT, markup, end + 1);
      if (braces) {
        flush();
        const style = bracesStyle(braces);
        const inner = markup.slice(at + 1, end);
        if (style) out.push(...runs(inner, notes, style));
        else out.push(withStyle({ base: '[' }, inherited), ...runs(inner, notes, inherited), withStyle({ base: ']' + braces[0] }, inherited));
        at = end + 1 + braces[0].length;
        continue;
      }
      const orphan = markup[at] === '{' && matchAt(ORPHAN_AT, markup, at);
      if (orphan) notes.push({ kind: 'orphan', raw: orphan[0] });
      text += markup[at++];
    }
    flush();
    return out;
  }

  return { runs };
})();
