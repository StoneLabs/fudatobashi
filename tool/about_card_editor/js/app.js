/* The page itself: switching card and language, saving as you type, and starting everything up. */
Editor.app = (() => {
  const { FOLDERS, STORAGE_KEY } = Editor.config;
  const { $, pad, cardName } = Editor.util;
  const state = Editor.state;
  const { store, key, original, textOfCard, isEdited, cards, editedList, saveSoon } = state;
  const ta = $('#ta');

  function refreshControls() {
    const sel = $('#card');
    cards.forEach((i) => { sel.options[i].textContent = cardLabel(i); });
    sel.value = String(state.n);
    $('#langBadge').textContent = state.lang === 'en' ? 'English' : '日本語';
    $('#langSel').value = state.lang;
    const edited = editedList();
    $('#editedList').innerHTML = edited.length
      ? 'Edited: ' + edited.map((e) => `<button type="button" class="chip" data-lang="${e.lang}" data-n="${e.n}">${e.lang === 'en' ? 'EN' : 'JA'} ${cardName(e.n)}</button>`).join('')
      : 'No drafts yet. Your text is saved in this browser as you type.';
    const mine = isEdited(state.lang, state.n);
    $('#folder').textContent = FOLDERS[state.lang];
    $('#fname').textContent = pad(state.n) + '.md';
    $('#status').textContent = mine ? 'Draft saved in this browser.' : 'No draft yet: this is the template.';
    $('#status').className = mine ? 'status edited' : 'status';
    $('#clear').disabled = !mine;
    $('#dlOne').textContent = `Download ${pad(state.n)}.md`;
    $('#dlAll').textContent = `Download all (.zip) (${edited.length})`;
    for (const id of ['#dlAll', '#expJson', '#copyAll']) $(id).disabled = !edited.length;
  }

  const cardLabel = (i) => `${cardName(i)}${state.poems[i]?.kimariji ? ` · ${state.poems[i].kimariji}` : ''}${isEdited(state.lang, i) ? '  ✎ draft' : ''}`;

  function load(newLang, newN) {
    state.lang = newLang;
    state.n = newN;
    store.last = { lang: state.lang, n: state.n };
    ta.value = textOfCard(state.lang, state.n);
    ta.lang = state.lang;
    ta.spellcheck = state.lang === 'en';
    ta.scrollTop = 0;
    Editor.phone.renderShell();
    const scr = $('#scr');
    if (scr) scr.scrollTop = 0;
    refreshControls();
    saveSoon();
  }

  function onType() {
    const k = key(state.lang, state.n);
    if (ta.value === original(state.lang)) delete store.drafts[k];
    else store.drafts[k] = ta.value;
    saveSoon();
    Editor.preview.renderMd();
    refreshControls();
  }

  function fitPhone() {
    const narrow = innerWidth < 980;
    const zoom = narrow ? Math.min(1, (innerWidth - 24) / 404) : Math.max(0.6, Math.min(1, (innerHeight - 150) / 852));
    $('#phoneWrap').style.zoom = zoom;
  }

  function init() {
    const sel = $('#card');
    cards.forEach((i) => sel.add(new Option(cardName(i), String(i))));
    sel.addEventListener('change', () => load(state.lang, +sel.value));
    $('#prev').addEventListener('click', () => load(state.lang, state.n === 0 ? 100 : state.n - 1));
    $('#next').addEventListener('click', () => load(state.lang, state.n === 100 ? 0 : state.n + 1));
    $('#langSel').addEventListener('change', () => load($('#langSel').value, state.n));
    $('#editedList').addEventListener('click', (e) => { const b = e.target.closest('.chip'); if (b) load(b.dataset.lang, +b.dataset.n); });
    ta.addEventListener('input', onType);
    $('#scriptSeg').addEventListener('click', (e) => {
      const b = e.target.closest('button');
      if (!b) return;
      store.script[state.lang] = b.dataset.s;
      saveSoon();
      const top = $('#scr')?.scrollTop ?? 0;
      Editor.phone.renderShell();
      $('#scr').scrollTop = top;
    });
    $('#jump').addEventListener('click', () => $('#scr').scrollTo({ top: $('#part').offsetTop - 8, behavior: 'smooth' }));
    $('#clear').addEventListener('click', () => {
      if (!confirm(`Clear your text for ${pad(state.n)}.md and go back to the template?`)) return;
      delete store.drafts[key(state.lang, state.n)];
      state.save();
      load(state.lang, state.n);
    });
    Editor.editing.wire();
    Editor.colours.wire();
    Editor.files.wire();
    Editor.carddata.wire();
    Editor.pictures.wire();

    $('#howto').open = (() => { try { return localStorage.getItem(STORAGE_KEY + '.howto') === '1'; } catch (e) { return false; } })();
    $('#howto').addEventListener('toggle', () => { try { localStorage.setItem(STORAGE_KEY + '.howto', $('#howto').open ? '1' : '0'); } catch (e) { /* ignore */ } });

    addEventListener('resize', fitPhone);
    fitPhone();
    if (document.fonts) {
      document.fonts.ready.then(Editor.preview.fitHeadings);
      document.fonts.addEventListener?.('loadingdone', Editor.preview.fitHeadings);
    }
    if (Editor.config.SAMPLE_MODE) Editor.sample.install();
    $('#csv').value = store.csv;
    if (store.csv && Editor.carddata.useCsv(store.csv, false)) return;
    load(state.lang, state.n);
  }

  return { load, init };
})();

Editor.app.init();
