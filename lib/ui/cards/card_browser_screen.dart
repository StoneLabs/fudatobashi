import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../config/design.dart';
import '../../config/vector_art.dart';
import '../../data/joka.dart';
import '../../data/poem.dart';
import '../../domain/card_search.dart';
import '../../l10n/card_info_strings.dart';
import '../../l10n/romaji.dart';
import '../../l10n/strings.dart';
import '../../state/settings.dart';
import '../manga/manga.dart';
import '../torifuda/torifuda_painter.dart';
import '../torifuda/yomifuda_card.dart';
import 'about_card_screen.dart';
import 'page_frame.dart';

/// The card browser (Help › Tools): every card in a ruled table of its
/// number, kimariji and torifuda, searched by number or by its first sounds
/// (see [CardSearch]), the matched part marked. A row opens the card's
/// About page. Over card 1, while nothing is searched, sits the 序歌 with
/// its reading card.
class CardBrowserScreen extends StatefulWidget {
  const CardBrowserScreen({super.key});

  @override
  State<CardBrowserScreen> createState() => _CardBrowserScreenState();
}

class _CardBrowserScreenState extends State<CardBrowserScreen> {
  final _query = TextEditingController();

  @override
  void initState() {
    super.initState();
    _query.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  void _open(AboutCardScreen page) {
    FocusScope.of(context).unfocus();
    Navigator.of(context).push(MangaRoute<void>(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final romaji = s.ja ? s.other : s;
    final matches = CardSearch(poems.all, romajiOf: romaji.kimariji).find(_query.text);
    final showRomaji = resolvedKimarijiScript(context) == KimarijiScript.romaji;
    final searching = _query.text.trim().isNotEmpty;
    return PageFrame(
      title: s.cardBrowserTitle,
      sub: s.other.cardBrowserTitle,
      body: CustomScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          SliverPadding(
            padding: PageFrame.padding,
            sliver: SliverMainAxisGroup(slivers: [
              SliverToBoxAdapter(child: _SearchField(controller: _query)),
              if (matches.isEmpty)
                SliverToBoxAdapter(child: _NoMatch(query: _query.text.trim(), onClear: _query.clear))
              else ...[
                SliverToBoxAdapter(child: _CountLine(found: matches.length, searching: searching)),
                const SliverToBoxAdapter(child: _TableHeader()),
                if (!searching)
                  SliverToBoxAdapter(
                    child: _JokaRow(romajiFirst: showRomaji, onTap: () => _open(const AboutCardScreen.joka())),
                  ),
                SliverList.builder(
                  itemCount: matches.length,
                  itemBuilder: (context, i) => _CardRow(
                    match: matches[i],
                    romajiFirst: showRomaji,
                    romaji: showRomaji || matches[i].kind == CardMatchKind.romaji ? romaji.kimariji(matches[i].poem.id) : null,
                    first: i == 0 && searching,
                    last: i == matches.length - 1,
                    onTap: () => _open(AboutCardScreen(poemId: matches[i].poem.id)),
                  ),
                ),
              ],
            ]),
          ),
        ],
      ),
    );
  }
}

/// The search: an ink box with the magnifier, what is typed and a round
/// button that clears it; a sun shadow while it has the focus.
class _SearchField extends StatefulWidget {
  const _SearchField({required this.controller});

  final TextEditingController controller;

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    const text = TextStyle(fontWeight: Weights.bold, fontSize: CardBrowserLayout.searchFont, color: Palette.ink);
    return Container(
      height: CardBrowserLayout.searchHeight,
      padding: CardBrowserLayout.searchPadding,
      decoration: BoxDecoration(
        color: Palette.paper,
        border: Border.all(color: Palette.ink, width: CardBrowserLayout.searchBorder),
        boxShadow: [
          if (_focus.hasFocus)
            const BoxShadow(
                color: Palette.sun, offset: Offset(CardBrowserLayout.searchFocusShadow, CardBrowserLayout.searchFocusShadow)),
        ],
      ),
      child: Row(children: [
        MangaIcon(IconArt.search),
        const SizedBox(width: CardBrowserLayout.searchGap),
        Expanded(
          child: TextField(
            controller: widget.controller,
            focusNode: _focus,
            style: text,
            cursorColor: Palette.ink,
            autocorrect: false,
            enableSuggestions: false,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration.collapsed(
              hintText: s.cardSearchHint,
              hintStyle: text.copyWith(color: CardBrowserLayout.searchHint),
            ),
          ),
        ),
        if (widget.controller.text.isNotEmpty)
          Pressable(
            semanticLabel: s.cardSearchClear,
            onTap: widget.controller.clear,
            builder: (context, pressed) => Container(
              width: CardBrowserLayout.clearSize,
              height: CardBrowserLayout.clearSize,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Palette.paper,
                shape: BoxShape.circle,
                border: Border.all(color: Palette.ink, width: Strokes.label),
              ),
              child: MangaIcon(IconArt.close,
                  size: CardBrowserLayout.clearIcon, strokeWidth: CardBrowserLayout.clearStroke),
            ),
          ),
      ]),
    );
  }
}

