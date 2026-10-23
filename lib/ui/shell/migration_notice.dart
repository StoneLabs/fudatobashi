import 'package:flutter/material.dart';

import '../../l10n/home_strings.dart';
import '../../l10n/strings.dart';
import '../../migrations/v3_to_v4.dart';
import '../../state/scope.dart';
import '../side_trips/burst_button.dart';
import 'tobi_notice.dart';

/// The l10n keys of each notice an upgrade can queue (see `queueNotice`): to
/// add one, queue its id in the upgrade step and add its pair here.
const _noticeTexts = {
  ankirenReworkNotice: (title: 'noticeAnkirenReworkTitle', body: 'noticeAnkirenReworkBody'),
};

/// The first notice an upgrade queued that has not been dismissed, over
/// everything; dismissing it shows the next one.
class MigrationNoticeOverlay extends StatelessWidget {
  const MigrationNoticeOverlay({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final texts = _noticeTexts[id];
    if (texts == null) return const SizedBox.shrink();
    return MigrationNotice(
      key: ValueKey(id),
      title: s.t(texts.title),
      body: s.t(texts.body),
      onOk: () => ProgressScope.read(context).dismissNotice(id),
    );
  }
}

/// A message from the app: a [title] on an ink tag over the panel's top
/// edge, Tobi with the [body] and an OK shout, on a dimmed screen.
class MigrationNotice extends StatelessWidget {
  const MigrationNotice({super.key, required this.title, required this.body, required this.onOk});

  final String title, body;
  final VoidCallback onOk;

  @override
  Widget build(BuildContext context) =>
      TobiNotice(title: title, body: body, actions: [BurstButton(title: S.of(context).noticeOk, onTap: onOk)]);
}
