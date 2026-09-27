import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';

import 'data/fuda_sets.dart';
import 'data/poem.dart';
import 'ui/play/play_screen.dart';
import 'ui/torifuda/glyph_atlas.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb && Platform.isAndroid) {
    // Samsung and others default Flutter apps to 60 Hz.
    try {
      await FlutterDisplayMode.setHighRefreshRate();
    } catch (_) {}
  }
  poems = await Poems.load();
  await GlyphAtlas.load();
  fudaSets = FudaSets(poems);
  runApp(const FudatobashiApp());
}

class FudatobashiApp extends StatelessWidget {
  const FudatobashiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fudatobashi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: const Color(0xFF4B2A7B)),
      home: PlayScreen(cards: PlayScreen.randomDeck(10)),
    );
  }
}
