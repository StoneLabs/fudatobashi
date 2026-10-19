import 'package:flutter/material.dart';

import '../config.dart';

Future<void> showShortcutsSheet(BuildContext context) => showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keyboard shortcuts'),
        content: SizedBox(
          width: Cfg.shortcutsSheetWidth,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            for (final (keys, what) in Cfg.shortcuts)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  SizedBox(width: Cfg.shortcutKeysWidth, child: Text(keys, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: Cfg.labelFontSize, color: Cfg.accentColor))),
                  Expanded(child: Text(what, style: const TextStyle(fontSize: Cfg.labelFontSize))),
                ]),
              ),
          ]),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
