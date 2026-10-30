/* The check list under the editor: what will not show up in the app as written. */
Editor.warnings = (() => {
  const { FLOAT } = Editor.config;
  const { $, esc } = Editor.util;
  const { textOf } = Editor.CardMarkdown;
  const classes = Editor.classes;

  const orphanMessage = (raw) => `${raw} does nothing here. Braces like {.red} must come straight after a picture's closing bracket ")" or after a [word] span.`;

  /* The spans and stray braces in the lines of a verse block. */
  function verseNotes(pre) {
    const code = (pre.c || []).find((k) => k.tag);
    if (code?.attrs?.class !== 'language-verse') return [];
    const notes = [];
    Editor.verse.lines(textOf(code), notes).forEach((line) => { if (!line.literal) Editor.verse.runs(line.markup, notes); });
    return notes;
  }

  function verseMessage(note, out) {
    if (note.kind === 'orphan') out.add(orphanMessage(note.raw));
    else if (note.kind === 'span') checkClasses(note, out);
    else if (note.kind === 'unclosed') out.add('A ::: block in a verse is never closed. End it with a line that holds only :::.');
    else if (note.kind === 'stray') out.add('A ::: line in a verse closes nothing. A block starts with ::: {.right}.');
    else out.add(`Only ${classes.listed(Editor.config.ALIGN_CLASSES)} works in a ::: block inside a verse, not ${note.raw}. For colours, use [words]{.red} in a line.`);
  }

  /* The class names in the braces of a [words]{...} span or a ::: {...} box. */
  function checkClasses(x, out, allowed = classes.COLOUR_CLASSES) {
    classes.unknownIn(x.classes, allowed).forEach((name) =>
      out.add(`Unknown class .${name} in ${x.raw}. Use one of ${classes.listed(allowed)}.`));
    if (classes.repeats(x.classes)) out.add(`${x.raw} has two text colours or two backgrounds. Only the last of each is used.`);
  }

  function renderChecks(nodes, templateError) {
    const out = new Set();
    if (templateError) out.add(`The template does not work, so the preview shows the text as written: ${templateError}`);
    if (!nodes.length) out.add('The file is empty.');
    else if (nodes[0].tag !== 'h1') out.add('Start the file with a # heading, for example  # 解説 | Explanation');
    const tobiMarks = new Set();
    const walk = (list) => list.forEach((x) => {
      const tobi = Editor.tobi.line(x);
      if (tobi) tobiMarks.add(tobi.mark);
      if (tobi && !tobi.known) out.add(`Tobi has no pose called ${tobi.pose}, so the app shows him standing. Use one of ${Editor.config.TOBI_POSES.join(', ')}.`);
      if (x.tag === 'p' && x.c.length > 1 && x.c.some((k) => k.tag === 'img')) out.add('A picture only shows when it is alone on its line, with a blank line above and below. Only a picture with {.left} or {.right} may have text on the very next line. Otherwise it is dropped.');
      if (x.tag === 'img' && x.classes) {
        classes.unknownIn(x.classes, FLOAT.sides).forEach((name) => out.add(`A picture only takes ${FLOAT.sides.map((s) => '.' + s).join(' or ')}, not .${name}.`));
        if (FLOAT.sides.every((side) => x.classes.includes(side))) out.add('A picture cannot be both .left and .right.');
      }
      if ((x.tag === 'span' || x.tag === 'ruby') && x.classes) checkClasses(x, out);
      if (x.tag === 'div') checkClasses(x, out, classes.BOX_CLASSES);
      if (x.tag === 'orphan' && !tobiMarks.has(x)) out.add(orphanMessage(textOf(x)));
      if (x.tag === 'pre') verseNotes(x).forEach((note) => verseMessage(note, out));
      if (x.unclosed) out.add('A ::: box is never closed. End it with a line that holds only :::.');
      else if (x.tag === 'p' && /^[ \t]*:::/m.test(textOf(x))) out.add('This ::: line is not understood. Open a box with ::: {.bg-yellow} and close it with a line that holds only :::. A box cannot sit inside another box; only a ::: {.right} block can go inside a coloured box.');
      if (x.tag === 'img' && !/^assets\/[A-Za-z0-9_\-./]+$/.test(x.attrs.src)) out.add(`The picture path "${x.attrs.src}" should start with assets/ and use only letters, digits, - _ . and /.`);
      if (x.tag === 'li' && (x.c || []).some((k) => k.tag === 'ul' || k.tag === 'ol')) out.add('Nested lists do not display well. Keep each list flat.');
      if (x.tag === 'a') out.add('Links are shown as plain text.');
      if (x.tag === 'h5' || x.tag === 'h6') out.add('##### and ###### show as plain text. Use # to ####.');
      if (x.kana !== undefined && /[^ぁ-ゖ]/.test(x.kana)) out.add(`{${x.kana}} should hold only hiragana. Other characters stay as they are in Romaji.`);
      if (x.c) walk(x.c);
    });
    walk(nodes);
    const box = $('#checks');
    box.hidden = false;
    box.className = out.size ? 'checks warn' : 'checks ok';
    box.innerHTML = out.size ? [...out].map((m) => `<li>${esc(m)}</li>`).join('') : '<li>No problems found.</li>';
  }

  return { renderChecks };
})();
