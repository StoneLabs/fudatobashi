import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';

import 'data/fuda_sets.dart';
import 'data/islands.dart';
import 'data/poem.dart';
import 'db/database.dart';
import 'state/progress.dart';
import 'ui/app.dart';
import 'ui/debug/frame_stats.dart';
import 'ui/torifuda/glyph_atlas.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb && Platform.isAndroid) {
    // Samsung and others default Flutter apps to 60 Hz.
    try {
      await FlutterDisplayMode.setHighRefreshRate();
    } catch (_) {}
  }
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  poems = await Poems.load();
  fudaSets = FudaSets(poems);
  archipelago = await Archipelago.load();
  final progress = await Progress.open(AppDatabase());
  await GlyphAtlas.load();
  FrameStats.instance.start();
  runApp(FudatobashiApp(progress: progress));
}
