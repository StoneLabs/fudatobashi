import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../l10n/home_strings.dart';
import '../../l10n/strings.dart';
import '../../l10n/teiichi_strings.dart';
import '../../state/scope.dart';
import '../manga/manga.dart';
import '../shell/tobi_notice.dart';
import '../side_trips/burst_button.dart';

/// Tobi's tip on a portrait 定位置 game: turned sideways, the phone shows
/// the cards much bigger. It closes with OK, or with "Don't show again",
/// which keeps it from showing again (`AppSettings.teiichiTurnTipOff`).
Future<void> showTeiichiTurnTip(BuildContext context) {
  final progress = ProgressScope.read(context);
  return showTobiNotice(context, (context) {
    final s = S.of(context);
    void close({required bool never}) {
      if (never) unawaited(progress.updateSettings(progress.settings.copyWith(teiichiTurnTipOff: true)));
      Navigator.pop(context);
    }

    return TobiNotice(
      title: s.teiichiTurnTitle,
      body: s.teiichiTurnBody,
      pose: TobiPose.pointing,
      actions: [
        BurstButton(title: s.noticeOk, onTap: () => close(never: false)),
        TobiNoticeButton(label: s.teiichiTurnNever, onTap: () => close(never: true)),
      ],
    );
  });
}
