import 'package:flutter/material.dart';

import '../../config/design.dart';
import '../../l10n/home_strings.dart';
import '../../l10n/strings.dart';
import '../../migrations/v3_to_v4.dart';
import '../../state/scope.dart';
import '../manga/manga.dart';
import '../side_trips/burst_button.dart';

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
  Widget build(BuildContext context) {
    final s = S.of(context);
    final tag = FittedBox(fit: BoxFit.scaleDown, child: InkBanner(title, fontSize: MigrationNoticeStyle.tagFont));
    const padding = MigrationNoticeStyle.panelPadding;
    return Semantics(
      scopesRoute: true,
      explicitChildNodes: true,
      child: ColoredBox(
        color: MigrationNoticeStyle.scrim,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: MigrationNoticeStyle.margin,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: MigrationNoticeStyle.maxWidth),
                child: Stack(clipBehavior: Clip.none, children: [
                  Padding(
                    padding: const EdgeInsets.only(top: MigrationNoticeStyle.tagRise),
                    child: MangaPanel(
                      shadow: MigrationNoticeStyle.panelShadow,
                      padding: padding,
                      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Overhang(
                              rise: MigrationNoticeStyle.tagRise + padding.top, child: ExcludeSemantics(child: tag)),
                        ),
                        const SizedBox(height: MigrationNoticeStyle.gap),
                        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                          SizedBox.fromSize(size: MigrationNoticeStyle.tobi, child: const Tobi(pose: TobiPose.tryHard)),
                          const SizedBox(width: MigrationNoticeStyle.gap),
                          Expanded(
                            child: Text.rich(Phrases.span(body),
                                style: const TextStyle(
                                    fontWeight: Weights.bold,
                                    fontSize: MigrationNoticeStyle.bodyFont,
                                    height: MigrationNoticeStyle.bodyLineHeight)),
                          ),
                        ]),
                        const SizedBox(height: MigrationNoticeStyle.gap),
                        BurstButton(title: s.noticeOk, onTap: onOk),
                      ]),
                    ),
                  ),
                  Positioned(
                    left: padding.left,
                    right: padding.right,
                    top: 0,
                    child: Align(alignment: Alignment.centerLeft, child: Semantics(header: true, child: tag)),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
