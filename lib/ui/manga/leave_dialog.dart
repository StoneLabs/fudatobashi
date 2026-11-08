import 'package:flutter/material.dart';

/// Asks before leaving a game under way: [title] over [note], then [stay]
/// and [leave]. True to leave.
Future<bool> confirmLeaving(
  BuildContext context, {
  required String title,
  required String note,
  required String stay,
  required String leave,
}) async {
  final answer = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(title),
      content: Text(note),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: Text(stay)),
        FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(leave)),
      ],
    ),
  );
  return answer == true;
}
