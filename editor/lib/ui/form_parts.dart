import 'package:flutter/material.dart';

import '../config.dart';
import 'widgets.dart';

/// Decimals shown for a field with this [step].
int stepDecimals(double? step) {
  if (step == null) return 2;
  final s = step.toString();
  final dot = s.indexOf('.');
  return s.endsWith('.0') || dot < 0 ? 0 : s.length - dot - 1;
}

/// One label and its control on a single row.
class FormRow extends StatelessWidget {
  const FormRow({super.key, required this.label, required this.child, this.help});

  final String label;
  final Widget child;
  final String? help;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, top: Cfg.formRowGap, bottom: Cfg.formRowGap),
      child: SizedBox(
        height: Cfg.formRowHeight,
        child: Row(children: [
          SizedBox(
            width: Cfg.formLabelWidth,
            child: Tooltip(
              message: help ?? label,
              waitDuration: const Duration(milliseconds: 600),
              child: Text(label, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: Cfg.labelFontSize)),
            ),
          ),
          Expanded(child: Align(alignment: Alignment.centerLeft, child: child)),
        ]),
      ),
    );
  }
}

class FormDropdown extends StatelessWidget {
  const FormDropdown({super.key, required this.value, required this.items, required this.onChanged});

  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: value,
      isDense: true,
      isExpanded: true,
      style: const TextStyle(fontSize: Cfg.labelFontSize, color: Cfg.labelColor),
      items: [for (final i in items) DropdownMenuItem(value: i, child: Text(i))],
      onChanged: onChanged,
    );
  }
}

class FormTextBox extends StatefulWidget {
  const FormTextBox({super.key, required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  State<FormTextBox> createState() => _FormTextBoxState();
}

class _FormTextBoxState extends State<FormTextBox> {
  late final TextEditingController _controller = TextEditingController(text: widget.value);

  @override
  void didUpdateWidget(FormTextBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_controller.text != widget.value) _controller.text = widget.value;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: Cfg.formRowHeight - 2,
      child: TextField(
        controller: _controller,
        style: const TextStyle(fontSize: Cfg.labelFontSize),
        decoration: compactDecoration,
        onChanged: widget.onChanged,
      ),
    );
  }
}
