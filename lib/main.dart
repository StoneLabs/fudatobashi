import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';

import 'config/licenses.dart';
import 'config/vector_art_assets.dart';
import 'data/fuda_sets.dart';
import 'data/islands.dart';
import 'data/poem.dart';
import 'db/database.dart';
import 'l10n/localization.dart';
import 'state/progress.dart';
import 'ui/app.dart';
import 'ui/debug/frame_stats.dart';
import 'ui/sound/sounds.dart';
import 'ui/torifuda/glyph_atlas.dart';

/// Bundled font and sound licenses, added so they show up in
/// `showLicensePage` alongside every pub package (see the credits screen,
/// `lib/ui/settings/credits_screen.dart`, for the same texts read on demand).
void _registerBundledLicenses() {
  LicenseRegistry.addLicense(() async* {
    for (final font in fontCredits) {
      yield LicenseEntryWithLineBreaks([font.name], await rootBundle.loadString(font.licenseAsset));
    }
    yield LicenseEntryWithLineBreaks(['Kenney sound effects'], await rootBundle.loadString(soundsLicenseAsset));
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _registerBundledLicenses();
  if (!kIsWeb && Platform.isAndroid) {
    // Samsung and others default Flutter apps to 60 Hz.
    try {
      await FlutterDisplayMode.setHighRefreshRate();
    } catch (_) {}
  }
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  await Localization.load();
  poems = await Poems.load();
  fudaSets = FudaSets(poems);
  archipelago = await Archipelago.load();
  final progress = await Progress.open(AppDatabase());
  await GlyphAtlas.load();
  await loadVectorArt();
  FrameStats.instance.start();
  runApp(FudatobashiApp(progress: progress));
  // Loaded in the background: the first celebration is at least a run away.
  unawaited(sounds.load());
}
