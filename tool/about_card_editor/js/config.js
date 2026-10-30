/* The editor's one global, Editor, and its settings. Every number, colour and
   text the editor uses on purpose lives here; the other files only use them. */
const Editor = {};

Editor.config = (() => {
  /* Colours the writers can pick, taken from lib/config/design/core.dart
     (Palette). Text colours need 4.5:1 against white, so they use the deep
     tokens; backgrounds are the soft tokens, which keep the dark body text
     above 13:1. "token" says where each value comes from. */
  const PALETTE = {
    text: [
      { name: 'red', hex: '#B0101C', token: 'Palette.alarmDeep' },
      { name: 'pink', hex: '#E0246A', token: 'Palette.pinkDeep' },
      { name: 'blue', hex: '#1463C4', token: 'Palette.seaDeep' },
      { name: 'green', hex: '#4F743D', token: 'Palette.landDeep mixed 20% with Palette.ink (landDeep alone is only 3.9:1)' },
      { name: 'purple', hex: '#6E2C8C', token: 'Palette.violetDeep' },
      { name: 'gold', hex: '#8E6B26', token: 'Palette.goldDeep' },
    ],
    background: [
      { name: 'yellow', hex: '#FFF4BF', token: 'Palette.sunSoft' },
      { name: 'pink', hex: '#FFE1EB', token: 'Palette.pinkSoft' },
      { name: 'blue', hex: '#DCEFFF', token: 'Palette.seaSoft' },
      { name: 'green', hex: '#E5F6D8', token: 'Palette.landSoft' },
      { name: 'orange', hex: '#FFE8CF', token: 'Palette.orangeSoft' },
      { name: 'purple', hex: '#F1E6F7', token: 'Palette.violetSoft' },
    ],
    backgroundPrefix: 'bg-',
  };

  return {
    /* The card colour groups, from lib/config/design/core.dart (Palette). */
    GROUP_COLORS: { 青: '#2B9BFF', 桃: '#FF3D7F', 黄: '#FFD83A', 緑: '#8ED462', 橙: '#FF9A2E' },
    NEUTRAL_COLOR: '#B9B9C2',
    TEMPLATES: { en: '# Coming soon', ja: '# 準備中 | Coming soon' },
    CSV_URL: 'https://raw.githubusercontent.com/StoneLabs/hyakuninissyu-csv/master/data.csv',
    CARD_COUNT: 100,
    /* The 序歌 is card 000, listed before card 1. */
    JOKA_LABEL: '序歌',
    EMPHASIS_TINT: 0.45,
    BLOCK_TAGS: new Set(['h1', 'h2', 'h3', 'h4', 'p', 'ul', 'ol', 'blockquote', 'pre', 'hr', 'div']),
    GAPS: { h1: 26, h2: 22, h3: 16, h4: 16, block: 10, item: 6, quote: 10 },
    FOLDERS: { en: 'assets/l10n/en_articles/card_details/', ja: 'assets/l10n/ja_articles/card_details/' },
    /* Pictures written as assets/… are looked up in the repo, this far up from index.html. */
    REPO_ROOT: '../../',
    /* Developer flag: index.html?sample opens a sample draft with its pictures and
       card data, and saves nothing, so the writer's own drafts are left alone. */
    SAMPLE_MODE: /[?&]sample\b/.test(location.search),
    STORAGE_KEY: 'fudatobashi.explanationEditor.v1',
    PALETTE,
    /* A picture with {.left} or {.right}: its width as a share of the text column,
       its height cap and the gap between it and the text (px). */
    FLOAT: { sides: ['left', 'right'], width: '42%', maxHeight: 180, gap: 12 },
    /* Classes that only align, on a ::: box or a verse block. */
    ALIGN_CLASSES: ['right'],
    /* The coloured box made by ::: {.bg-yellow}: padding and border (px). */
    BOX: { padding: '10px 12px', border: 2 },
    WORDS: {
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
    },
    ICON_BACK: '<svg class="ic" viewBox="0 0 24 24"><path d="M15 5l-7 7 7 7"/></svg>',
  };
})();
