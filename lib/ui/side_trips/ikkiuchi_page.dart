import 'dart:async';

import 'package:flutter/material.dart';

import '../../config/design.dart';
import '../../config/vector_art.dart';
import '../../l10n/ikkiuchi_strings.dart';
import '../../l10n/side_trip_strings.dart';
import '../../l10n/strings.dart';
import '../../state/scope.dart';
import '../history/history_filter.dart';
import '../history/history_screen.dart';
import '../manga/manga.dart';
import 'ikkiuchi_bots_page.dart';
import 'ikkiuchi_custom_page.dart';
import 'ikkiuchi_mode_box.dart';
import 'ikkiuchi_rules_sheet.dart';
import 'side_trip_entry.dart';
import 'side_trip_panels.dart';

/// Opens 一騎打ち's page ([IkkiuchiPage]), once its hall is open.
Future<void> openIkkiuchiPage(BuildContext context) async {
  if (ProgressScope.read(context).sideTripsHub().hallLock != null) return;
  await Navigator.of(context).push(MangaRoute<void>(builder: (_) => const IkkiuchiPage()));
}

/// 一騎打ち's page, on the side trips' page frame, with History beside the
/// back button. Under the header, the ranked modes' tabs over the box of
/// the mode whose tab was opened last (`IkkiuchiSettings.tab`, kept when a
/// tab is tapped): the player's standing in it, the curve of their rating,
/// its match and the burst that starts it ([IkkiuchiRankedBox]). At the
/// foot, free play: the bots' page ([IkkiuchiBotsPage]) and a custom match
/// ([IkkiuchiCustomPage]); then guest mode (the same page, for a guest) and
/// the rules, Home's button pair. Home's
/// dotted ground, in the sea's blue, lies behind; the page scrolls when it
/// is taller than the screen.
class IkkiuchiPage extends StatelessWidget {
  const IkkiuchiPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final progress = ProgressScope.of(context);
    final settings = progress.settings;
    final mode = settings.ikkiuchi.tab;
    return Scaffold(
      body: Stack(children: [
        const Positioned.fill(child: GradationBox(Tones.homeSea)),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Gaps.gutter),
            child: CustomScrollView(slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: HeaderStyle.topGap),
                    MangaHeader(
                      title: ScreenTitle(s.hallName, sub: s.hallTag),
                      actions: [
                        InkIconButton(
                            icon: IconArt.history,
                            semanticLabel: s.history,
                            onTap: () => openHistoryOn(context, HistoryList.ikkiuchi)),
                        InkIconButton(icon: IconArt.back, semanticLabel: s.back, onTap: () => Navigator.maybePop(context)),
                      ],
                    ),
                    const SizedBox(height: IkkiuchiPageLayout.tabsTop),
                    IkkiuchiModeTabs(
                      chosen: mode,
                      onPick: (picked) {
                        if (picked == mode) return;
                        unawaited(progress.updateSettings(
                            settings.copyWith(ikkiuchi: settings.ikkiuchi.copyWith(tab: picked))));
                      },
                      child: IkkiuchiRankedBox(progress.ikkiuchi.of(mode), rows: settings.ikkiuchi.rowsOf(mode)),
                    ),
                    const Spacer(),
                    _FreePlay(
                      onBots: () => Navigator.of(context).push(MangaRoute<void>(builder: (_) => const IkkiuchiBotsPage())),
                      onCustom: () => openIkkiuchiCustom(context),
                    ),
                    const SizedBox(height: IkkiuchiPageLayout.pairTop),
                    Row(children: [
                      Expanded(child: SideTripGuestButton(onTap: () => openIkkiuchiCustom(context, guest: true))),
                      const SizedBox(width: SideTripsLayout.pairGap),
                      Expanded(child: SideTripRulesButton(onTap: () => openIkkiuchiRules(context))),
                    ]),
                    const SizedBox(height: IkkiuchiPageLayout.bottomGap),
                  ],
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}

/// Free play, whose matches leave the rating as it is: the bots ([onBots])
/// and a custom match ([onCustom]), each a row with a chevron.
class _FreePlay extends StatelessWidget {
  const _FreePlay({required this.onBots, required this.onCustom});

