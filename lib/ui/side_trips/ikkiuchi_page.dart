import 'package:flutter/material.dart';

import '../../config/design.dart';
import '../../config/vector_art.dart';
import '../../data/poem.dart';
import '../../domain/ikkiuchi_match.dart';
import '../../domain/ikkiuchi_rating.dart';
import '../../domain/ikkiuchi_record.dart';
import '../../l10n/ikkiuchi_strings.dart';
import '../../l10n/side_trip_strings.dart';
import '../../l10n/strings.dart';
import '../../state/ikkiuchi_records.dart';
import '../../state/scope.dart';
import '../history/history_filter.dart';
import '../history/history_screen.dart';
import '../ikkiuchi/ikkiuchi_field_preview.dart';
import '../ikkiuchi/ikkiuchi_match_screen.dart';
import '../manga/manga.dart';
import '../play/time_format.dart';
import 'burst_button.dart';
import 'ikkiuchi_rules_sheet.dart';
import 'ikkiuchi_sheet.dart';
import 'side_trip_entry.dart';
import 'side_trip_panels.dart';
import 'trip_record_panels.dart';

/// Opens 一騎打ち's page ([IkkiuchiPage]), once its hall is open.
Future<void> openIkkiuchiPage(BuildContext context) async {
  if (ProgressScope.read(context).sideTripsHub().hallLock != null) return;
  await Navigator.of(context).push(MangaRoute<void>(builder: (_) => const IkkiuchiPage()));
}

/// 一騎打ち's page, on the side trips' page frame, with History beside the
/// back button: who the player is (the class and rating on the shared class
/// scale, the wins and card margin of the last ranked matches, and the way
/// to the next class); ranked, in a panel with its placement matches while
/// they last and the burst that starts the next ranked match, Tobi's rating
/// for it on the burst; then the custom match, in a panel at the foot that
/// grows upwards: its facts, Tobi's rating among them the way to the custom
/// sheet ([pickIkkiuchiCustom]), the からふだ it reads, a preview of its
/// field and the burst that starts it. Guest mode and the rules are Home's
/// button pair under them, each a sheet. The custom setup starts as the
/// last free match's, or the first free match's before any, and keeps the
/// one confirmed while the page is open. Home's dotted ground, in the sea's
/// blue, lies behind the panels; the page scrolls when it is taller than
/// the screen.
class IkkiuchiPage extends StatefulWidget {
  const IkkiuchiPage({super.key});

  @override
  State<IkkiuchiPage> createState() => _IkkiuchiPageState();
}

