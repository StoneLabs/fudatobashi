import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../config/vector_art.dart';
import '../../domain/ankiren_level.dart';
import '../../domain/side_trips.dart';
import '../../l10n/ankiren_strings.dart';
import '../../l10n/free_strings.dart';
import '../../l10n/side_trip_strings.dart';
import '../../l10n/strings.dart';
import '../../state/scope.dart';
import '../ankiren/ankiren_field_preview.dart';
import '../ankiren/ankiren_strikes.dart';
import '../history/history_screen.dart';
import '../manga/manga.dart';
import '../play/time_format.dart';
import '../run/run_launcher.dart';
import 'ankiren_free_sheet.dart';
import 'ankiren_rules_sheet.dart';
import 'burst_button.dart';
import 'side_trip_entry.dart';
import 'side_trip_panels.dart';
import 'trip_record_panels.dart';

/// Opens 暗記練's page ([AnkirenPage]), once 暗記練 is open.
Future<void> openAnkirenPage(BuildContext context) async {
  if (!ProgressScope.read(context).sideTripsHub()[SideTrip.ankiren].open) return;
  await Navigator.of(context).push(MangaRoute<void>(builder: (_) => const AnkirenPage()));
}

/// 暗記練's page, the hub's panel opened up, on one screen, with History
/// beside the back button: who the player is (the class and rating, and the
/// way to the next class); ranked, in a panel with its last games (or the
/// placement games so far), its one setup and the burst that starts it, all
/// chained up until ranked opens (see [RankedLock]); then free play's next
/// level to clear, or the setup picked instead, in a larger panel with its
/// facts, what clears it, a preview of its field, the way to the level
/// sheet ([pickAnkirenFree]) and the burst that starts it. Guest mode
/// and the rules are Home's button pair under them, each a sheet. The first
/// visit opens with the rules. Home's dotted ground, in the sea's blue, lies
/// behind the panels.
///
/// The field preview is the one part that gives up height. With too
/// little room for it, the free-play panel closes up over its burst, which
/// stays near the thumb. When even without it the page is taller than the
/// screen, it scrolls.
class AnkirenPage extends StatefulWidget {
  const AnkirenPage({super.key});

  @override
  State<AnkirenPage> createState() => _AnkirenPageState();
}

class _AnkirenPageState extends State<AnkirenPage> {
  /// The setup picked from the level sheet, kept while the page is open;
  /// null for the next level to clear.
  AnkirenSetup? _picked;

  @override
  void initState() {
    super.initState();
    if (!ProgressScope.read(context).settings.ankiren.rulesSeen) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) openAnkirenRules(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final entry = ProgressScope.of(context).sideTripsHub()[SideTrip.ankiren];
    const trip = SideTrip.ankiren;
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
                      title: ScreenTitle(s.tripName(trip), sub: s.tripTag(trip)),
                      actions: [
                        InkIconButton(
                            icon: IconArt.history,
                            semanticLabel: s.history,
                            onTap: () => openTripHistory(context, trip)),
                        InkIconButton(icon: IconArt.back, semanticLabel: s.back, onTap: () => Navigator.maybePop(context)),
                      ],
                    ),
                    const SizedBox(height: AnkirenPageLayout.gap),
                    RecordStrip(entry),
                    const SizedBox(height: AnkirenPageLayout.nextTop),
                    RankedPanel(
                      entry,
                      onStart: () => startAnkirenRanked(context),
                    ),
                    const SizedBox(height: AnkirenPageLayout.nextTop),
                    Expanded(child: Align(alignment: Alignment.bottomCenter, child: _NextLevelPanel(
                      entry,
                      picked: _picked,
                      onPick: (setup) => setState(() => _picked = setup),
                    ))),
                    const SizedBox(height: AnkirenPageLayout.gap),
                    Row(children: [
                      Expanded(child: SideTripGuestButton(onTap: () => openAnkirenGuest(context))),
                      const SizedBox(width: SideTripsLayout.pairGap),
                      Expanded(child: SideTripRulesButton(onTap: () => openAnkirenRules(context))),
                    ]),
                    const SizedBox(height: AnkirenPageLayout.bottomGap),
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

/// Free play's next level to clear (the top level again once every level
/// is cleared), or the setup [picked] instead under Free play's tag: its
/// facts, the level among them the way to the level sheet, what clears it
/// (or that a custom game is not scored, or what the known cards still
/// lack), a preview of its field, and the burst that starts it. A setup
/// confirmed in the sheet goes to [onPick], as null when it is the next
/// level to clear.
class _NextLevelPanel extends StatelessWidget {
  const _NextLevelPanel(this.entry, {required this.picked, required this.onPick});

  final SideTripEntry entry;
  final AnkirenSetup? picked;
  final ValueChanged<AnkirenSetup?> onPick;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final next = entry.nextLevel;
    final usual = AnkirenSetup.forLevel(next ?? AnkirenLevels.top);
    final setup = picked ?? usual;
    final level = setup.level;
    final fits = level == null || entry.fits(level);
    final allCleared = picked == null && next == null;
    String tag(S s) => picked != null
        ? s.freePlay
        : allCleared
            ? s.ankirenAllClearedTitle
            : s.ankirenNextToClear;
    String play(S s) => level == null ? s.freeStart : s.ankirenPlayLevel(level);
    Future<void> pick() async {
      final chosen = await pickAnkirenFree(context, setup);
      if (chosen != null && context.mounted) onPick(chosen == usual ? null : chosen);
    }

