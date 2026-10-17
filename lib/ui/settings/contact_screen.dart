import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/design.dart';
import '../../config/links.dart';
import '../../config/vector_art.dart';
import '../../l10n/credits_strings.dart';
import '../../l10n/strings.dart';
import '../manga/manga.dart';
import 'settings_rows.dart';

/// "Contact the developer", from About: issues and ideas go to GitHub,
/// anything else by email, with the address to copy or write to.
class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final o = s.sub;
    final issues = Uri.parse(Links.issues);
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: HeaderStyle.topGap),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Gaps.gutter),
              child: MangaHeader(
                title: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: ScreenTitle(s.contactTitle, sub: s.other.contactTitle),
                ),
                actions: [
                  InkIconButton(icon: IconArt.back, semanticLabel: s.back, onTap: () => Navigator.maybePop(context)),
                ],
              ),
            ),
            const SizedBox(height: Gaps.section),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(Gaps.gutter, Gaps.tight, Gaps.gutter, ProseLayout.bottomPad),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: Gaps.small),
                      child: MarkerHeading(s.contactIssues, o?.contactIssues),
                    ),
                    ProseBody(s.contactIssuesBody),
                    const SizedBox(height: ProseLayout.actionGap),
                    SettingsGroup(children: [
                      SettingsTapRow(
                        title: s.contactOpenIssues,
                        note: '${issues.host}${issues.path}',
                        opensPage: true,
                        onTap: () => _open(context, issues, fallback: Links.issues, failed: s.contactBrowserFailed),
                      ),
                    ]),
                    const SizedBox(height: MarkerHeadingStyle.sectionGap),
                    Padding(
                      padding: const EdgeInsets.only(bottom: Gaps.small),
                      child: MarkerHeading(s.contactEmail, o?.contactEmail),
                    ),
                    ProseBody(s.contactEmailBody),
                    const SizedBox(height: ProseLayout.actionGap),
                    SettingsGroup(children: [
                      SettingsTapRow(
                        title: s.contactCopyEmail,
                        note: Links.developerEmail,
                        onTap: () => _copy(context, Links.developerEmail, s.contactEmailCopied),
                      ),
                      SettingsTapRow(
                        title: s.contactWriteEmail,
                        opensPage: true,
                        onTap: () => _open(context, Uri.parse(Links.developerMailto),
                            fallback: Links.developerEmail, failed: s.contactMailFailed),
                      ),
                    ]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _copy(BuildContext context, String text, String done) async {
  await Clipboard.setData(ClipboardData(text: text));
  if (context.mounted) MangaToast.show(context, done);
}

/// Opens [uri] in another app; when none takes it, copies [fallback]
/// instead and says so with [failed].
Future<void> _open(BuildContext context, Uri uri, {required String fallback, required String failed}) async {
  bool opened;
  try {
    opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
  } on PlatformException {
    opened = false;
  }
  if (!opened && context.mounted) await _copy(context, fallback, failed);
}
