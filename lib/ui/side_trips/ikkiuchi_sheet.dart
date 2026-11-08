import 'package:flutter/material.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../domain/ikkiuchi_record.dart';
import '../../domain/rating.dart';
import '../../l10n/free_strings.dart';
import '../../l10n/ikkiuchi_strings.dart';
import '../../l10n/ranked_strings.dart';
import '../../l10n/strings.dart';
import '../ikkiuchi/ikkiuchi_match_screen.dart';
import '../manga/manga.dart';
import '../play/time_format.dart';
import 'burst_button.dart';
import 'trip_sheet.dart';

/// 一騎打ち's custom sheet, opened on [current]: the setup confirmed, or null
/// when it is closed.
Future<IkkiuchiSetup?> pickIkkiuchiCustom(BuildContext context, IkkiuchiSetup current) =>
    showMangaSheet<IkkiuchiSetup>(
      context,
      barrierColor: IkkiuchiSheetLayout.barrier,
      barrierLabel: S.of(context).cancel,
      builder: (_) => IkkiuchiCustomSheet(initial: current),
    );

/// The guest's last setup, while the app runs.
IkkiuchiSetup _guestSetup = IkkiuchiSetup.firstFree;

/// Guest mode: the custom sheet on the guest's last setup, then a match
/// that records nothing.
Future<void> openIkkiuchiGuest(BuildContext context) async {
  final setup = await showMangaSheet<IkkiuchiSetup>(
    context,
    barrierColor: IkkiuchiSheetLayout.barrier,
    barrierLabel: S.of(context).cancel,
    builder: (_) => IkkiuchiCustomSheet(initial: _guestSetup, guest: true),
  );
  if (setup == null || !context.mounted) return;
  _guestSetup = setup;
  await startIkkiuchiMatch(context, setup, guest: true);
}

/// A custom match's setup, from [initial]: Tobi's rating, a key for each
/// of [IkkiuchiFreeTuning.ratingClasses] (its class's threshold on the
/// shared class scale) over a stepper for any rating; the cards a side,
/// keys over a stepper; and the memory time, a stepper. Each stepper's
/// button held down steps on. Then the setup in a line, and the burst,
/// Confirm (Start for a [guest]), which closes the sheet with the setup.
class IkkiuchiCustomSheet extends StatefulWidget {
  const IkkiuchiCustomSheet({super.key, required this.initial, this.guest = false});

  final IkkiuchiSetup initial;
  final bool guest;

  @override
  State<IkkiuchiCustomSheet> createState() => _IkkiuchiCustomSheetState();
}

class _IkkiuchiCustomSheetState extends State<IkkiuchiCustomSheet> {
  late int _perSide = widget.initial.perSide.clamp(IkkiuchiFreeTuning.perSideMin, IkkiuchiFreeTuning.perSideMax);
  late Duration _memorise = _clampMemorise(widget.initial.memorise);
  late double _rating = _clampRating(widget.initial.opponentRating);

  static Duration _clampMemorise(Duration d) => Duration(
      microseconds: d.inMicroseconds.clamp(
          IkkiuchiFreeTuning.memoriseMin.inMicroseconds, IkkiuchiFreeTuning.memoriseMax.inMicroseconds));

  static double _clampRating(double r) => r.clamp(IkkiuchiFreeTuning.ratingMin, IkkiuchiFreeTuning.ratingMax);

  /// The rating a class's key sets: its threshold, held in Tobi's range.
  static double _ratingOf(RankBand band) => _clampRating(band.minRating.roundToDouble());

  IkkiuchiSetup get _setup =>
      IkkiuchiSetup.free(opponentRating: _rating, perSide: _perSide, memorise: _memorise);

