import 'package:flutter/material.dart';

import '../../config/design.dart';
import '../../l10n/home_strings.dart';
import '../../l10n/strings.dart';
import '../manga/manga.dart';

/// Tobi's gentle warning before "Learn next cards" while [shaky] cards are
/// not solid yet. Returns whether to go ahead; it never blocks.
Future<bool> confirmLearnWhileShaky(BuildContext context, int shaky) async {
  final ok = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: S.of(context).cancel,
    barrierColor: GuestSheetStyle.barrier,
    transitionDuration: Motion.sheet,
    pageBuilder: (_, _, _) => _ShakySheet(shaky),
    transitionBuilder: (context, animation, _, child) {
      final t = CurvedAnimation(parent: animation, curve: Motion.routeCurve);
      return SlideTransition(
        position: Tween(begin: const Offset(0, 1), end: Offset.zero).animate(t),
        child: child,
      );
    },
  );
  return ok == true;
}

class _ShakySheet extends StatelessWidget {
  const _ShakySheet(this.shaky);
  final int shaky;

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
                      Padding(
                        padding: EdgeInsets.only(right: GuestSheetStyle.tobi.size.width),
                        child: Text(
                          s.shakyTitle(shaky),
                          style: const TextStyle(
                              fontFamily: Fonts.display, fontSize: GuestSheetStyle.title, height: TypeScale.displayLineHeight),
                        ),
                      ),
                      const SizedBox(height: Gaps.section),
                      Text(
                        s.shakyNote,
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
                          label: s.shakyCancel,
                          color: Palette.pink,
                          pressedColor: Palette.pinkSoft,
                          onTap: () => Navigator.pop(context, false),
                        ),
                      ),
                      const SizedBox(height: Gaps.panel),
                      SizedBox(
                        height: GuestSheetStyle.cancelHeight,
                        child: InkButton(
                          color: Palette.sunSoft,
                          onTap: () => Navigator.pop(context, true),
                          child: Text(s.shakyConfirm,
                              style: const TextStyle(fontWeight: Weights.black, fontSize: TypeScale.button)),
                        ),
                      ),
                    ],
                  ),
                ),
                const Placed(GuestSheetStyle.tobi, child: Tobi(pose: TobiPose.pointing)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