  final VoidCallback onBots, onCustom;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return TaggedPanel(
      tag: s.ikkiuchiFreePlay,
      sub: s.sub?.ikkiuchiFreePlay,
      heading: Semantics(
        header: true,
        child: Padding(
          padding: IkkiuchiPageLayout.headingPadding,
          child: PanelLabel(s.ikkiuchiRatingStays, null, fontSize: IkkiuchiPageLayout.headingFont),
        ),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _FreeRow(
          height: IkkiuchiPageLayout.botsRowHeight,
          padding: IkkiuchiPageLayout.botsRowPadding,
          lead: Container(
            width: IkkiuchiPageLayout.botFrame,
            height: IkkiuchiPageLayout.botFrame,
            decoration: BoxDecoration(
              color: IkkiuchiPageLayout.botFrameFill,
              border: Border.all(color: Palette.ink, width: IkkiuchiPageLayout.botFrameBorder),
            ),
            alignment: Alignment.center,
            child: MangaIcon(IconArt.bot,
                size: IkkiuchiPageLayout.botIcon, strokeWidth: IkkiuchiPageLayout.botIconStroke),
          ),
          title: s.ikkiuchiBots,
          sub: s.sub?.ikkiuchiBots,
          line: s.ikkiuchiBotsLine,
          display: true,
          onTap: onBots,
        ),
        _FreeRow(
          height: IkkiuchiPageLayout.customRowHeight,
          padding: IkkiuchiPageLayout.customRowPadding,
          ruled: true,
          lead: SizedBox(
            width: IkkiuchiPageLayout.gearBox,
            child: Center(
              child: MangaIcon(IconArt.settings, size: IkkiuchiPageLayout.gear, strokeWidth: IkkiuchiPageLayout.gearStroke),
            ),
          ),
          title: s.ikkiuchiCustom,
          sub: s.sub?.ikkiuchiCustom,
          line: s.ikkiuchiCustomLine,
          display: false,
          onTap: onCustom,
        ),
      ]),
    );
  }
}

/// A free play row, at least [height] tall inside [padding], under a light rule
/// when [ruled]: [lead], then [title] (in display type when [display]) with
/// the other language's [sub] after it, over a [line] on what is there; a
/// chevron at its end. It stamps a tone while pressed and calls [onTap].
class _FreeRow extends StatelessWidget {
  const _FreeRow({
    required this.height,
    required this.padding,
    this.ruled = false,
    required this.lead,
    required this.title,
    required this.sub,
    required this.line,
    required this.display,
    required this.onTap,
  });

  final double height;
  final EdgeInsets padding;
  final bool ruled;
  final Widget lead;
  final String title, line;
  final String? sub;
  final bool display;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final tracking = s.ja
        ? (display ? IkkiuchiPageLayout.botsTitleTracking : IkkiuchiPageLayout.customTitleTracking)
        : IkkiuchiPageLayout.rowTitleLatinTracking;
    final titleStyle = display
        ? TextStyle(fontFamily: Fonts.display, fontSize: IkkiuchiPageLayout.botsTitleFont, letterSpacing: tracking)
        : TextStyle(fontWeight: Weights.black, fontSize: IkkiuchiPageLayout.customTitleFont, letterSpacing: tracking);
    final lineStyle = display
        ? const TextStyle(
            fontWeight: Weights.bold,
            fontSize: IkkiuchiPageLayout.botsLineFont,
            height: IkkiuchiPageLayout.botsLineHeight,
            color: Palette.mute)
        : const TextStyle(
            fontWeight: Weights.bold,
            fontSize: IkkiuchiPageLayout.customLineFont,
            height: IkkiuchiPageLayout.customLineHeight,
            color: Palette.mute);
    return Pressable(
      onTap: onTap,
      drop: 0,
      turn: 0,
      scale: Press.panelScale,
      semanticLabel: '$title. $line',
      builder: (context, pressed) => Stack(fit: StackFit.passthrough, children: [
        Positioned.fill(
          child: AnimatedOpacity(
            opacity: pressed ? Tones.stampOpacity : 0,
            duration: Motion.stampFade,
            child: const ToneBox(Tones.stamp),
          ),
        ),
        ExcludeSemantics(
          child: Padding(
            padding: IkkiuchiPageLayout.rowMargin,
            child: Container(
              constraints: BoxConstraints(minHeight: height),
              foregroundDecoration: ruled
                  ? const BoxDecoration(
                      border: Border(
                          top: BorderSide(color: IkkiuchiPageLayout.lightRule, width: IkkiuchiPageLayout.customRule)),
                    )
                  : null,
              child: Padding(
                padding: padding,
                child: Row(children: [
                  lead,
                  const SizedBox(width: IkkiuchiPageLayout.rowGap),
                  Expanded(
                    child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text.rich(
                          TextSpan(children: [
                            TextSpan(text: title, style: titleStyle),
                            if (sub case final sub?) ...[
                              const WidgetSpan(child: SizedBox(width: IkkiuchiPageLayout.rowSubGap)),
                              TextSpan(
                                text: sub.toUpperCase(),
                                style: const TextStyle(
                                  fontFamily: Fonts.ui,
                                  fontWeight: Weights.black,
                                  fontSize: IkkiuchiPageLayout.rowSubFont,
                                  letterSpacing: IkkiuchiPageLayout.rowSubTracking,
                                ),
                              ),
                            ],
                          ]),
                          maxLines: 1,
                          style: const TextStyle(height: IkkiuchiPageLayout.rowTitleHeight),
                        ),
                      ),
                      if (display) const SizedBox(height: IkkiuchiPageLayout.botsLineTop),
                      Text.rich(Phrases.span(line), style: lineStyle),
                    ]),
                  ),
                  const SizedBox(width: IkkiuchiPageLayout.rowGap),
                  MangaIcon(IconArt.chevron,
                      size: IkkiuchiPageLayout.chevron, strokeWidth: IkkiuchiPageLayout.chevronStroke),
                ]),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}