  void _change(VoidCallback change) => setState(change);

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final o = s.sub;
    const value = TextStyle(fontFamily: Fonts.display, fontSize: IkkiuchiSheetLayout.valueFont);
    const unit = TextStyle(fontWeight: Weights.black, fontSize: IkkiuchiSheetLayout.unitFont);
    const keyTop = TextStyle(fontFamily: Fonts.display, fontSize: IkkiuchiSheetLayout.keyFont);
    const keySub = TextStyle(fontWeight: Weights.black, fontSize: IkkiuchiSheetLayout.keySubFont, color: Palette.mute);
    const every = IkkiuchiSheetLayout.repeatEvery;
    final bands = [
      for (final id in IkkiuchiFreeTuning.ratingClasses) Rating.bands.firstWhere((b) => b.id == id),
    ];
    Widget section(String label, String? sub, List<Widget> children) =>
        Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SheetLabel(label, sub),
          for (final child in children) ...[const SizedBox(height: IkkiuchiSheetLayout.sectionGap), child],
        ]);
    return TripSheet(
      title: widget.guest ? s.ikkiuchiGuestMode : s.ikkiuchiCustom,
      sub: widget.guest ? o?.ikkiuchiGuestMode : o?.ikkiuchiCustom,
      line: widget.guest ? s.ikkiuchiGuestLine : null,
      body: [
        section(s.ikkiuchiTobiRating, o?.ikkiuchiTobiRating, [
          SheetKeyGrid(perRow: bands.length, [
            for (final band in bands)
              SheetKey(
                semanticLabel: '${s.className(band)} ${_ratingOf(band).round()}',
                chosen: _rating == _ratingOf(band),
                fits: true,
                locked: false,
                cleared: false,
                onTap: () => _change(() => _rating = _ratingOf(band)),
                top: Text(s.className(band), style: keyTop),
                bottom: Text('${_ratingOf(band).round()}', style: keySub),
              ),
          ]),
          SheetStepper(
            label: SheetLabel(s.ikkiuchiAnyRating, null),
            value: Text('${_rating.round()}', style: value),
            repeatEvery: every,
            onLess: _rating > IkkiuchiFreeTuning.ratingMin
                ? () => _change(() => _rating = _clampRating(_rating - IkkiuchiFreeTuning.ratingStep))
                : null,
            onMore: _rating < IkkiuchiFreeTuning.ratingMax
                ? () => _change(() => _rating = _clampRating(_rating + IkkiuchiFreeTuning.ratingStep))
                : null,
          ),
        ]),
        section(s.ikkiuchiCardsPerSide, o?.ikkiuchiCardsPerSide, [
          SheetKeyGrid(perRow: IkkiuchiFreeTuning.perSideKeys.length, [
            for (final n in IkkiuchiFreeTuning.perSideKeys)
              SheetKey(
                semanticLabel: '$n',
                chosen: _perSide == n,
                fits: true,
                locked: false,
                cleared: false,
                onTap: () => _change(() => _perSide = n),
                top: Text('$n', style: keyTop),
              ),
          ]),
          SheetStepper(
            label: SheetLabel(s.ikkiuchiAnyCount, null),
            value: NumberedText(s.ikkiuchiPerSideCount, [_perSide], style: unit, numberStyle: value),
            repeatEvery: every,
            onLess: _perSide > IkkiuchiFreeTuning.perSideMin
                ? () => _change(() => _perSide -= IkkiuchiFreeTuning.perSideStep)
                : null,
            onMore: _perSide < IkkiuchiFreeTuning.perSideMax
                ? () => _change(() => _perSide += IkkiuchiFreeTuning.perSideStep)
                : null,
          ),
        ]),
        SheetStepper(
          label: SheetLabel(s.ikkiuchiMemoryTime, null),
          value: Text(formatMinutes(_memorise), style: value),
          repeatEvery: every,
          onLess: _memorise > IkkiuchiFreeTuning.memoriseMin
              ? () => _change(() => _memorise -= IkkiuchiFreeTuning.memoriseStep)
              : null,
          onMore: _memorise < IkkiuchiFreeTuning.memoriseMax
              ? () => _change(() => _memorise += IkkiuchiFreeTuning.memoriseStep)
              : null,
        ),
        Text(
          s.ikkiuchiSetupLine(_perSide, formatMinutes(_memorise), _rating.round()),
          style: const TextStyle(fontWeight: Weights.black, fontSize: IkkiuchiSheetLayout.factsFont),
        ),
      ],
      footer: BurstButton(
        title: widget.guest ? s.freeStart : s.ikkiuchiConfirm,
        sub: (widget.guest ? o?.freeStart : o?.ikkiuchiConfirm)?.toUpperCase(),
        onTap: () => Navigator.pop(context, _setup),
      ),
    );
  }
}
