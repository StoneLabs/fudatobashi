import 'package:flutter/material.dart';

import '../../config/design.dart';
import '../../db/database.dart' show IkkiuchiMatchRow, IkkiuchiReadRow;
import '../../domain/ikkiuchi_cards.dart';
import '../../l10n/history_strings.dart';
import '../../l10n/ikkiuchi_strings.dart';
import '../../l10n/side_trip_strings.dart';
import '../../l10n/strings.dart';
import '../../state/scope.dart';
import '../manga/manga.dart';
import '../play/time_format.dart';
import 'ankiren_widgets.dart';
import 'history_widgets.dart';
import 'review_parts.dart';
import 'run_page.dart';

/// Opens 一騎打ち match [match]'s page.
Future<void> openIkkiuchiMatch(BuildContext context, IkkiuchiMatchRow match) =>
    Navigator.of(context).push(MangaRoute<void>(builder: (_) => IkkiuchiMatchPage(match: match)));

/// A recorded 一騎打ち match: its header names the setup; then how it
/// ended, the cards left and faults on each side and how long it took;
/// then every read in order, read from the database as the page opens.
class IkkiuchiMatchPage extends StatefulWidget {
  const IkkiuchiMatchPage({super.key, required this.match});
  final IkkiuchiMatchRow match;

  @override
  State<IkkiuchiMatchPage> createState() => _IkkiuchiMatchPageState();
}

class _IkkiuchiMatchPageState extends State<IkkiuchiMatchPage> {
  late final Future<List<IkkiuchiReadRow>> _reads = ProgressScope.read(context).ikkiuchiReadsOf(widget.match.id);

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final match = widget.match;
    final setup = s.ikkiuchiSetupLine(
        match.perSide, formatMinutes(Duration(milliseconds: match.memoriseMs)), match.tobiRating.round());
    return RunPageFrame(
      title: s.hallName,
      sub: [s.other.hallName, s.freePlay, s.sessionDate(match.startedAt), setup].join(' · '),
      shortSub: [s.other.hallName, s.freePlay, s.sessionDay(match.startedAt)].join(' · '),
      body: FutureBuilder(
        future: _reads,
        builder: (context, snap) => ReviewColumn(
          fillMinHeight: 0,
          fill: switch (snap.data) {
            final reads? => _Reads(reads),
            null => const SizedBox(),
          },
          children: [_Summary(match)],
        ),
      ),
    );
  }
}

/// How the match ended, the cards left and faults on each side, and how
/// long it took.
class _Summary extends StatelessWidget {
  const _Summary(this.match);
  final IkkiuchiMatchRow match;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return ReviewSlab(
      flatTop: true,
      child: FactGrid(perRow: IkkiuchiHistoryStyle.factsPerRow, [
        Fact(s.ikkiuchiResult(match.result), s.ikkiuchiResultLabel),
        Fact('${match.playerLeft}', s.ikkiuchiYourLeft),
        Fact('${match.tobiLeft}', s.ikkiuchiTobiLeft),
        Fact(formatMinutes(match.endedAt.difference(match.startedAt)), s.ikkiuchiMatchTime),
        Fact('${match.playerFaults}', s.ikkiuchiYourFaults),
        Fact('${match.tobiFaults}', s.ikkiuchiTobiFaults),
      ]),
    );
  }
}

/// Every read in order: its card (tagged when a からふだ), who took it and
/// whether it was a tie, and each side's time from the deciding sound
/// with its faults under it. Rows Tobi took are marked.
class _Reads extends StatelessWidget {
  const _Reads(this.reads);
  final List<IkkiuchiReadRow> reads;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    Widget side(int? us, int faults) => _Stacked(
          ReviewTable.cell(us == null ? missingTime : '${formatSeconds(us / Duration.microsecondsPerMillisecond)}s'),
          faults == 0 ? null : s.ikkiuchiFaultCount(faults),
          HistoryRunStyle.behind,
          end: true,
        );
    Widget taken(IkkiuchiReadRow r) => _Stacked(
          ReviewTable.cell(
              switch (r.taker) {
                IkkiuchiSide.player => s.ikkiuchiYou,
                IkkiuchiSide.tobi => s.ikkiuchiTobi,
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
                  for (final r in reads)
                    ReviewRow(
                      [
                        ReviewTable.cell('${r.seq + 1}'),
                        _Stacked(ReviewTable.cell(kimarijiFor(context, r.poemId), strong: true),
                            r.karafuda ? s.ikkiuchiKarafuda : null, KarafudaStyle.tag),
                        taken(r),
                        side(r.playerUs, r.playerFaults),
                        side(r.tobiUs, r.tobiFaults),
                      ],
                      marked: r.taker == IkkiuchiSide.tobi,
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
