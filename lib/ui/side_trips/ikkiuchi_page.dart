import 'package:flutter/material.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../config/vector_art.dart';
import '../../domain/ikkiuchi_record.dart';
import '../../l10n/ikkiuchi_strings.dart';
import '../../l10n/side_trip_strings.dart';
import '../../l10n/strings.dart';
import '../../state/ikkiuchi_records.dart';
import '../../state/scope.dart';
import '../ikkiuchi/ikkiuchi_match_screen.dart';
import '../manga/manga.dart';
import '../play/time_format.dart';
import 'ankiren_sheet.dart';
import 'burst_button.dart';
import 'side_trip_panels.dart';

/// Opens 一騎打ち's page ([IkkiuchiPage]).
Future<void> openIkkiuchiPage(BuildContext context) =>
    Navigator.of(context).push(MangaRoute<void>(builder: (_) => const IkkiuchiPage()));

/// 一騎打ち's page, on the side trips' page frame: the matches played, won
/// and lost; ranked, chained up as coming soon; then free play's setup,
/// the cards each side is dealt, the memory time and Tobi's rating, each a
/// stepper through its choices ([IkkiuchiFreeTuning]), and the burst that
/// starts a match. The setup starts as the last match's, or the first
/// match's choices before any. Home's dotted ground, in the sea's blue,
/// lies behind the panels; the page scrolls when it is taller than the
/// screen.
class IkkiuchiPage extends StatefulWidget {
  const IkkiuchiPage({super.key});

  @override
  State<IkkiuchiPage> createState() => _IkkiuchiPageState();
}

class _IkkiuchiPageState extends State<IkkiuchiPage> {
  late int _perSide, _memorise, _rating;

  static int _nearest<T>(List<T> choices, double Function(T) value, double to) {
    var best = 0;
    for (final (i, c) in choices.indexed) {
      if ((value(c) - to).abs() < (value(choices[best]) - to).abs()) best = i;
    }
    return best;
  }

  @override
  void initState() {
    super.initState();
    final last = ProgressScope.read(context).ikkiuchi.last;
    final setup = last == null ? IkkiuchiSetup.first : IkkiuchiRecords.setupOf(last);
    _perSide = _nearest(IkkiuchiFreeTuning.perSideChoices, (n) => n.toDouble(), setup.perSide.toDouble());
    _memorise = _nearest(
        IkkiuchiFreeTuning.memoriseChoices, (d) => d.inSeconds.toDouble(), setup.memorise.inSeconds.toDouble());
    _rating = _nearest(IkkiuchiFreeTuning.ratingChoices, (r) => r, setup.rating);
  }

  IkkiuchiSetup get _setup => IkkiuchiSetup(
        perSide: IkkiuchiFreeTuning.perSideChoices[_perSide],
        memorise: IkkiuchiFreeTuning.memoriseChoices[_memorise],
        rating: IkkiuchiFreeTuning.ratingChoices[_rating],
      );

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final matches = ProgressScope.of(context).ikkiuchi.matches;
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
                        InkIconButton(icon: IconArt.back, semanticLabel: s.back, onTap: () => Navigator.maybePop(context)),
                      ],
                    ),
                    const SizedBox(height: IkkiuchiPageLayout.gap),
                    _Strip(
                      played: matches.length,
                      won: matches.where((m) => m.result == IkkiuchiResult.won).length,
                    ),
                    const SizedBox(height: IkkiuchiPageLayout.panelTop),
                    const _RankedPanel(),
                    const SizedBox(height: IkkiuchiPageLayout.panelTop),
                    const Spacer(),
                    _FreePanel(
                      setup: _setup,
                      onPerSide: _step(IkkiuchiFreeTuning.perSideChoices.length, _perSide, (i) => _perSide = i),
                      onMemorise: _step(IkkiuchiFreeTuning.memoriseChoices.length, _memorise, (i) => _memorise = i),
                      onRating: _step(IkkiuchiFreeTuning.ratingChoices.length, _rating, (i) => _rating = i),
                    ),
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

  /// A stepper's two moves through [count] choices from [at], each null at
  /// its end.
  ({VoidCallback? less, VoidCallback? more}) _step(int count, int at, void Function(int) set) => (
        less: at > 0 ? () => setState(() => set(at - 1)) : null,
        more: at < count - 1 ? () => setState(() => set(at + 1)) : null,
      );
}

/// The page's strip: the matches played, won and lost, a match given up
/// counting as lost.
class _Strip extends StatelessWidget {
  const _Strip({required this.played, required this.won});

  final int played, won;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    const big = StatStrip.valueStyle;
    return StatStrip(
      fills: true,
      cells: [
        StatCell(label: PanelLabel(s.ikkiuchiPlayed, null), value: Text('$played', style: big)),
        StatCell(label: PanelLabel(s.ikkiuchiWon, null), value: Text('$won', style: big)),
        StatCell(label: PanelLabel(s.ikkiuchiLost, null), value: Text('${played - won}', style: big)),
      ],
    );
  }
}

/// Ranked, shut for now: what it will hold over the ranked burst, chained
/// up, saying it is coming soon.
class _RankedPanel extends StatelessWidget {
  const _RankedPanel();

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return LockedPanel(
      tag: s.sideTripRanked,
      sub: s.sub?.sideTripRanked,
      why: s.ikkiuchiRankedSoon,
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
          padding: IkkiuchiPageLayout.rankedLinePadding,
          child: Text(s.ikkiuchiRankedLine,
              style: const TextStyle(fontWeight: Weights.bold, fontSize: IkkiuchiPageLayout.rankedLineFont)),
        ),
        const RankedRow(onTap: null),
      ]),
    );
  }
}

/// Free play: a stepper each for the cards a side, the memory time and
/// Tobi's rating, then the burst that starts a match of [setup].
class _FreePanel extends StatelessWidget {
  const _FreePanel({required this.setup, required this.onPerSide, required this.onMemorise, required this.onRating});

  final IkkiuchiSetup setup;
  final ({VoidCallback? less, VoidCallback? more}) onPerSide, onMemorise, onRating;

  static const _value = TextStyle(fontFamily: Fonts.display, fontSize: IkkiuchiPageLayout.stepperValueFont);

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    Widget stepper(String label, String value, ({VoidCallback? less, VoidCallback? more}) on) => SheetStepper(
          label: SheetLabel(label, null),
          value: Text(value, style: _value),
          onLess: on.less,
          onMore: on.more,
        );
    return TaggedPanel(
      tag: s.freePlay,
      sub: s.sub?.freePlay,
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
          padding: IkkiuchiPageLayout.steppersPadding,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            stepper(s.ikkiuchiCards, '${setup.perSide}', onPerSide),
            const SizedBox(height: IkkiuchiPageLayout.stepperGap),
            stepper(s.ikkiuchiMemoryTime, formatMinutes(setup.memorise), onMemorise),
            const SizedBox(height: IkkiuchiPageLayout.stepperGap),
            stepper(s.ikkiuchiTobiRating, '${setup.rating.round()}', onRating),
          ]),
        ),
        Padding(
          padding: IkkiuchiPageLayout.burstMargin,
          child: BurstButton(title: s.ikkiuchiStart, onTap: () => startIkkiuchiMatch(context, setup)),
        ),
      ]),
    );
  }
}
