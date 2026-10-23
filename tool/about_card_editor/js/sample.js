/* Developer sample: open index.html?sample to see every kind of markup at once.
   It fills card 1 in English with the sample text, shows card data for card 1
   and attaches a drawn picture (the other pictures come from the repo). Nothing is saved while the flag is on. */
Editor.sample = (() => {
  const DRAFT = `# 解説 | Explanation

![Hishikawa's Tenji](assets/pictures/p001.png){.right}

Tenji Tennō wrote this poem while guarding the harvest. This text runs left of the picture until the picture ends, then continues full width. The kimariji is {あきの}. Some words are [red]{.red}, some have a [yellow highlight]{.bg-yellow}, and some are [both together]{.red .bg-yellow}.

![Poet 1, from the repo](assets/artworks/woodcarvings-porter-1909/poet_001.avif){.left}
This paragraph wraps on the picture's right side instead. It starts on the very next line after the picture, which works the same as leaving a blank line. A longer text makes it easier to see how the lines run beside the picture and then below it.

\`\`\`verse
[[秋|あき]の[田|た]の]{.red}　[かりほの]{.bg-yellow}[庵|いほ]の
[苫|とま]をあらみ　[わが[衣手|ころもで]は]{.blue .bg-pink}
::: {.right}
[露|つゆ]にぬれつつ
:::
\`\`\`

## Furigana and right-aligned text

[秋|あき]の[田|た]の、[[庵|いほ]の苫]{.red}を[あらみ|あらみ]。 Plain prose like [a | b] and \\[x|y] stay as typed.

> A quote with [衣手|ころもで] in it.
> ::: {.right}
> — Fujiwara no Teika
> :::

::: {.right}
Right-aligned [紅葉|もみじ] without a box
:::

## A coloured box

::: {.bg-yellow}
The first paragraph of the box. It has [blue words]{.blue} inside.

A second paragraph in the same box.

::: {.right}
— set to the right inside the box
:::
:::

::: {.purple .bg-blue}
A box with purple text on a blue background.
:::

- A list item with [green]{.green} and [gold]{.gold}
- Another item

A picture that stays centred:

![No braces: a picture in the repo that exists](assets/artworks/woodcarvings-porter-1909/poet_002.avif)

![A repo path that does not exist](assets/artworks/missing.png)
`;

  const CSV = 'number,kimariji_kami,kimariji_kami_yomi,color,author_kanji,author_hiragana,verse_1,verse_2,verse_3,verse_4,verse_5,verse_1_hiragana_yomi,verse_2_hiragana_yomi,verse_3_hiragana_yomi,verse_4_hiragana_yomi,verse_5_hiragana_yomi\n'
    + '1,秋の,あきの,黄,天智天皇,てんじてんのう,秋の田の,かりほの庵の,苫をあらみ,わが衣手は,露にぬれつつ,あきのたの,かりほのいほの,とまをあらみ,わがころもでは,つゆにぬれつつ\n';

  /* Pictures drawn on the spot: [path, width, height, colour, label]. */
  const PICTURES = [
    ['assets/pictures/p001.png', 600, 400, '#2B9BFF', 'Landscape 600x400'],
  ];

  function draw([path, width, height, colour, label]) {
    const canvas = Object.assign(document.createElement('canvas'), { width, height });
    const g = canvas.getContext('2d');
    g.fillStyle = colour;
    g.fillRect(0, 0, width, height);
    g.fillStyle = '#141414';
    g.font = 'bold 36px sans-serif';
    g.textAlign = 'center';
    g.fillText(label, width / 2, height / 2);
    canvas.toBlob((blob) => Editor.pictures.attach(path, new File([blob], 'sample.png', { type: 'image/png' })));
  }

  function install() {
    const { state } = Editor;
    state.lang = 'en';
    state.n = 1;
    state.store.drafts[state.key('en', 1)] = DRAFT;
    state.store.csv = CSV;
    PICTURES.forEach(draw);
  }

  return { install };
})();
