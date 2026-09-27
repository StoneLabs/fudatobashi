import 'package:flutter/widgets.dart';

import '../../config/design.dart';

/// The EN / JA pill switch.
class LanguageToggle extends StatelessWidget {
  const LanguageToggle({super.key, required this.japanese, required this.onChanged});

  final bool japanese;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: LangToggleStyle.height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Palette.paper,
        border: Border.all(color: Palette.ink, width: Strokes.control),
        borderRadius: BorderRadius.circular(LangToggleStyle.height / 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Segment('EN', selected: !japanese, onTap: () => onChanged(false)),
          _Segment('JA', selected: japanese, onTap: () => onChanged(true)),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment(this.label, {required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: selected,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: AnimatedContainer(
            duration: Motion.tab,
            color: selected ? Palette.ink : Palette.paper,
            padding: const EdgeInsets.symmetric(horizontal: LangToggleStyle.padding),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: Weights.black,
                fontSize: LangToggleStyle.font,
                color: selected ? Palette.paper : Palette.ink,
              ),
            ),
          ),
        ),
      );
}
