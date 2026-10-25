import 'package:flutter/widgets.dart';

import '../../config/design.dart';

/// A screen's top bar: a title on the left, actions on the right.
class MangaHeader extends StatelessWidget {
  const MangaHeader({super.key, required this.title, this.actions = const []});

  final Widget title;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
        constraints: const BoxConstraints(minHeight: HeaderStyle.height),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: title),
            for (final (i, a) in actions.indexed) ...[
              if (i > 0) const SizedBox(width: HeaderStyle.actionGap),
              a,
            ],
          ],
        ),
      );
}

/// The app's logo lettering: 札飛ばし over FUDATOBASHI, shrinking rather
/// than breaking when the header is tight; or, in its place, another
/// [title] over its [sub] (a run summary's mode).
class BrandTitle extends StatelessWidget {
  const BrandTitle({super.key, required this.sub, this.title = brand});

  static const brand = '札飛ばし';

  static const titleStyle = TextStyle(
    fontFamily: Fonts.display,
    fontSize: HeaderStyle.logo,
    letterSpacing: HeaderStyle.logoTracking * HeaderStyle.logo,
    height: 1,
  );
  static const subStyle = TextStyle(
    fontWeight: Weights.black,
    fontSize: HeaderStyle.sub,
    letterSpacing: HeaderStyle.subTracking * HeaderStyle.sub,
    height: 1,
  );

  final String title;
  final String sub;

  @override
  Widget build(BuildContext context) => FittedBox(
        fit: BoxFit.scaleDown,
        alignment: AlignmentDirectional.centerStart,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: titleStyle),
            const SizedBox(height: HeaderStyle.subGap),
            Text(sub, style: subStyle),
          ],
        ),
      );
}

/// A run page's header lettering: the [title] over its [sub] line, which
/// never shrinks but gives way to [shortSub] and then an ellipsis when the
/// room is short.
class RunHeaderTitle extends StatelessWidget {
  const RunHeaderTitle({super.key, required this.title, required this.sub, required this.shortSub});

  final String title, sub, shortSub;

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    return LayoutBuilder(builder: (context, box) {
      bool fits(String text) {
        final painter = TextPainter(
          text: TextSpan(text: text, style: BrandTitle.subStyle),
          textDirection: Directionality.of(context),
          textScaler: scaler,
          maxLines: 1,
        )..layout();
        return painter.width <= box.maxWidth;
      }

      final line = fits(sub) ? sub : shortSub;
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(title, style: BrandTitle.titleStyle),
          ),
          const SizedBox(height: HeaderStyle.subGap),
          Text(line, style: BrandTitle.subStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      );
    });
  }
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
