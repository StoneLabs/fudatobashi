/* The explanation editor: the phone preview, the editor and the files. */
(() => {
  const DATA = EDITOR_DATA;
  const { parse, textOf, KANA_OPEN, KANA_CLOSE } = CardMarkdown;
  const { hepburn } = Romaji;
  const $ = (s, r = document) => r.querySelector(s);
  const $$ = (s, r = document) => [...r.querySelectorAll(s)];
  const esc = (s) => s.replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));
  const pad = (n) => String(n).padStart(3, '0');

  /* The app's palette (lib/config/design/core.dart) and the colour groups. */
  const GROUP_COLORS = { 青: '#2B9BFF', 桃: '#FF3D7F', 黄: '#FFD83A', 緑: '#8ED462', 橙: '#FF9A2E' };
  const EMPHASIS_TINT = 0.45;
  const BLOCK_TAGS = new Set(['h1', 'h2', 'h3', 'h4', 'p', 'ul', 'ol', 'blockquote', 'pre', 'hr']);
  const GAPS = { h1: 26, h2: 22, h3: 16, h4: 16, block: 10, item: 6, quote: 10 };
  const FOLDERS = { en: 'assets/l10n/en_card_explanations/', ja: 'assets/l10n/ja_card_explanations/' };
  const WORDS = {
    en: {
      title: 'About this card', first: 'FIRST HALF', second: 'SECOND HALF', part: 'About the poem', partSub: '',
      reference: 'For reference only: this card is not part of your file',
      omitted: '[ … content omitted here … ]',
      omittedTop: 'The app shows the taking and reading card, the kimariji, the poem, the card facts and the sound ladder here.',
      omittedEnd: 'The app shows “My record on this card” and the previous and next card buttons here.',
    },
    ja: {
      title: 'この札について', first: '上の句', second: '下の句', part: 'この歌について', partSub: 'About the poem',
      reference: '参考：この札はファイルには入りません',
      omitted: '［…ここは省略…］',
      omittedTop: 'アプリではここに、取り札と読み札、決まり字、歌、札のデータ、最初の音と似た札が入ります。',
      omittedEnd: 'アプリではここに「この札の成績」と、前の札・次の札のボタンが入ります。',
    },
  };
  const ICON_BACK = '<svg class="ic" viewBox="0 0 24 24"><path d="M15 5l-7 7 7 7"/></svg>';

  const mix = (hex, t) => {
    const c = [1, 3, 5].map((i) => parseInt(hex.slice(i, i + 2), 16));
    return '#' + c.map((v) => Math.round(255 + (v - 255) * t).toString(16).padStart(2, '0')).join('');
  };

  /* ---- what is saved in this browser ---- */

  const KEY = 'fudatobashi.explanationEditor.v1';
  let store = { drafts: {}, last: { lang: 'en', n: 1 }, script: {} };
  try { Object.assign(store, JSON.parse(localStorage.getItem(KEY) || '{}')); } catch (e) { /* no storage: keep in memory */ }
  let saveTimer = 0;
  const save = () => { try { localStorage.setItem(KEY, JSON.stringify(store)); } catch (e) { /* ignore */ } };
  const saveSoon = () => { clearTimeout(saveTimer); saveTimer = setTimeout(save, 250); };

  let lang = store.last.lang === 'ja' ? 'ja' : 'en';
  let n = Math.min(100, Math.max(1, +store.last.n || 1));
  const attached = {}; // picture path -> { file, url }

  const key = (l, i) => `${l}/${i}`;
  const original = (l, i) => DATA.expl[l][i] ?? '';
  const draftOf = (l, i) => store.drafts[key(l, i)];
  const textOfCard = (l, i) => draftOf(l, i) ?? original(l, i);
  const isEdited = (l, i) => draftOf(l, i) !== undefined && draftOf(l, i) !== original(l, i);
  const editedList = () => ['en', 'ja'].flatMap((l) => DATA.poems.filter((p) => isEdited(l, p.n)).map((p) => ({ lang: l, n: p.n })));
  const script = () => store.script[lang] ?? (lang === 'en' ? 'romaji' : 'kana');

  const ta = $('#ta');
  const hl = $('#hl');

  /* ---- the phone ---- */

  const kanaSpan = (kana) => `<span class="km">${esc(script() === 'romaji' ? hepburn(kana) : kana)}</span>`;
  const markedHtml = (s) =>
    s.split(new RegExp(`(${KANA_OPEN}[^${KANA_CLOSE}]*${KANA_CLOSE})`)).map((part) =>
      part.startsWith(KANA_OPEN) ? kanaSpan(part.slice(1, -1)) : esc(part)).join('');

  const RUBY = /\[([^|\]]+)\|([^\]]+)\]/g;
  const rubyRuns = (phrase) => {
    const runs = [];
    let at = 0;
    for (const m of phrase.matchAll(RUBY)) {
      if (m.index > at) runs.push({ base: phrase.slice(at, m.index) });
      runs.push({ base: m[1], reading: m[2] });
      at = m.index + m[0].length;
    }
    if (at < phrase.length) runs.push({ base: phrase.slice(at) });
    return runs;
  };
  const runHtml = (r, marked) => {
    const base = r.reading ? `<ruby>${esc(r.base)}<rt>${esc(r.reading)}</rt></ruby>` : esc(r.base);
    return marked ? `<span class="kh">${base}</span>` : base;
  };
  /* One line of furigana markup: phrases end at a full-width space. [kimariji]
     is how many kana at the start are the kimariji (shown in pink). */
  function rubyLine(markup, kimariji = 0) {
    let left = kimariji;
    const phrases = markup.split('　').filter(Boolean).map((phrase) => {
      const html = rubyRuns(phrase).flatMap((r) => {
        if (left <= 0) return [runHtml(r)];
        if (r.reading || r.base.length <= left) { left -= (r.reading ?? r.base).length; return [runHtml(r, true)]; }
        const cut = left;
        left = 0;
        return [runHtml({ base: r.base.slice(0, cut) }, true), runHtml({ base: r.base.slice(cut) })];
      }).join('');
      return `<span class="ph">${html}</span>`;
    });
    return `<div class="vl${/\[[^|\]]+\|/.test(markup) ? '' : ' plain'}">${phrases.join('')}</div>`;
  }

  function renderPoem(p, romaji) {
    const w = WORDS[lang];
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
  const omitted = (what, cls) => `<div class="omit ${cls}" role="note"><b>${WORDS[lang].omitted}</b><span>${what}</span></div>`;

  function renderShell() {
    const p = DATA.poems[n - 1];
    const w = WORDS[lang];
    const romaji = script() === 'romaji';
    const accent = GROUP_COLORS[p.color] ?? GROUP_COLORS['黄'];
    const screen = $('#screen');
    screen.style.setProperty('--accent', accent);
    screen.style.setProperty('--em', mix(accent, EMPHASIS_TINT));
    screen.innerHTML =
      `<div class="sbar"><span>9:41</span><span>5G<i></i></span></div>` +
      `<div class="app"><div class="hdr"><div class="ttl">${w.title}</div><span class="iconbtn" aria-hidden="true">${ICON_BACK}</span></div>` +
      `<div class="body" id="scr">` +
      `<div class="refnote">${w.reference}</div>` +
      `<div class="kmrow"><span class="big">${esc(romaji ? hepburn(p.kimarijiReading) : p.kimariji)}</span><span class="numtag">#${p.n}</span></div>` +
      renderPoem(p, romaji) +
      omitted(w.omittedTop, 'omit-top') +
      `<h2 class="part" id="part">${w.part}${w.partSub ? `<small>${w.partSub}</small>` : ''}</h2>` +
      `<div class="md" id="md"></div>` +
      omitted(w.omittedEnd, 'omit-end') +
      `</div></div>`;
    $('#scriptSeg').querySelectorAll('button').forEach((b) => b.setAttribute('aria-pressed', String(b.dataset.s === script())));
    renderMd();
  }

  /* ---- the Markdown, as MarkdownBlocks and ProseBlocks lay it out ---- */

  const imageUrl = (path) => attached[path]?.url ?? DATA.images[path] ?? null;

  function inline(nodes) {
    return nodes.map((c) => {
      if (c.t !== undefined) return esc(c.t.replaceAll('\n', ' '));
      if (c.kana !== undefined) return kanaSpan(c.kana);
      if (c.tag === 'strong') return `<strong>${inline(c.c)}</strong>`;
      if (c.tag === 'em') return `<em>${inline(c.c)}</em>`;
      if (c.tag === 'br') return '<br>';
      return inline(c.c || []);
    }).join('');
  }

  function markerHeading(e) {
    const parts = textOf(e, true).split(' | ');
    const title = parts[0].trim();
    const sub = parts.length > 1 ? parts[1].trim() : null;
    if (sub === null) return `<div class="mhw"><span class="mh">${markedHtml(title)}</span></div>`;
    return `<div class="mhw sub"><div class="one"><span class="mh">${markedHtml(title)}<span class="ms">  ${markedHtml(sub)}</span></span></div>` +
      `<div class="two"><span class="mh">${markedHtml(title)}</span><br><span class="mh s">${markedHtml(sub)}</span></div></div>`;
  }

  function picture(img) {
    const path = img.attrs.src;
    const caption = img.attrs.alt || '';
    const url = imageUrl(path);
    const visual = url
      ? `<img src="${url}" alt="${esc(caption.replace(/[]/g, ''))}">`
      : `<div class="drop" data-path="${esc(path)}" tabindex="0" role="button"><b>Picture not in the app yet</b><code>${esc(path)}</code><span>Drop an image here, or tap to choose one, to preview it.</span></div>`;
    return `<div class="pic">${visual}${caption ? `<div class="cap">${markedHtml(caption)}</div>` : ''}</div>`;
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
    return `<div class="verse">${text.split('\n').map((l) => rubyLine(l)).join('')}</div>`;
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
      case 'hr': return '<div class="rule"></div>';
      default: return `<div>${esc(textOf(node))}</div>`;
    }
  }

  const gapBefore = (node, prev) => (prev.tag === 'h1' ? 0 : GAPS[node.tag] ?? GAPS.block);

  function renderMd() {
    const nodes = parse(ta.value);
    $('#md').innerHTML = nodes.map((node, i) =>
      `<div style="margin-top:${i ? gapBefore(node, nodes[i - 1]) : 0}px">${block(node)}</div>`).join('');
    if (!nodes.length) $('#md').innerHTML = '<div class="emptymd">Nothing here yet. Start typing on the right.</div>';
    fitHeadings();
    renderChecks(nodes);
    renderPictures(nodes);
    renderHighlight();
  }

  /* A marker heading keeps its other-language word beside it when both fit
     on one line (with the marker's reach); otherwise the word takes a line. */
  function fitHeadings() {
    $$('.mhw.sub').forEach((w) => {
      w.classList.remove('split');
      if ($('.one .mh', w).offsetWidth + 4 > w.clientWidth) w.classList.add('split');
    });
  }

  /* ---- checks ---- */

  function renderChecks(nodes) {
    const out = new Set();
    if (!nodes.length) out.add('The file is empty.');
    else if (nodes[0].tag !== 'h1') out.add('Start the file with a # heading, for example  # 解説 | Explanation');
    const walk = (list) => list.forEach((x) => {
      if (x.tag === 'p' && x.c.length > 1 && x.c.some((k) => k.tag === 'img')) out.add('A picture only shows when it is alone on its line, with a blank line above and below. Otherwise it is dropped.');
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

  /* ---- pictures ---- */

  const picturesIn = (nodes) => {
    const found = [];
    const walk = (list) => list.forEach((x) => {
      if (x.tag === 'img' && !found.some((f) => f.path === x.attrs.src)) found.push({ path: x.attrs.src, caption: textOf({ t: x.attrs.alt || '' }).replace(/[]/g, '') });
      if (x.c) walk(x.c);
    });
    walk(nodes);
    return found;
  };

  function renderPictures(nodes) {
    const items = picturesIn(nodes);
    const box = $('#pictures');
    $('#picturesWrap').hidden = !items.length;
    box.innerHTML = items.map(({ path }) => {
      const url = imageUrl(path);
      const status = attached[path] ? 'Preview only: send this image file to the developer.'
        : DATA.images[path] ? 'Already in the app.' : 'Not in the app yet. Choose a file to preview it, then send it to the developer.';
      return `<li class="picrow" data-path="${esc(path)}"><span class="thumb">${url ? `<img src="${url}" alt="">` : '?'}</span>` +
        `<span class="pinfo"><code>${esc(path)}</code><small>${status}</small></span>` +
        `<button type="button" class="btn small" data-act="pick" data-path="${esc(path)}">Choose image</button>` +
        (attached[path] ? `<button type="button" class="btn small" data-act="unpick" data-path="${esc(path)}">Remove</button>` : '') + '</li>';
    }).join('');
  }

  function attach(path, file) {
    if (!file || !file.type.startsWith('image/')) return;
    if (attached[path]) URL.revokeObjectURL(attached[path].url);
    attached[path] = { file, url: URL.createObjectURL(file) };
    renderMd();
  }

  /* ---- the editor ---- */

  function renderHighlight() {
    let fenced = false;
    hl.innerHTML = ta.value.split('\n').map((line) => {
      if (/^ {0,3}(`{3,}|~{3,})/.test(line)) { fenced = !fenced; return esc(line); }
      if (fenced) return esc(line);
      return esc(line).replace(/\\[\s\S]|\{[^{}\n]+\}/g, (m) => (m[0] === '\\' ? m : `<mark>${m}</mark>`));
    }).join('\n') + '​';
    hl.scrollTop = ta.scrollTop;
  }

  function refreshControls() {
    const sel = $('#card');
    DATA.poems.forEach((p, i) => { sel.options[i].textContent = `${p.n} · ${p.kimariji}${isEdited(lang, p.n) ? '  ✎ edited' : ''}`; });
    sel.value = String(n);
    const count = (l) => DATA.poems.filter((p) => isEdited(l, p.n)).length;
    $('#lang-en').textContent = `English${count('en') ? ` (${count('en')} edited)` : ''}`;
    $('#lang-ja').textContent = `日本語${count('ja') ? ` (${count('ja')} edited)` : ''}`;
    $('#lang-en').setAttribute('aria-pressed', String(lang === 'en'));
    $('#lang-ja').setAttribute('aria-pressed', String(lang === 'ja'));
    const edited = editedList();
    $('#editedList').innerHTML = edited.length
      ? 'Edited: ' + edited.map((e) => `<button type="button" class="chip" data-lang="${e.lang}" data-n="${e.n}">${e.lang === 'en' ? 'EN' : 'JA'} ${e.n}</button>`).join('')
      : 'No cards edited yet. Your edits are saved in this browser as you type.';
    const mine = isEdited(lang, n);
    $('#folder').textContent = FOLDERS[lang];
    $('#fname').textContent = pad(n) + '.md';
    $('#status').textContent = mine ? 'Edited. Draft saved in this browser.' : 'Same as the file in the app.';
    $('#status').className = mine ? 'status edited' : 'status';
    $('#reset').disabled = !mine;
    $('#dlOne').textContent = `Download ${pad(n)}.md`;
    $('#dlAll').textContent = `Download all edited (${edited.length})`;
    $('#dlAll').disabled = !edited.length;
  }

  function load(newLang, newN) {
    lang = newLang;
    n = newN;
    store.last = { lang, n };
    ta.value = textOfCard(lang, n);
    ta.lang = lang;
    ta.spellcheck = lang === 'en';
    ta.scrollTop = 0;
    renderShell();
    const scr = $('#scr');
    if (scr) scr.scrollTop = 0;
    refreshControls();
    saveSoon();
  }

  function onType() {
    const k = key(lang, n);
    if (ta.value === original(lang, n)) delete store.drafts[k];
    else store.drafts[k] = ta.value;
    saveSoon();
    renderMd();
    refreshControls();
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
    verse: () => insertBlock('```verse\n[秋|あき]の[田|た]の　かりほの[庵|いほ]の\n```', '[秋|あき]の[田|た]の　かりほの[庵|いほ]の'),
    rule: () => insertBlock('---'),
    picture: () => insertBlock('![caption](assets/pictures/name.png)', 'caption'),
  };

  /* ---- files ---- */

  function download(blob, name) {
    const a = document.createElement('a');
    a.href = URL.createObjectURL(blob);
    a.download = name;
    document.body.appendChild(a);
    a.click();
    a.remove();
    setTimeout(() => URL.revokeObjectURL(a.href), 5000);
  }
  const utf8 = (s) => new TextEncoder().encode(s);

  const CRC = (() => {
    const t = [];
    for (let i = 0; i < 256; i++) {
      let c = i;
      for (let k = 0; k < 8; k++) c = c & 1 ? 0xEDB88320 ^ (c >>> 1) : c >>> 1;
      t[i] = c >>> 0;
    }
    return (bytes) => {
      let c = 0xFFFFFFFF;
      for (let i = 0; i < bytes.length; i++) c = t[(c ^ bytes[i]) & 255] ^ (c >>> 8);
      return (c ^ 0xFFFFFFFF) >>> 0;
    };
  })();

  /* A zip with the files stored as they are (no compression), which is all
     a handful of small Markdown files and pictures need. */
  function makeZip(files) {
    const parts = [];
    const central = [];
    let offset = 0;
    const now = new Date();
    const time = (now.getHours() << 11) | (now.getMinutes() << 5) | (now.getSeconds() >> 1);
    const date = ((now.getFullYear() - 1980) << 9) | ((now.getMonth() + 1) << 5) | now.getDate();
    for (const f of files) {
      const name = utf8(f.name);
      const crc = CRC(f.data);
      const size = f.data.length;
      const head = new DataView(new ArrayBuffer(30));
      [[0, 0x04034b50, 4], [4, 20, 2], [6, 0x0800, 2], [8, 0, 2], [10, time, 2], [12, date, 2], [14, crc, 4], [18, size, 4], [22, size, 4], [26, name.length, 2], [28, 0, 2]]
        .forEach(([at, v, len]) => (len === 4 ? head.setUint32(at, v, true) : head.setUint16(at, v, true)));
      parts.push(new Uint8Array(head.buffer), name, f.data);
      const dir = new DataView(new ArrayBuffer(46));
      [[0, 0x02014b50, 4], [4, 20, 2], [6, 20, 2], [8, 0x0800, 2], [10, 0, 2], [12, time, 2], [14, date, 2], [16, crc, 4], [20, size, 4], [24, size, 4], [28, name.length, 2], [30, 0, 2], [32, 0, 2], [34, 0, 2], [36, 0, 2], [38, 0, 4], [42, offset, 4]]
        .forEach(([at, v, len]) => (len === 4 ? dir.setUint32(at, v, true) : dir.setUint16(at, v, true)));
      central.push(new Uint8Array(dir.buffer), name);
      offset += 30 + name.length + size;
    }
    const size = central.reduce((sum, c) => sum + c.length, 0);
    const end = new DataView(new ArrayBuffer(22));
    end.setUint32(0, 0x06054b50, true);
    end.setUint16(8, files.length, true);
    end.setUint16(10, files.length, true);
    end.setUint32(12, size, true);
    end.setUint32(16, offset, true);
    return new Blob([...parts, ...central, new Uint8Array(end.buffer)], { type: 'application/zip' });
  }

  async function downloadAll() {
    const files = editedList().map((e) => ({ name: `${FOLDERS[e.lang]}${pad(e.n)}.md`, data: utf8(draftOf(e.lang, e.n)) }));
    const used = new Set();
    editedList().forEach((e) => picturesIn(parse(draftOf(e.lang, e.n))).forEach((p) => used.add(p.path)));
    for (const path of used) {
      if (attached[path]) files.push({ name: path, data: new Uint8Array(await attached[path].file.arrayBuffer()) });
    }
    download(makeZip(files), 'fudatobashi-explanations-edited.zip');
  }

  async function copyText() {
    try { await navigator.clipboard.writeText(ta.value); } catch (e) { ta.select(); document.execCommand('copy'); }
    const b = $('#copy');
    b.textContent = 'Copied';
    setTimeout(() => { b.textContent = 'Copy'; }, 1200);
  }

  /* ---- wiring ---- */

  function fitPhone() {
    const narrow = innerWidth < 980;
    const zoom = narrow ? Math.min(1, (innerWidth - 24) / 404) : Math.max(0.6, Math.min(1, (innerHeight - 150) / 852));
    $('#phoneWrap').style.zoom = zoom;
  }

  function init() {
    const sel = $('#card');
    DATA.poems.forEach((p) => sel.add(new Option(`${p.n} · ${p.kimariji}`, String(p.n))));
    sel.addEventListener('change', () => load(lang, +sel.value));
    $('#prev').addEventListener('click', () => load(lang, n === 1 ? 100 : n - 1));
    $('#next').addEventListener('click', () => load(lang, n === 100 ? 1 : n + 1));
    $('#lang-en').addEventListener('click', () => load('en', n));
    $('#lang-ja').addEventListener('click', () => load('ja', n));
    $('#editedList').addEventListener('click', (e) => { const b = e.target.closest('.chip'); if (b) load(b.dataset.lang, +b.dataset.n); });
    ta.addEventListener('input', onType);
    ta.addEventListener('scroll', () => { hl.scrollTop = ta.scrollTop; });
    $('#scriptSeg').addEventListener('click', (e) => {
      const b = e.target.closest('button');
      if (!b) return;
      store.script[lang] = b.dataset.s;
      saveSoon();
      const top = $('#scr')?.scrollTop ?? 0;
      renderShell();
      $('#scr').scrollTop = top;
    });
    $('#jump').addEventListener('click', () => $('#scr').scrollTo({ top: $('#part').offsetTop - 8, behavior: 'smooth' }));
    $('#toolbar').addEventListener('click', (e) => { const b = e.target.closest('button'); if (b) FORMATS[b.dataset.f](); });
    $('#reset').addEventListener('click', () => {
      if (!confirm(`Throw away your changes to ${pad(n)}.md and go back to the file in the app?`)) return;
      delete store.drafts[key(lang, n)];
      save();
      load(lang, n);
    });
    $('#dlOne').addEventListener('click', () => download(new Blob([ta.value], { type: 'text/markdown;charset=utf-8' }), pad(n) + '.md'));
    $('#dlAll').addEventListener('click', downloadAll);
    $('#copy').addEventListener('click', copyText);

    const input = $('#pick');
    let pickPath = '';
    const choose = (path) => { pickPath = path; input.value = ''; input.click(); };
    input.addEventListener('change', () => attach(pickPath, input.files[0]));
    document.addEventListener('click', (e) => {
      const d = e.target.closest('.drop');
      if (d) return choose(d.dataset.path);
      const b = e.target.closest('button[data-act]');
      if (!b) return;
      if (b.dataset.act === 'pick') choose(b.dataset.path);
      if (b.dataset.act === 'unpick') { URL.revokeObjectURL(attached[b.dataset.path].url); delete attached[b.dataset.path]; renderMd(); }
    });
    document.addEventListener('keydown', (e) => {
      const d = e.target.closest?.('.drop');
      if (d && (e.key === 'Enter' || e.key === ' ')) { e.preventDefault(); choose(d.dataset.path); }
    });
    document.addEventListener('dragover', (e) => { e.preventDefault(); });
    document.addEventListener('drop', (e) => {
      e.preventDefault();
      const target = e.target.closest?.('[data-path]');
      if (target && e.dataTransfer.files[0]) attach(target.dataset.path, e.dataTransfer.files[0]);
    });

    $('#howto').open = (() => { try { return localStorage.getItem(KEY + '.howto') === '1'; } catch (e) { return false; } })();
    $('#howto').addEventListener('toggle', () => { try { localStorage.setItem(KEY + '.howto', $('#howto').open ? '1' : '0'); } catch (e) { /* ignore */ } });

    addEventListener('resize', fitPhone);
    fitPhone();
    if (document.fonts) {
      document.fonts.ready.then(fitHeadings);
      document.fonts.addEventListener?.('loadingdone', fitHeadings);
    }
    load(lang, n);
  }

  init();
})();