class _IkkiuchiPageState extends State<IkkiuchiPage> {
  /// The custom setup confirmed in the sheet, kept while the page is open;
  /// null for the last free match's.
  IkkiuchiSetup? _picked;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final records = ProgressScope.of(context).ikkiuchi;
    final custom = _picked ?? records.freeSetup;
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
                    const SizedBox(height: IkkiuchiPageLayout.gap),
                    _Strip(records),
                    const SizedBox(height: IkkiuchiPageLayout.panelTop),
                    _RankedPanel(records),
                    const SizedBox(height: IkkiuchiPageLayout.panelTop),
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: _CustomPanel(custom, onPick: () async {
                          final chosen = await pickIkkiuchiCustom(context, custom);
                          if (chosen != null && mounted) setState(() => _picked = chosen);
                        }),
                      ),
                    ),
                    const SizedBox(height: IkkiuchiPageLayout.gap),
                    Row(children: [
                      Expanded(child: SideTripGuestButton(onTap: () => openIkkiuchiGuest(context))),
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

/// The page's [ClassStrip]: the class and rating, then the wins of the
/// last [IkkiuchiPageLayout.formMatches] ranked matches over how many, and
/// the average card margin over them ([IkkiuchiMatchRecord.margin]);
/// dashes before the first. The labels go without the other language's,
/// which would wrap them.
class _Strip extends StatelessWidget {
  const _Strip(this.records);

  final IkkiuchiRecords records;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final last = records.lastRanked(IkkiuchiPageLayout.formMatches);
    const big = StatStrip.valueStyle;
    final wins = last.where((m) => m.result == IkkiuchiResult.won).length;
    final margin = last.isEmpty ? null : last.fold(0, (sum, m) => sum + m.margin) / last.length;
    return ClassStrip(
      rating: records.rating,
      change: records.ratingChange,
      placing: records.placing,
      unratedAt: IkkiuchiRating.start,
      more: [
        StatCell(
          label: PanelLabel(s.ikkiuchiWins, null),
          value: last.isEmpty
              ? const Text(IkkiuchiPageLayout.missing, style: big)
              : Text.rich(
                  TextSpan(children: [
                    TextSpan(text: '$wins'),
                    TextSpan(
                        text: '/${last.length}', style: const TextStyle(fontSize: IkkiuchiPageLayout.stripSuffixFont)),
                  ]),
                  style: big,
                ),
        ),
        StatCell(
          label: PanelLabel(s.ikkiuchiMargin, null),
          value: Text(margin == null ? IkkiuchiPageLayout.missing : _signed(margin), style: big),
        ),
      ],
    );
  }

  /// [x] to a tenth, with its sign.
  static String _signed(double x) => '${x < 0 ? '−' : '+'}${x.abs().toStringAsFixed(1)}';
}

/// Ranked: while the rating is being placed, the placement matches under
/// their heading (those played, each its result over its change; dashed
/// slots for the rest, the next one marked); then the burst that starts the
/// next ranked match, with Tobi's rating for it.
class _RankedPanel extends StatelessWidget {
  const _RankedPanel(this.records);

  final IkkiuchiRecords records;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final placing = records.placing;
    final setup = records.rankedSetup;
    final tobi = setup.opponentRating.round();
    return TaggedPanel(
      tag: s.ikkiuchiRankedMode,
      sub: s.sub?.ikkiuchiRankedMode,
      heading: placing ? PanelHeading(s.ikkiuchiPlacementTitle) : null,
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (placing) Padding(padding: IkkiuchiPageLayout.gamesPadding, child: _Placement(records)),
        Padding(
          padding: IkkiuchiPageLayout.rankedRowPadding,
          child: BurstButton(
            title: s.sideTripRanked,
            tag: _TobiTag(tobi),
            semanticLabel: '${s.sideTripRanked} ${s.ikkiuchiTobi} $tobi',
            onTap: () => startIkkiuchiMatch(context, setup),
          ),
        ),
      ]),
    );
  }
}

/// The placement matches: those played, then dashed slots for the rest,
/// the next one marked.
class _Placement extends StatelessWidget {
  const _Placement(this.records);

  final IkkiuchiRecords records;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final played = records.matches.where((m) => m.ranked).toList();
    return GameRow([
      for (var i = 0; i < IkkiuchiRating.placementMatches; i++)
        if (i < played.length)
          _Played(played[i], change: played[i].rating! - (i == 0 ? IkkiuchiRating.start : played[i - 1].rating!))
        else
          PlacementSlot(i + 1,
              next: i == played.length ? (s.ikkiuchiPlacementNext, s.sub?.ikkiuchiPlacementNext) : null),
    ]);
  }
}

/// A placement match played: won or lost, over what it did to the
/// estimate ([change]).
class _Played extends StatelessWidget {
  const _Played(this.match, {required this.change});

  final IkkiuchiMatchRecord match;
  final double change;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final won = match.result == IkkiuchiResult.won;
    return DefaultTextStyle.merge(
      softWrap: false,
      child: Column(children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(won ? s.ikkiuchiWon : s.ikkiuchiLost,
              style: TextStyle(
                  fontFamily: Fonts.display,
                  fontSize: IkkiuchiPageLayout.resultFont,
                  height: 1,
                  color: won ? Palette.ink : IkkiuchiPageLayout.lostInk)),
        ),
        const SizedBox(height: IkkiuchiPageLayout.resultGap),
        FittedBox(fit: BoxFit.scaleDown, child: RatingChangeTag(change.round())),
      ]),
    );
  }
}

