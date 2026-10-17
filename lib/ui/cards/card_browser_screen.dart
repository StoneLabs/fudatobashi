import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../config/design.dart';
import '../../config/vector_art.dart';
import '../../data/poem.dart';
import '../../domain/card_search.dart';
import '../../l10n/card_info_strings.dart';
import '../../l10n/strings.dart';
import '../../state/settings.dart';
import '../manga/manga.dart';
import '../torifuda/torifuda_painter.dart';
import 'about_card_screen.dart';
import 'page_frame.dart';

/// The card browser (Help › Tools): every card in a ruled table of its
/// number, kimariji and torifuda, searched by number or by its first sounds
/// (see [CardSearch]), the matched part marked. A row opens the card's
/// About page.
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

  void _open(Poem poem) {
    FocusScope.of(context).unfocus();
    Navigator.of(context).push(MangaRoute<void>(builder: (_) => AboutCardScreen(poemId: poem.id)));
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final romaji = s.ja ? s.other : s;
    final matches = CardSearch(poems.all, romajiOf: romaji.kimariji).find(_query.text);
    final showRomaji = resolvedKimarijiScript(context) == KimarijiScript.romaji;
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
                SliverToBoxAdapter(child: _CountLine(found: matches.length, searching: _query.text.trim().isNotEmpty)),
                const SliverToBoxAdapter(child: _TableHeader()),
                SliverList.builder(
                  itemCount: matches.length,
                  itemBuilder: (context, i) => _Row(
                    match: matches[i],
                    romaji: showRomaji || matches[i].kind == CardMatchKind.romaji ? romaji.kimariji(matches[i].poem.id) : null,
                    first: i == 0,
                    last: i == matches.length - 1,
                    onTap: () => _open(matches[i].poem),
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
/// kimariji with the romaji (or the matched second half) under it, its
/// torifuda and a chevron. Stamps when tapped.
class _Row extends StatelessWidget {
  const _Row({required this.match, this.romaji, required this.first, required this.last, required this.onTap});

  final CardMatch match;

  /// The kimariji in romaji, to show under the kana.
  final String? romaji;
  final bool first, last;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final poem = match.poem;
    final romaji = this.romaji;
    int marked(CardMatchKind kind) => match.kind == kind ? match.marked : 0;
    const sub = TextStyle(
        fontWeight: Weights.bold,
        fontSize: CardBrowserLayout.subFont,
        height: CardBrowserLayout.subLineHeight,
        color: CardBrowserLayout.subColor);
    final under = switch (match) {
      CardMatch(kind: CardMatchKind.shimo, :final shimo?) => Row(children: [
          InkTag(s.cardShimoTag, fontSize: CardBrowserLayout.tagFont, padding: CardBrowserLayout.tagPadding),
          const SizedBox(width: CardBrowserLayout.tagGap),
          Flexible(child: MarkedText(shimo, style: sub, marked: match.marked)),
        ]),
      _ when romaji != null => MarkedText(romaji, style: sub, marked: marked(CardMatchKind.romaji)),
      _ => null,
    };
    const rule = BorderSide(color: Palette.ink, width: CardBrowserLayout.tableBorder);
    return Semantics(
      label: '${poem.id} ${poem.kimariji}',
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
              child: ColoredBox(color: CardColorGroups.of(poem.color)),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: CardBrowserLayout.rowMinHeight),
              child: Padding(
                padding: CardBrowserLayout.rowPadding,
                child: Row(children: [
                  SizedBox(
                    width: MediaQuery.textScalerOf(context).scale(CardBrowserLayout.numberColumn),
                    child: MarkedText('${poem.id}',
                        style: const TextStyle(fontFamily: Fonts.display, fontSize: CardBrowserLayout.numberFont, height: 1),
                        marked: marked(CardMatchKind.number)),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: CardBrowserLayout.cardGap),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          MarkedText(poem.kimariji,
                              style: const TextStyle(
                                  fontFamily: Fonts.display,
                                  fontSize: CardBrowserLayout.kimarijiFont,
                                  height: CardBrowserLayout.kimarijiLineHeight),
                              marked: marked(CardMatchKind.kana)),
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
                          child: TorifudaCard(poem: poem),
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
