/* Getting drafts out of the editor and back in: downloads, the zip, the clipboard and the JSON file. */
Editor.files = (() => {
  const { CARD_COUNT, FOLDERS } = Editor.config;
  const { $, pad } = Editor.util;
  const { parse } = Editor.CardMarkdown;
  const state = Editor.state;
  const { store, save, key, draftOf, isEdited, editedList } = state;
  const ta = $('#ta');

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
    editedList().forEach((e) => Editor.pictures.picturesIn(parse(draftOf(e.lang, e.n))).forEach((p) => used.add(p.path)));
    for (const path of used) {
      if (state.attached[path]) files.push({ name: path, data: new Uint8Array(await state.attached[path].file.arrayBuffer()) });
    }
    download(makeZip(files), 'fudatobashi-explanations-edited.zip');
  }

  const allDrafts = () => {
    const out = { lang: state.lang, cards: {} };
    editedList().forEach((e) => { out.cards[pad(e.n)] = draftOf(state.lang, e.n); });
    return JSON.stringify(out, null, 2);
  };

  async function toClipboard(text, button, label) {
    try { await navigator.clipboard.writeText(text); } catch (e) {
      const t = document.createElement('textarea');
      t.value = text;
      document.body.appendChild(t);
      t.select();
      document.execCommand('copy');
      t.remove();
    }
    button.textContent = 'Copied';
    setTimeout(() => { button.textContent = label; }, 1200);
  }
  const copyText = () => toClipboard(ta.value, $('#copy'), 'Copy');

  function importJson(text) {
    let data;
    try { data = JSON.parse(text); } catch (e) { return alert('That is not a valid JSON file.'); }
    if (data?.lang !== state.lang) return alert(`This file is for "${data?.lang}" but you are writing "${state.lang}". Change the language in Settings first.`);
    const found = [];
    for (const [k, v] of Object.entries(data.cards ?? {})) {
      if (typeof v === 'string' && /^\d{3}$/.test(k) && +k >= 1 && +k <= CARD_COUNT) found.push([state.lang, +k, v]);
    }
    if (!found.length) return alert('No card texts found in that file.');
    const clash = found.filter(([l, i, v]) => isEdited(l, i) && draftOf(l, i) !== v).length;
    if (!confirm(`Load ${found.length} card text(s)?` + (clash ? ` ${clash} of them replace a draft you already have in this browser.` : ''))) return;
    found.forEach(([l, i, v]) => { store.drafts[key(l, i)] = v; });
    save();
    Editor.app.load(state.lang, state.n);
  }

  function wire() {
    $('#expJson').addEventListener('click', () => download(new Blob([allDrafts()], { type: 'application/json' }), 'fudatobashi-explanations.json'));
    $('#copyAll').addEventListener('click', () => toClipboard(allDrafts(), $('#copyAll'), 'Copy all'));
    $('#impJson').addEventListener('click', () => { $('#impFile').value = ''; $('#impFile').click(); });
    $('#impFile').addEventListener('change', async () => { if ($('#impFile').files[0]) importJson(await $('#impFile').files[0].text()); });
    $('#dlOne').addEventListener('click', () => download(new Blob([ta.value], { type: 'text/markdown;charset=utf-8' }), pad(state.n) + '.md'));
    $('#dlAll').addEventListener('click', downloadAll);
    $('#copy').addEventListener('click', copyText);
  }

  return { wire };
})();
