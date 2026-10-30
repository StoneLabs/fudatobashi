import 'package:flutter/material.dart';

import '../../l10n/home_strings.dart';
import '../../l10n/reminder_strings.dart';
import '../../l10n/strings.dart';
import '../../state/reminders.dart';
import '../../state/scope.dart';
import '../manga/manga.dart';
import '../shell/tobi_notice.dart';
import '../side_trips/burst_button.dart';

/// Tobi offers the daily reminders, over Results (see [remindersOfferDue]).
/// "Yes" asks for the permission to notify and turns them on; if the phone
/// refuses, the offer gives way to [RemindersBlocked]. [onDone] once the
/// player is through.
class ReminderOffer extends StatefulWidget {
  const ReminderOffer({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<ReminderOffer> createState() => _ReminderOfferState();
}

class _ReminderOfferState extends State<ReminderOffer> {
  /// The system is asking for the permission: the buttons wait.
  bool _asking = false;
  bool _blocked = false;

  Future<void> _yes() async {
    setState(() => _asking = true);
    final on = await reminders.turnOn(ProgressScope.read(context));
    if (!mounted) return;
    if (on) {
      widget.onDone();
    } else {
      setState(() => _blocked = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_blocked) return RemindersBlocked(onOk: widget.onDone);
    final s = S.of(context);
    return TobiNotice(
      title: s.reminderOfferTitle,
      body: s.reminderOfferBody,
      note: s.reminderOfferNote,
      pose: TobiPose.waving,
      actions: [
        BurstButton(title: s.reminderOfferYes, onTap: _asking ? null : _yes),
        TobiNoticeButton(label: s.reminderOfferNo, onTap: _asking ? null : widget.onDone),
      ],
    );
  }
}

/// The phone doesn't let the app notify, so reminders stay off: how to
/// allow them, with a way to the phone's settings.
class RemindersBlocked extends StatelessWidget {
  const RemindersBlocked({super.key, required this.onOk});

  final VoidCallback onOk;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return TobiNotice(
      title: s.reminderBlockedTitle,
      body: s.reminderBlockedBody,
      pose: TobiPose.relaxed,
      actions: [
        BurstButton(title: s.noticeOk, onTap: onOk),
        TobiNoticeButton(label: s.reminderBlockedOpen, onTap: reminders.openSettings),
      ],
    );
  }
}

/// Shows [RemindersBlocked] over the screen until the player is through.
Future<void> showRemindersBlocked(BuildContext context) =>
    showTobiNotice(context, (context) => RemindersBlocked(onOk: () => Navigator.pop(context)));
