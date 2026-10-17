import 'package:flutter/widgets.dart';

import '../../config/design.dart';

/// One choice of a [PillSwitch]: its [label], and a smaller [sub] after it.
typedef PillChoice<T> = ({T value, String label, String? sub});

/// A switch between a few [choices] in a round-ended ink box, the
/// [selected] one filled ink. With [expand] the choices share the whole
/// width; otherwise each is as wide as its label.
class PillSwitch<T> extends StatelessWidget {
  const PillSwitch({
    super.key,
    required this.choices,
    required this.selected,
    required this.onChanged,
    required this.height,
    required this.border,
    required this.fontSize,
    this.subFontSize,
    this.padding = 0,
    this.expand = false,
  });

  final List<PillChoice<T>> choices;
  final T selected;
  final ValueChanged<T> onChanged;

  /// The whole switch's height, its border included.
  final double height;
  final double border;
  final double fontSize;
  final double? subFontSize;

  /// Room on each side of a label.
  final double padding;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final radius = height / 2;
    Widget segment(PillChoice<T> choice) {
      final on = choice.value == selected;
      final color = on ? Palette.paper : Palette.ink;
      final label = Text.rich(
        TextSpan(children: [
          TextSpan(text: choice.label),
          if (choice.sub case final sub?) ...[
            const WidgetSpan(child: SizedBox(width: PillSwitchStyle.subGap)),
            TextSpan(
              text: sub,
              style: TextStyle(
                  fontSize: subFontSize ?? fontSize, letterSpacing: (subFontSize ?? fontSize) * PillSwitchStyle.subTracking),
            ),
          ],
        ]),
        maxLines: 1,
        softWrap: false,
        style: TextStyle(fontWeight: Weights.black, fontSize: fontSize, height: PillStyle.lineHeight, color: color),
      );
      return Semantics(
        button: true,
        selected: on,
        inMutuallyExclusiveGroup: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: on ? null : () => onChanged(choice.value),
          child: Container(
            color: on ? Palette.ink : Palette.paper,
            constraints: BoxConstraints(minHeight: height - 2 * border),
            padding: EdgeInsets.symmetric(horizontal: padding),
            alignment: Alignment.center,
            child: expand ? FittedBox(fit: BoxFit.scaleDown, child: label) : label,
          ),
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Palette.paper,
        border: Border.all(color: Palette.ink, width: border),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Padding(
        padding: EdgeInsets.all(border),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius - border),
          child: IntrinsicHeight(
            child: Row(
              mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final choice in choices) expand ? Expanded(child: segment(choice)) : segment(choice),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
