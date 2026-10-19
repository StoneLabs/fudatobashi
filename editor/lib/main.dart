import 'package:flutter/material.dart';

import 'export/export_cli.dart';
import 'io/editor_controller.dart';
import 'io/settings.dart';
import 'ui/editor_app.dart';

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  if (args.isNotEmpty && args.first == '--export') {
    await exportAndExit(args.skip(1).toList());
    return;
  }
  final settings = Settings.load();
  final controller = EditorController(settings);
  runApp(EditorApp(controller: controller));
  await controller.init(args.isNotEmpty ? args.first : null);
}