/// How many cards show, and what a tap on one does.
class _CountLine extends StatelessWidget {
  const _CountLine({required this.found, required this.searching});

  final int found;
  final bool searching;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Padding(
      padding: CardBrowserLayout.countPadding,
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.end,
        spacing: Gaps.small,
        children: [
          Text(searching ? s.cardCountFound(found, poems.all.length) : s.cardCountAll(found),
              style: const TextStyle(
                  fontWeight: Weights.black,
                  fontSize: CardBrowserLayout.countFont,
                  letterSpacing: CardBrowserLayout.countFont * TagStyle.tracking)),
          Text(s.cardTapHint,
              style: const TextStyle(
                  fontWeight: Weights.bold, fontSize: CardBrowserLayout.hintFont, color: CardBrowserLayout.hintColor)),
        ],
      ),
    );
  }
}

/// The table's ink header band: the columns' names.
class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    const style = TextStyle(
        fontWeight: Weights.black,
        fontSize: CardBrowserLayout.headerFont,
        letterSpacing: CardBrowserLayout.headerFont * CardBrowserLayout.headerTracking,
        color: Palette.paper);
    return Container(
      constraints: const BoxConstraints(minHeight: CardBrowserLayout.headerHeight),
      color: Palette.ink,
      padding: const EdgeInsets.only(left: CardBrowserLayout.rowLeftPad + CardBrowserLayout.tableBorder),
      child: Row(children: [
        SizedBox(
          width: MediaQuery.textScalerOf(context).scale(CardBrowserLayout.numberColumn),
          child: Text(s.cardColumnNumber, style: style),
        ),
        Expanded(child: Text(s.cardColumnKimariji, style: style)),
        SizedBox(
          width: CardBrowserLayout.cardColumn,
          child: Text(s.cardColumnCard, textAlign: TextAlign.center, maxLines: 1, softWrap: false, style: style),
        ),
      ]),
    );
  }
}

/// One card in the table: its colour group's strip, its number, its
/// kimariji with the romaji (or the matched second half) under it, and its
/// torifuda.
class _CardRow extends StatelessWidget {
  const _CardRow({required this.match, this.romaji, this.romajiFirst = false, required this.first, required this.last, required this.onTap});

  final CardMatch match;

  /// The kimariji in romaji, to show under the kana.
  final String? romaji;

  /// Whether the romaji is the big line and the kana the small one.
  final bool romajiFirst;
  final bool first, last;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final poem = match.poem;
    final romaji = this.romaji;
    int marked(CardMatchKind kind) => match.kind == kind ? match.marked : 0;
    final under = switch (match) {
      CardMatch(kind: CardMatchKind.shimo, :final shimo?) => Row(children: [
          InkTag(s.cardShimoTag, fontSize: CardBrowserLayout.tagFont, padding: CardBrowserLayout.tagPadding),
          const SizedBox(width: CardBrowserLayout.tagGap),
          Flexible(child: MarkedText(shimo, style: _Row.sub, marked: match.marked)),
        ]),
      _ when romaji != null && romajiFirst =>
        MarkedText(poem.kimariji, style: _Row.sub, marked: marked(CardMatchKind.kana)),
      _ when romaji != null => MarkedText(romaji, style: _Row.sub, marked: marked(CardMatchKind.romaji)),
      _ => null,
    };
    return _Row(
      label: '${poem.id} ${poem.kimariji}',
      strip: CardColorGroups.of(poem.color),
      number: MarkedText('${poem.id}', style: _Row.numberStyle, marked: marked(CardMatchKind.number)),
      title: MarkedText(romaji != null && romajiFirst ? romaji : poem.kimariji,
          style: _Row.titleStyle,
          marked: marked(romaji != null && romajiFirst ? CardMatchKind.romaji : CardMatchKind.kana)),
      under: under,
      card: TorifudaCard(poem: poem),
      first: first,
      last: last,
      onTap: onTap,
    );
  }
}

/// The 序歌's row, over card 1's: no number, its name where a kimariji
/// goes (romaji first when the kimariji are) with what it is beside it
/// outside Japanese, and its reading card.
class _JokaRow extends StatelessWidget {
  const _JokaRow({required this.romajiFirst, required this.onTap});

  final bool romajiFirst;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final gloss = S.of(context).cardJokaGloss;
    final under = [if (romajiFirst) jokaTitle, if (gloss.isNotEmpty) gloss];
    return _Row(
      label: [jokaTitle, if (gloss.isNotEmpty) gloss].join(' '),
      strip: CardColorGroups.none,
      title: Text(romajiFirst ? hepburn(jokaTitleKana) : jokaTitle, style: _Row.titleStyle),
      under: under.isEmpty
          ? null
          : Wrap(
              spacing: CardBrowserLayout.glossGap,
              children: [for (final text in under) Text(text, style: _Row.sub)],
            ),
      card: YomifudaCard(poem: joka),
      first: true,
      last: false,
      onTap: onTap,
    );
  }
}

