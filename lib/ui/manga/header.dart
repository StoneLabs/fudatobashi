import 'package:flutter/widgets.dart';

import '../../config/design.dart';

/// A screen's top bar: a title on the left, actions on the right.
class MangaHeader extends StatelessWidget {
  const MangaHeader({super.key, required this.title, this.actions = const []});

  final Widget title;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: HeaderStyle.height,
        child: Row(
          children: [
            Expanded(child: Align(alignment: Alignment.centerLeft, child: title)),
            for (final (i, a) in actions.indexed) ...[
              if (i > 0) const SizedBox(width: HeaderStyle.actionGap),
              a,
            ],
          ],
        ),
      );
}

/// The app's logo lettering: 札飛ばし over FUDATOBASHI.
class BrandTitle extends StatelessWidget {
  const BrandTitle({super.key, required this.sub});

  final String sub;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '札飛ばし',
            style: TextStyle(
              fontFamily: Fonts.display,
              fontSize: HeaderStyle.logo,
              letterSpacing: HeaderStyle.logoTracking * HeaderStyle.logo,
              height: 1,
            ),
          ),
          const SizedBox(height: HeaderStyle.subGap),
          Text(
            sub,
            style: const TextStyle(
              fontWeight: Weights.black,
              fontSize: HeaderStyle.sub,
              letterSpacing: HeaderStyle.subTracking * HeaderStyle.sub,
              height: 1,
            ),
          ),
        ],
      );
}

/// A screen title in display type with a small second-language label
/// ("Stats 成績").
class ScreenTitle extends StatelessWidget {
  const ScreenTitle(this.title, {super.key, this.sub});

  final String title;
  final String? sub;

  @override
  Widget build(BuildContext context) => Text.rich(
        TextSpan(children: [
          TextSpan(
            text: title,
            style: const TextStyle(fontFamily: Fonts.display, fontSize: HeaderStyle.logo, height: 1),
          ),
          if (sub != null)
            TextSpan(
              text: '  $sub',
              style: const TextStyle(fontWeight: Weights.black, fontSize: HeaderStyle.titleSub, height: 1),
            ),
        ]),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
}
