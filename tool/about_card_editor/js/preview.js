/* The Markdown as the phone shows it: nodes from the parser become the
   blocks MarkdownBlocks and ProseBlocks lay out in the app. */
Editor.preview = (() => {
  const { BLOCK_TAGS, GAPS } = Editor.config;
  const { $, $$, esc } = Editor.util;
  const { hepburn } = Editor.Romaji;
  const { parse, textOf, unmark, KANA_OPEN, KANA_CLOSE, RUBY_OPEN, RUBY_SPLIT, RUBY_CLOSE } = Editor.CardMarkdown;
  const state = Editor.state;
  const { script } = state;
  const { rubyLine } = Editor.phone;
  const classes = Editor.classes;
  const ta = $('#ta');

  const kanaSpan = (kana) => `<span class="km">${esc(script() === 'romaji' ? hepburn(kana) : kana)}</span>`;
  const rubyHtml = (base, reading) => `<ruby>${esc(base)}<rt>${esc(reading)}</rt></ruby>`;
  /* Text from textOf(…, true): kana marks and rubies become their elements. */
  const markedHtml = (s) =>
    s.split(new RegExp(`(${KANA_OPEN}[^${KANA_CLOSE}]*${KANA_CLOSE}|${RUBY_OPEN}[^${RUBY_CLOSE}]*${RUBY_CLOSE})`)).map((part) => {
      if (part.startsWith(KANA_OPEN)) return kanaSpan(part.slice(1, -1));
      if (part.startsWith(RUBY_OPEN)) return rubyHtml(...part.slice(1, -1).split(RUBY_SPLIT));
      return esc(part);
    }).join('');

  /* A picture the writer chose by hand wins; otherwise a file of that name in the repo. */
  const repoUrl = (path) => (/^assets\/[A-Za-z0-9_\-./]+$/.test(path) && !path.includes('..') ? Editor.config.REPO_ROOT + path : null);
  const imageUrl = (path) => state.attached[path]?.url ?? repoUrl(path);
  const dropHtml = (path) => `<div class="drop" data-path="${esc(path)}" tabindex="0" role="button"><b>Picture preview</b><code>${esc(path)}</code><span>Drop an image here, or tap to choose one, to preview it.</span></div>`;
  /* A repo picture that does not load turns into the drop box. */
  const missing = (img) => { img.outerHTML = dropHtml(img.dataset.path); };

  function inline(nodes) {
    return nodes.map((c) => {
      if (c.t !== undefined) return esc(c.t.replaceAll('\n', ' '));
      if (c.kana !== undefined) return kanaSpan(c.kana);
      if (c.tag === 'strong') return `<strong>${inline(c.c)}</strong>`;
      if (c.tag === 'em') return `<em>${inline(c.c)}</em>`;
      if (c.tag === 'br') return '<br>';
      if (c.tag === 'span') return span(c);
      if (c.tag === 'ruby') return ruby(c);
      return inline(c.c || []);
    }).join('');
  }

  /* [words]{.red .bg-yellow}. Unknown class names make it plain text, as typed. */
  function span(e) {
    if (classes.unknownIn(e.classes, classes.COLOUR_CLASSES).length) return `[${inline(e.c)}]${esc(e.raw)}`;
    return classes.paint(inline(e.c), classes.colourOf(e.classes));
  }

  /* [漢字|かな], also with colour braces after it. Unknown class names leave the braces as typed. */
  function ruby(e) {
    const html = rubyHtml(textOf(e), e.reading);
    if (!e.classes) return html;
    if (classes.unknownIn(e.classes, classes.COLOUR_CLASSES).length) return html + esc(e.raw);
    return classes.paint(html, classes.colourOf(e.classes));
  }

  function markerHeading(e) {
    const parts = textOf(e, true).split(' | ');
    const title = parts[0].trim();
    const sub = parts.length > 1 ? parts[1].trim() : null;
    if (sub === null) return `<div class="mhw"><span class="mh">${markedHtml(title)}</span></div>`;
    return `<div class="mhw sub"><div class="one"><span class="mh">${markedHtml(title)}<span class="ms">  ${markedHtml(sub)}</span></span></div>` +
      `<div class="two"><span class="mh">${markedHtml(title)}</span><br><span class="mh s">${markedHtml(sub)}</span></div></div>`;
  }

  /* [top] is the gap above a floating picture; it has no wrapper to carry it. */
  function picture(img, top = 0) {
    const path = img.attrs.src;
    const caption = img.attrs.alt || '';
    const url = imageUrl(path);
    const visual = url
      ? `<img src="${url}" data-path="${esc(path)}" alt="${esc(unmark(caption))}" onerror="Editor.preview.missing(this)">`
      : dropHtml(path);
    const side = classes.floatSide(img.classes);
    const attrs = side ? ` class="pic float-${side}" style="margin-top:${top}px"` : ' class="pic"';
    return `<div${attrs}>${visual}${caption ? `<div class="cap">${markedHtml(caption)}</div>` : ''}</div>`;
  }

  function list(e, ordered) {
    const start = parseInt(e.attrs?.start ?? '1', 10) || 1;
    return (e.c || []).filter((li) => li.tag === 'li').map((li, i) => {
      const body = li.c || [];
      const flat = body.every((k) => k.t !== undefined || k.kana !== undefined || (k.tag && !BLOCK_TAGS.has(k.tag)));
      return `<div class="li" style="margin-top:${i ? GAPS.item : 0}px"><div class="mk">${ordered ? `<span class="num">${start + i}.</span>` : '<span class="dia"></span>'}</div>` +
        `<div class="lb">${flat ? inline(body) : body.map((k) => block(k)).join('')}</div></div>`;
    }).join('');
  }

  function fence(e) {
    const codeEl = (e.c || []).find((k) => k.tag);
    const text = (codeEl ? textOf(codeEl) : textOf(e)).trimEnd();
    if (codeEl?.attrs?.class !== 'language-verse') return `<div class="plainpre">${esc(text)}</div>`;
    return `<div class="verse">${Editor.verse.lines(text).map((l) => rubyLine(l.markup, 0, l.align)).join('')}</div>`;
  }

  function block(node) {
    if (node.t !== undefined) return `<div>${esc(node.t)}</div>`;
    if (node.kana !== undefined) return `<div>${kanaSpan(node.kana)}</div>`;
    const kids = node.c || [];
    switch (node.tag) {
      case 'h1': return markerHeading(node);
      case 'h2': case 'h3': case 'h4': return `<div class="hd ${node.tag}">${inline(kids)}</div>`;
      case 'p': return kids.length === 1 && kids[0].tag === 'img' ? picture(kids[0]) : `<div>${inline(kids)}</div>`;
      case 'ul': return list(node, false);
      case 'ol': return list(node, true);
      case 'blockquote':
        return `<div class="quote">${kids.map((k, i) => `<div style="margin-top:${i ? GAPS.quote : 0}px">${k.tag === 'p' ? `<div class="strongtext">${inline(k.c || [])}</div>` : block(k)}</div>`).join('')}</div>`;
      case 'pre': return fence(node);
      case 'div': return box(node);
      case 'hr': return '<div class="rule"></div>';
      default: return `<div>${esc(textOf(node))}</div>`;
    }
  }

  /* ::: {.bg-yellow} ... :::  Unknown class names make the ::: lines plain text, as typed. */
  function box(e) {
    if (classes.unknownIn(e.classes, classes.BOX_CLASSES).length) {
      return blocks([{ tag: 'p', c: [{ t: e.raw }] }, ...e.c, { tag: 'p', c: [{ t: ':::' }] }]);
    }
    const { text, background } = classes.colourOf(e.classes);
    const style = (text ? `--tc:${text};` : '') + (background ? `background-color:${background}` : '');
    const aligned = e.classes.filter((c) => classes.kindOf(c) === 'align').map((c) => 'align-' + c);
    const cls = [background && 'tbox', text && 'tc', ...aligned].filter(Boolean).join(' ');
    return `<div class="${cls}" style="${style}">${blocks(e.c)}</div>`;
  }

  const isFloat = (node) => node.tag === 'p' && node.c.length === 1 && node.c[0].tag === 'img' && !!classes.floatSide(node.c[0].classes);
  const gapBefore = (node, prev) => (prev.tag === 'h1' ? 0 : GAPS[node.tag] ?? GAPS.block);

  /* Each block sits in a wrapper that carries its gap. A floating picture has
     no wrapper, and the block after it takes the same gap, so they start level. */
  function blocks(nodes) {
    let top = 0;
    return nodes.map((node, i) => {
      if (i && !isFloat(nodes[i - 1])) top = gapBefore(node, nodes[i - 1]);
      return isFloat(node) ? picture(node.c[0], top) : `<div style="margin-top:${top}px">${block(node)}</div>`;
    }).join('');
  }

  function renderMd() {
    const nodes = parse(ta.value);
    $('#md').innerHTML = blocks(nodes);
    if (!nodes.length) $('#md').innerHTML = '<div class="emptymd">Nothing here yet. Start typing on the right.</div>';
    fitHeadings();
    Editor.warnings.renderChecks(nodes);
    Editor.pictures.renderPictures(nodes);
    Editor.editing.renderHighlight();
  }

  /* A marker heading keeps its other-language word beside it when both fit
     on one line (with the marker's reach); otherwise the word takes a line. */
  function fitHeadings() {
    $$('.mhw.sub').forEach((w) => {
      w.classList.remove('split');
      if ($('.one .mh', w).offsetWidth + 4 > w.clientWidth) w.classList.add('split');
    });
  }

  return { renderMd, fitHeadings, imageUrl, repoUrl, missing };
})();