/// Tobi's [rating] for the next ranked match on an ink tag: his name, then
/// the rating.
class _TobiTag extends StatelessWidget {
  const _TobiTag(this.rating);

  final int rating;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: const BoxDecoration(color: Palette.ink),
        child: Padding(
          padding: IkkiuchiPageLayout.tobiTagPadding,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(S.of(context).ikkiuchiTobi,
                  style: const TextStyle(
                      fontWeight: Weights.black,
                      fontSize: IkkiuchiPageLayout.tobiTagNameFont,
                      height: 1,
                      color: IkkiuchiPageLayout.tobiTagName)),
              const SizedBox(width: IkkiuchiPageLayout.tobiTagGap),
              Text('$rating',
                  style: const TextStyle(
                      fontFamily: Fonts.display,
                      fontSize: IkkiuchiPageLayout.tobiTagFont,
                      height: 1,
                      color: Palette.paper)),
            ],
          ),
        ),
      );
}

/// The custom match of [setup]: its facts across the panel (Tobi's rating
/// boxed, the button that calls [onPick], then the cards a side and the
/// memory time, split by an ink rule), the からふだ it reads, a preview of
/// its field, and the burst that starts it.
class _CustomPanel extends StatelessWidget {
  const _CustomPanel(this.setup, {required this.onPick});

  final IkkiuchiSetup setup;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    const big = TextStyle(fontFamily: Fonts.display, fontSize: IkkiuchiPageLayout.statFont, height: 1);
    const hint = TextStyle(fontWeight: Weights.bold, fontSize: IkkiuchiPageLayout.hintFont, color: Palette.mute);
    const hintNumber = TextStyle(fontFamily: Fonts.display, fontSize: IkkiuchiPageLayout.hintNumber, color: Palette.ink);
    final field = 2 * setup.perSide;
    final karafuda = IkkiuchiReadOrder.karafuda(field: field, away: poems.all.length - field);
    return TaggedPanel(
      tag: s.ikkiuchiCustom,
      sub: s.sub?.ikkiuchiCustom,
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
          padding: IkkiuchiPageLayout.statsPadding,
          child: CellRow(firstRuled: false, fills: true, children: [
            DropCellButton(
              onTap: onPick,
              semanticLabel: s.ikkiuchiCustomSetup,
              label: PanelLabel(s.ikkiuchiTobiRating, null),
              value: Text('${setup.opponentRating.round()}', style: big),
            ),
            StatCell(
              inset: IkkiuchiPageLayout.cellInset,
              label: PanelLabel(s.ikkiuchiPerSide, null),
              value: NumberedText(
                s.ikkiuchiPerSideCount,
                [setup.perSide],
                style: const TextStyle(
                    fontWeight: Weights.black, fontSize: IkkiuchiPageLayout.statSuffixFont, height: 1),
                numberStyle: big,
              ),
            ),
            StatCell(
              inset: IkkiuchiPageLayout.cellInset,
              label: PanelLabel(s.ikkiuchiMemoryTime, null),
              value: Text(formatMinutes(setup.memorise), style: big),
            ),
          ]),
        ),
        Padding(
          padding: IkkiuchiPageLayout.hintPadding,
          child: Align(
            alignment: Alignment.centerLeft,
            child: NumberedText(s.ikkiuchiKarafudaLine, [karafuda], style: hint, numberStyle: hintNumber),
          ),
        ),
        Flexible(child: IkkiuchiFieldPreview(setup.perSide)),
        Padding(
          padding: IkkiuchiPageLayout.burstMargin,
          child: BurstButton(
            title: s.ikkiuchiPlayCards(setup.perSide),
            onTap: () => startIkkiuchiMatch(context, setup),
          ),
        ),
      ]),
    );
  }
}