/// A row of the table: [strip]'s colour down its left edge, [number],
/// [title] (shrinking rather than cut short) with [under] under it, a small
/// [card] and a chevron. Stamps when tapped.
class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.strip,
    this.number,
    required this.title,
    this.under,
    required this.card,
    required this.first,
    required this.last,
    required this.onTap,
  });

  /// What a screen reader says for the row.
  final String label;
  final Color strip;
  final Widget? number;
  final Widget title;
  final Widget? under;
  final Widget card;
  final bool first, last;
  final VoidCallback onTap;

  static const numberStyle = TextStyle(fontFamily: Fonts.display, fontSize: CardBrowserLayout.numberFont, height: 1);
  static const titleStyle = TextStyle(
      fontFamily: Fonts.display,
      fontSize: CardBrowserLayout.kimarijiFont,
      height: CardBrowserLayout.kimarijiLineHeight);
  static const sub = TextStyle(
      fontWeight: Weights.bold,
      fontSize: CardBrowserLayout.subFont,
      height: CardBrowserLayout.subLineHeight,
      color: CardBrowserLayout.subColor);

  @override
  Widget build(BuildContext context) {
    final under = this.under;
    const rule = BorderSide(color: Palette.ink, width: CardBrowserLayout.tableBorder);
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: rule,
            right: rule,
            top: first ? BorderSide.none : const BorderSide(color: Palette.ink, width: CardBrowserLayout.rowRule),
            bottom: last ? rule : BorderSide.none,
          ),
        ),
        child: Pressable(
          onTap: onTap,
          drop: 0,
          turn: 0,
          scale: 1,
          builder: (context, pressed) => Stack(children: [
            Positioned.fill(child: ColoredBox(color: pressed ? Palette.sunSoft : Palette.paper)),
            Positioned.fill(
              child: AnimatedOpacity(
                opacity: pressed ? Tones.stampOpacity : 0,
                duration: Motion.stampFade,
                child: const ToneBox(Tones.stamp),
              ),
            ),
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: CardBrowserLayout.strip,
              child: ColoredBox(color: strip),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: CardBrowserLayout.rowMinHeight),
              child: Padding(
                padding: CardBrowserLayout.rowPadding,
                child: Row(children: [
                  SizedBox(
                    width: MediaQuery.textScalerOf(context).scale(CardBrowserLayout.numberColumn),
                    child: number,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: CardBrowserLayout.cardGap),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: title),
                          if (under != null) ...[const SizedBox(height: CardBrowserLayout.subGap), under],
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    width: CardBrowserLayout.cardColumn - CardBrowserLayout.chevronColumn,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        width: CardBrowserLayout.card,
                        child: DecoratedBox(
                          decoration: const BoxDecoration(boxShadow: [
                            BoxShadow(color: CardBrowserLayout.cardShadowColor, offset: CardBrowserLayout.cardShadow),
                          ]),
                          child: card,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: CardBrowserLayout.chevronColumn,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: MangaIcon(IconArt.chevron, size: CardBrowserLayout.chevron),
                    ),
                  ),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

/// No card matched: a blank card with a question mark, a line on what to
/// try and a button that clears the search.
class _NoMatch extends StatelessWidget {
  const _NoMatch({required this.query, required this.onClear});

  final String query;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final number = CardSearch.isNumber(CardSearch.normalize(query));
    return Padding(
      padding: CardBrowserLayout.emptyPadding,
      child: Column(children: [
        Transform.rotate(
          angle: CardBrowserLayout.emptyCardTurn * math.pi / 180,
          child: SizedBox(
            width: CardBrowserLayout.emptyCard,
            child: Stack(alignment: Alignment.center, children: [
              TorifudaCard(poem: poems.all.first, showText: false, showNumber: false),
              const Text('?', style: TextStyle(fontFamily: Fonts.display, fontSize: CardBrowserLayout.emptyMarkFont)),
            ]),
          ),
        ),
        const SizedBox(height: CardBrowserLayout.emptyCardGap),
        Text.rich(Phrases.span(number ? s.cardNoneNumberTitle(query) : s.cardNoneTitle(query)),
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontFamily: Fonts.display,
                fontSize: CardBrowserLayout.emptyTitleFont,
                height: CardBrowserLayout.emptyTitleLineHeight)),
        const SizedBox(height: CardBrowserLayout.emptyTextGap),
        Text.rich(Phrases.span(number ? s.cardNoneNumberText : s.cardNoneText),
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontWeight: Weights.medium,
                fontSize: CardBrowserLayout.emptyTextFont,
                height: CardBrowserLayout.emptyTextLineHeight,
                color: Palette.inkSoft)),
        const SizedBox(height: CardBrowserLayout.emptyButtonGap),
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: CardBrowserLayout.emptyButtonHeight),
          child: IntrinsicWidth(
            child: InkButton(
              onTap: onClear,
              padding: CardBrowserLayout.emptyButtonPadding + const EdgeInsets.all(Strokes.button),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                MangaIcon(IconArt.close, size: CardBrowserLayout.emptyButtonIcon),
                const SizedBox(width: CardBrowserLayout.emptyButtonIconGap),
                Text(s.cardSearchClear,
                    style: const TextStyle(fontWeight: Weights.black, fontSize: CardBrowserLayout.emptyButtonFont)),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}
