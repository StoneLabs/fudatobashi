import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../../config/design.dart';
import '../../config/licenses.dart';
import '../../config/vector_art.dart';
import '../../l10n/credits_strings.dart';
import '../../l10n/strings.dart';
import '../manga/manga.dart';

/// Attribution for everything third-party this app bundles: fonts, the
/// pre-rendered torifuda kana, sound effects, the poem dataset, its
/// inspiration and (via `showLicensePage`) every pub package it depends on.
class CreditsScreen extends StatelessWidget {
  const CreditsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Gaps.gutter),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: HeaderStyle.topGap),
              MangaHeader(
                title: ScreenTitle(s.credits, sub: s.other.credits),
                actions: [
                  InkIconButton(icon: IconArt.back, semanticLabel: s.back, onTap: () => Navigator.maybePop(context)),
                ],
              ),
              const SizedBox(height: Gaps.section),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Section(
                        title: s.creditsFonts,
                        children: [for (final f in fontCredits) _FontRow(credit: f)],
                      ),
                      const SizedBox(height: Gaps.section),
                      _Section(
                        title: s.creditsCardKana,
                        children: [NarrationBox(child: Text(s.creditsCardKanaBody))],
                      ),
                      const SizedBox(height: Gaps.section),
                      _Section(
                        title: s.creditsSounds,
                        children: [
                          NarrationBox(child: Text(s.creditsSoundsBody)),
                          const SizedBox(height: Gaps.small),
                          _TapRow(
                            title: s.creditsViewLicense,
                            onTap: () => Navigator.push(
                              context,
                              MangaRoute<void>(builder: (_) => LicenseTextScreen(title: s.creditsSounds, asset: soundsLicenseAsset)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: Gaps.section),
                      _Section(
                        title: s.creditsMusic,
                        children: [
                          NarrationBox(child: Text(s.creditsMusicBody)),
                          const SizedBox(height: Gaps.small),
                          _TapRow(
                            title: s.creditsViewLicense,
                            onTap: () => Navigator.push(
                              context,
                              MangaRoute<void>(builder: (_) => LicenseTextScreen(title: s.creditsMusic, asset: musicLicenseAsset)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: Gaps.section),
                      _Section(
                        title: s.creditsVoice,
                        children: [NarrationBox(child: Text(s.creditsVoiceBody))],
                      ),
                      const SizedBox(height: Gaps.section),
                      _Section(
                        title: s.creditsPoemData,
                        children: [NarrationBox(child: Text(s.creditsPoemDataBody))],
                      ),
                      const SizedBox(height: Gaps.section),
                      _Section(
                        title: s.creditsInspiration,
                        children: [NarrationBox(child: Text(s.creditsInspirationBody))],
                      ),
                      const SizedBox(height: Gaps.section),
                      _Section(
                        title: s.creditsOpenSource,
                        children: [
                          NarrationBox(child: Text(s.creditsOpenSourceBody)),
                          const SizedBox(height: Gaps.small),
                          _TapRow(
                            title: s.creditsViewPackages,
                            onTap: () => showLicensePage(context: context, applicationName: 'Fudatobashi'),
                          ),
                        ],
                      ),
                      const SizedBox(height: Gaps.section),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: Gaps.small),
            child: Text(title, style: const TextStyle(fontWeight: Weights.black, fontSize: TypeScale.button)),
          ),
          for (final (i, child) in children.indexed) ...[
            if (i > 0) const SizedBox(height: Gaps.tight),
            child,
          ],
        ],
      );
}

/// A tappable row: a title (and optional subtitle) on the left, a chevron on
/// the right. Sized to its content so a wrapped subtitle never overflows at a
/// larger font scale.
class _TapRow extends StatelessWidget {
  const _TapRow({required this.title, this.subtitle, required this.onTap});
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
        constraints: const BoxConstraints(minHeight: ButtonMetrics.rowHeight),
        child: InkButton(
          onTap: onTap,
          padding: const EdgeInsets.symmetric(horizontal: Gaps.inner, vertical: Gaps.small),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: Weights.black, fontSize: TypeScale.button)),
                    if (subtitle != null) ...[
                      const SizedBox(height: CreditsLayout.rowSubtitleGap),
                      Text(subtitle!,
                          style: const TextStyle(fontWeight: Weights.bold, fontSize: TypeScale.small, color: Palette.inkSoft)),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: Gaps.small),
              MangaIcon(IconArt.chevron, size: CreditsLayout.chevron, color: Palette.mute),
            ],
          ),
        ),
      );
}

class _FontRow extends StatelessWidget {
  const _FontRow({required this.credit});
  final FontCredit credit;

  @override
  Widget build(BuildContext context) => _TapRow(
        title: credit.name,
        subtitle: '${credit.author} · ${credit.license}',
        onTap: () => Navigator.push(
          context,
          MangaRoute<void>(builder: (_) => LicenseTextScreen(title: credit.name, asset: credit.licenseAsset)),
        ),
      );
}

/// The full text of a bundled font or sound-pack license, read from its
/// asset when the page opens. The text itself is never translated.
class LicenseTextScreen extends StatefulWidget {
  const LicenseTextScreen({super.key, required this.title, required this.asset});
  final String title;
  final String asset;

  @override
  State<LicenseTextScreen> createState() => _LicenseTextScreenState();
}

class _LicenseTextScreenState extends State<LicenseTextScreen> {
  String? _text;

  @override
  void initState() {
    super.initState();
    rootBundle.loadString(widget.asset).then((text) {
      if (mounted) setState(() => _text = text);
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Gaps.gutter),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: HeaderStyle.topGap),
              MangaHeader(
                title: ScreenTitle(widget.title),
                actions: [
                  InkIconButton(icon: IconArt.back, semanticLabel: s.back, onTap: () => Navigator.maybePop(context)),
                ],
              ),
              const SizedBox(height: Gaps.section),
              Expanded(
                child: _text == null
                    ? const SizedBox.shrink()
                    : SingleChildScrollView(
                        child: SelectableText(_text!,
                            style: const TextStyle(fontSize: TypeScale.body, height: CreditsLayout.licenseTextLineHeight)),
                      ),
              ),
              const SizedBox(height: Gaps.section),
            ],
          ),
        ),
      ),
    );
  }
}