    return TaggedPanel(
      tag: tag(s),
      sub: s.sub == null ? null : tag(s.sub!),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _Stats(setup, onLevel: pick),
        _Hint(setup, fits: fits, allCleared: allCleared, cleared: level != null && entry.ladder.isCleared(level)),
        Flexible(child: AnkirenFieldPreview(setup)),
        Padding(
          padding: AnkirenPageLayout.burstMargin,
          child: BurstButton(
            title: play(s),
            onTap: fits ? () => startAnkirenFree(context, setup) : null,
          ),
        ),
      ]),
    );
  }
}

/// A setup's facts across the panel: the level, as the button that calls
/// [onLevel], then the cards a side and the memorise time, split by an ink
/// rule, their labels and values in line with the level's.
class _Stats extends StatelessWidget {
  const _Stats(this.setup, {required this.onLevel});

  final AnkirenSetup setup;
  final VoidCallback onLevel;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    const big = TextStyle(fontFamily: Fonts.display, fontSize: AnkirenPageLayout.statFont, height: 1);
    return Padding(
      padding: AnkirenPageLayout.statsPadding,
      child: CellRow(firstRuled: false, fills: true, children: [
        _LevelButton(setup.level, onTap: onLevel),
        StatCell(
          inset: AnkirenPageLayout.levelButtonInset,
          label: PanelLabel(s.ankirenCards, null),
          value: NumberedText(
            s.ankirenPerSideCount,
            [setup.perSide],
            style: const TextStyle(fontWeight: Weights.black, fontSize: AnkirenPageLayout.statSuffixFont, height: 1),
            numberStyle: big,
          ),
        ),
        StatCell(
          inset: AnkirenPageLayout.levelButtonInset,
          label: PanelLabel(s.ankirenMemoriseLabel, null),
          value: Text(formatMinutes(setup.memorise), style: big),
        ),
      ]),
    );
  }
}

/// The [level]'s cell (Custom when null) as the button that calls [onTap].
class _LevelButton extends StatelessWidget {
  const _LevelButton(this.level, {required this.onTap});

  final int? level;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return DropCellButton(
      onTap: onTap,
      semanticLabel: s.ankirenAllLevels,
      label: PanelLabel(s.ankirenLevelRow, null),
      value: level == null
          ? Text(s.ankirenCustom,
              style: const TextStyle(fontFamily: Fonts.display, fontSize: AnkirenPageLayout.statUnitFont, height: 1))
          : NumberedText(
              s.ankirenLevelValue,
              [level!],
              style: const TextStyle(fontFamily: Fonts.display, fontSize: AnkirenPageLayout.statUnitFont, height: 1),
              numberStyle: const TextStyle(fontFamily: Fonts.display, fontSize: AnkirenPageLayout.statFont, height: 1),
            ),
    );
  }
}

/// What clears [setup]'s level (or that every level is, once [allCleared];
/// or that a custom setup is not scored), with a checked "Cleared" on the
/// right once it is [cleared]; or, when the known cards do not [fits] it,
/// how many it needs.
class _Hint extends StatelessWidget {
  const _Hint(this.setup, {required this.fits, required this.allCleared, required this.cleared});

  final AnkirenSetup setup;
  final bool fits, allCleared, cleared;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    const style = TextStyle(fontWeight: Weights.bold, fontSize: AnkirenPageLayout.hintFont, color: Palette.mute);
    const number = TextStyle(fontFamily: Fonts.display, fontSize: AnkirenPageLayout.hintNumber, color: Palette.ink);
    final Widget why;
    if (!fits) {
      why = Row(mainAxisSize: MainAxisSize.min, children: [
        MangaIcon(IconArt.lock,
            size: AnkirenPageLayout.hintIcon, color: Palette.mute, strokeWidth: AnkirenPageLayout.hintIconStroke),
        const SizedBox(width: AnkirenPageLayout.hintGap),
        Flexible(
          child: NumberedText(s.ankirenLevelFrom, [setup.level!, setup.calls], style: style, numberStyle: number),
        ),
      ]);
    } else if (allCleared) {
      why = Text(s.ankirenAllCleared, style: style);
    } else if (setup.custom) {
      why = Text.rich(Phrases.span(s.ankirenCustomNote), style: style);
    } else {
      why = Row(mainAxisSize: MainAxisSize.min, children: [
        const AnkirenStrikes(strikes: 1, count: 1, cardHeight: AnkirenPageLayout.hintCard),
        const SizedBox(width: AnkirenPageLayout.hintGap),
        Flexible(
          child: NumberedText(s.ankirenClearRule, [AnkirenTuning.strikesOut], style: style, numberStyle: number),
        ),
      ]);
    }
    return Padding(
      padding: AnkirenPageLayout.hintPadding,
      child: Row(children: [
        Expanded(child: Align(alignment: Alignment.centerLeft, child: why)),
        if (cleared) ...[
          const SizedBox(width: AnkirenPageLayout.hintGap),
          const ClearedCheck(size: AnkirenPageLayout.clearedCheck),
          const SizedBox(width: AnkirenPageLayout.hintGap),
          Text(s.ankirenClearedMark,
              style: const TextStyle(fontWeight: Weights.black, fontSize: AnkirenPageLayout.clearedFont)),
        ],
      ]),
    );
  }
}
