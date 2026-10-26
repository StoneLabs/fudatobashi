/* What the editor remembers: the current card and language, the drafts saved
   in this browser, the card data and the pictures chosen for the preview. */
Editor.state = (() => {
  const { TEMPLATES, CARD_COUNT, STORAGE_KEY, SAMPLE_MODE } = Editor.config;

  const store = { drafts: {}, last: { lang: 'en', n: 1 }, script: {}, csv: '' };
  try { Object.assign(store, JSON.parse(localStorage.getItem(STORAGE_KEY) || '{}')); } catch (e) { /* no storage: keep in memory */ }

  const state = {
    store,
    lang: store.last.lang === 'ja' ? 'ja' : 'en',
    n: Math.min(CARD_COUNT, Math.max(0, +store.last.n || 0)),
    poems: {}, // card number -> what the preview needs; empty without CSV data
    attached: {}, // picture path -> { file, url }
  };

  let saveTimer = 0;
  const save = () => { try { if (!SAMPLE_MODE) localStorage.setItem(STORAGE_KEY, JSON.stringify(store)); } catch (e) { /* ignore */ } };
  const saveSoon = () => { clearTimeout(saveTimer); saveTimer = setTimeout(save, 250); };

  const key = (l, i) => `${l}/${i}`;
  const original = (l) => TEMPLATES[l];
  const draftOf = (l, i) => store.drafts[key(l, i)];
  const textOfCard = (l, i) => draftOf(l, i) ?? original(l);
  const isEdited = (l, i) => draftOf(l, i) !== undefined;
  const cards = Array.from({ length: CARD_COUNT + 1 }, (_, i) => i);
  const editedList = () => cards.filter((i) => isEdited(state.lang, i)).map((i) => ({ lang: state.lang, n: i }));
  const poemOf = (i) => state.poems[i];
  const script = () => store.script[state.lang] ?? (state.lang === 'en' ? 'romaji' : 'kana');

  return Object.assign(state, { save, saveSoon, key, original, draftOf, textOfCard, isEdited, cards, editedList, poemOf, script });
})();
