import 'package:flutter/material.dart';

import '../../config/design.dart';
import '../../domain/ikkiuchi_record.dart';
import '../../domain/ikkiuchi_side.dart';
import '../../l10n/history_strings.dart';
import '../../l10n/ikkiuchi_strings.dart';
import '../../l10n/side_trip_strings.dart';
import '../../l10n/strings.dart';
import '../manga/manga.dart';
import '../play/time_format.dart';
import 'ankiren_widgets.dart';
import 'history_widgets.dart';
import 'review_parts.dart';
import 'run_page.dart';

/// Opens 一騎打ち match [match]'s page.
Future<void> openIkkiuchiMatch(BuildContext context, IkkiuchiMatchRecord match) =>
    Navigator.of(context).push(MangaRoute<void>(builder: (_) => IkkiuchiMatchPage(match: match)));

/// A recorded 一騎打ち match: its header names its kind and setup; then how
/// it ended, the cards left and faults on each side and how long it took;
/// then every read in order.
class IkkiuchiMatchPage extends StatelessWidget {
  const IkkiuchiMatchPage({super.key, required this.match});
  final IkkiuchiMatchRecord match;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final setup = match.setup;
    final kind = match.ranked ? s.sideTripRanked : s.freePlay;
    final line = s.ikkiuchiSetupLine(setup.perSide, formatMinutes(setup.memorise), setup.opponentRating.round());
    return RunPageFrame(
      title: s.hallName,
      sub: [s.other.hallName, kind, s.sessionDate(match.startedAt), line].join(' · '),
      shortSub: [s.other.hallName, kind, s.sessionDay(match.startedAt)].join(' · '),
      body: ReviewColumn(fillMinHeight: 0, fill: _Reads(match.reads), children: [_Summary(match)]),
    );
  }
}

/// How the match ended, the cards left and faults on each side, and how
/// long it took.
class _Summary extends StatelessWidget {
  const _Summary(this.match);
  final IkkiuchiMatchRecord match;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return ReviewSlab(
      flatTop: true,
      child: FactGrid(perRow: IkkiuchiHistoryStyle.factsPerRow, [
        Fact(s.ikkiuchiResult(match.result), s.ikkiuchiResultLabel),
        Fact('${match.playerLeft}', s.ikkiuchiYourLeft),
        Fact('${match.opponentLeft}', s.ikkiuchiTobiLeft),
        Fact(formatMinutes(match.endedAt.difference(match.startedAt)), s.ikkiuchiMatchTime),
        Fact('${match.playerFaults}', s.ikkiuchiYourFaults),
        Fact('${match.opponentFaults}', s.ikkiuchiTobiFaults),
      ]),
    );
  }
}

/// Every read in order: its card (tagged when a からふだ), who took it and
/// whether it was a tie, and each side's time from the deciding sound
/// with its faults under it. Rows Tobi took are marked.
class _Reads extends StatelessWidget {
  const _Reads(this.reads);
  final List<IkkiuchiReadLog> reads;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    Widget side(Duration? take, int faults) => _Stacked(
          ReviewTable.cell(take == null
              ? missingTime
              : '${formatSeconds(take.inMicroseconds / Duration.microsecondsPerMillisecond)}s'),
          faults == 0 ? null : s.ikkiuchiFaultCount(faults),
          HistoryRunStyle.behind,
          end: true,
        );
    Widget taken(IkkiuchiReadLog r) => _Stacked(
          ReviewTable.cell(
              switch (r.taker) {
                IkkiuchiSide.player => s.ikkiuchiYou,
                IkkiuchiSide.opponent => s.ikkiuchiTobi,
                null => missingTime,
              },
              strong: true),
          r.tied ? s.ikkiuchiTied : null,
          Palette.ink,
        );
    return ReviewSlab(
      title: s.ikkiuchiReadsTitle,
      sub: s.sub?.ikkiuchiReadsTitle,
      note: s.ikkiuchiReadsNote(reads.length),
      flatBottom: true,
      expands: true,
      child: reads.isEmpty
          ? Text(s.ikkiuchiNoReads, style: ReviewTextStyle.caption)
          : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              ReviewTable(
                leading: 3,
                inkHead: true,
                stretch: 1,
                head: [s.ikkiuchiColNumber, s.ikkiuchiColCard, s.ikkiuchiColTaken, s.ikkiuchiYou, s.ikkiuchiTobi],
                rows: [
                  for (final (i, r) in reads.indexed)
                    ReviewRow(
                      [
                        ReviewTable.cell('${i + 1}'),
                        _Stacked(ReviewTable.cell(kimarijiFor(context, r.poemId), strong: true),
                            r.karafuda ? s.ikkiuchiKarafuda : null, KarafudaStyle.tag),
                        taken(r),
                        side(r.playerTake, r.playerFaults),
                        side(r.opponentTake, r.opponentFaults),
                      ],
                      marked: r.taker == IkkiuchiSide.opponent,
                    ),
                ],
              ),
              const SizedBox(height: Gaps.panel),
              Text(s.ikkiuchiReadsCaption, style: ReviewTextStyle.caption),
            ]),
    );
  }
}

/// A table cell's [main] part, with a small [tag] in [color] under it
/// when there is one, both to the cell's start or, in a number's column,
/// its [end].
class _Stacked extends StatelessWidget {
  const _Stacked(this.main, this.tag, this.color, {this.end = false});
  final Widget main;
  final String? tag;
  final Color color;
  final bool end;

  @override
  Widget build(BuildContext context) {
    final tag = this.tag;
    if (tag == null) return main;
    return Column(
      crossAxisAlignment: end ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        main,
        Text(tag.toUpperCase(), maxLines: 1, style: ReviewTableStyle.head.copyWith(color: color)),
      ],
    );
  }
}
