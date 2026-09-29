import 'package:flutter/material.dart';

import '../../config/design.dart';
import '../../l10n/home_strings.dart';
import '../../l10n/strings.dart';
import '../manga/manga.dart';
import '../run/run_launcher.dart';
import 'home_widgets.dart';

/// Asks before a guest run (which records nothing) and starts it on yes.
Future<void> confirmGuestRun(BuildContext context) async {
  final ok = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: S.of(context).cancel,
    barrierColor: GuestSheetStyle.barrier,
    transitionDuration: Motion.sheet,
    pageBuilder: (_, _, _) => const _GuestSheet(),
    transitionBuilder: (context, animation, _, child) {
      final t = CurvedAnimation(parent: animation, curve: Motion.routeCurve);
      return SlideTransition(
        position: Tween(begin: const Offset(0, 1), end: Offset.zero).animate(t),
        child: child,
      );
    },
  );
  if (ok == true && context.mounted) {
    await startGuest(context);
  }
}

class _GuestSheet extends StatelessWidget {
  const _GuestSheet();

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.all(Gaps.gutter),
          child: Material(
            type: MaterialType.transparency,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                MangaPanel(
                  shape: const PanelShape(topLeft: Offset(0, GuestSheetStyle.cut)),
                  padding: GuestSheetStyle.padding,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(children: [UntrackedLabel(s.untrackedTag)]),
                      const SizedBox(height: Gaps.small),
                      Text(
                        s.guestConfirmTitle,
                        style: const TextStyle(
                            fontFamily: Fonts.display, fontSize: GuestSheetStyle.title, height: TypeScale.displayLineHeight),
                      ),
                      const SizedBox(height: Gaps.section),
                      Text(
                        s.guestNote,
                        style: const TextStyle(
                          fontSize: GuestSheetStyle.body,
                          fontWeight: Weights.bold,
                          height: GuestSheetStyle.bodyLineHeight,
                        ),
                      ),
                      const SizedBox(height: Gaps.section),
                      SizedBox(
                        height: GuestSheetStyle.shoutHeight,
                        child: ShoutButton(
                          label: s.guestConfirm,
                          color: Palette.sun,
                          pressedColor: Palette.sunSoft,
                          onTap: () => Navigator.pop(context, true),
                        ),
                      ),
                      const SizedBox(height: Gaps.panel),
                      SizedBox(
                        height: GuestSheetStyle.cancelHeight,
                        child: InkButton(
                          onTap: () => Navigator.pop(context, false),
                          child: Text(s.cancel,
                              style: const TextStyle(fontWeight: Weights.black, fontSize: TypeScale.button)),
                        ),
                      ),
                    ],
                  ),
                ),
                const Placed(GuestSheetStyle.tobi, child: Tobi(pose: TobiPose.shocked)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
