import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config.dart';
import '../io/editor_controller.dart';
import 'center_view.dart';
import 'left_column.dart';
import 'right_column.dart';
import 'shortcuts_sheet.dart';
import 'status_line.dart';

class EditorApp extends StatelessWidget {
  const EditorApp({super.key, required this.controller});

  final EditorController controller;

  /// Holding backslash shows the saved version, unless a text field is being typed in.
  KeyEventResult _compareKey(FocusNode node, KeyEvent event) {
    if (event.logicalKey != LogicalKeyboardKey.backslash || event is KeyRepeatEvent) return KeyEventResult.ignored;
    if (event is KeyUpEvent) {
      controller.setComparing(false);
      return KeyEventResult.handled;
    }
    final typing = FocusManager.instance.primaryFocus?.context?.findAncestorWidgetOfExactType<EditableText>() != null;
    if (typing) return KeyEventResult.ignored;
    controller.setComparing(true);
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Skin editor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: Cfg.windowColor),
      home: Builder(builder: (context) => CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.f1): () => showShortcutsSheet(context),
          const SingleActivator(LogicalKeyboardKey.keyS, control: true): controller.save,
          const SingleActivator(LogicalKeyboardKey.keyZ, control: true): controller.undo,
          const SingleActivator(LogicalKeyboardKey.keyZ, control: true, shift: true): controller.redo,
          const SingleActivator(LogicalKeyboardKey.keyY, control: true): controller.redo,
        },
        child: Focus(
          autofocus: true,
          onKeyEvent: _compareKey,
          child: Scaffold(
            body: Listener(
              onPointerDown: (_) => controller.dismissError(),
              child: ListenableBuilder(
              listenable: controller,
              builder: (context, _) => Column(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(Cfg.panelGap),
                      child: Row(
                        children: [
                          SizedBox(width: Cfg.leftColumnWidth, child: LeftColumn(controller: controller)),
                          const SizedBox(width: Cfg.panelGap),
                          Expanded(child: CenterView(controller: controller)),
                          const SizedBox(width: Cfg.panelGap),
                          SizedBox(width: Cfg.rightColumnWidth, child: RightColumn(controller: controller)),
                        ],
                      ),
                    ),
                  ),
                  StatusLine(controller: controller),
                ],
              ),
            ),
            ),
          ),
        ),
      )),
    );
  }
}
