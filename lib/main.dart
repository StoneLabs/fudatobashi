import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';

import 'config/config.dart';
import 'config/licenses.dart';
import 'config/vector_art_assets.dart';
import 'config/torifuda_spec.dart';
import 'config/yomifuda_spec.dart';
import 'data/fuda_sets.dart';
import 'data/islands.dart';
import 'data/joka.dart';
import 'data/poem.dart';
import 'db/database.dart';
import 'l10n/localization.dart';
import 'state/crash_log.dart';
import 'state/data_store.dart';
import 'state/progress.dart';
import 'ui/app.dart';
import 'ui/app_root.dart';
import 'ui/debug/frame_stats.dart';
import 'ui/play/pointer_clock.dart';
import 'ui/sound/sounds.dart';
import 'ui/torifuda/card_faces.dart';
import 'ui/torifuda/glyph_atlas.dart';

/// Bundled font, sound and music licenses, added so they show up in
/// `showLicensePage` alongside every pub package (see the credits screen,
/// `lib/ui/settings/credits_screen.dart`, for the same texts read on demand).
void _registerBundledLicenses() {
  LicenseRegistry.addLicense(() async* {
    for (final font in fontCredits) {
      yield LicenseEntryWithLineBreaks([font.name], await rootBundle.loadString(font.licenseAsset));
    }
    yield LicenseEntryWithLineBreaks(['Kenney sound effects'], await rootBundle.loadString(soundsLicenseAsset));
    yield LicenseEntryWithLineBreaks(['fun bgm 022824 (syncopika)', 'high energy bgm (syncopika)'], await rootBundle.loadString(musicLicenseAsset));
  });
}

/// Everything runs in one guarded zone, so an uncaught error lands in the
/// crash log; data that won't open lands on the recovery screen.
void main() => runZonedGuarded(_start, (error, stack) {
      debugPrint('$error\n$stack');
      CrashLog.instance?.record(error, stack);
    });

Future<void> _start() async {
  WidgetsFlutterBinding.ensureInitialized();
  final paths = kIsWeb ? null : await DataPaths.resolve();
  if (paths != null) CrashLog(paths.crashLog).install();
  PointerClock.start();
  _registerBundledLicenses();
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    await SystemChrome.setPreferredOrientations(OrientationTuning.app);
  }
  if (!kIsWeb && Platform.isAndroid) {
    // Samsung and others default Flutter apps to 60 Hz.
    try {
      await FlutterDisplayMode.setHighRefreshRate();
    } catch (_) {}
  }
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  await Localization.load();
  poems = await Poems.load();
  joka = await Waka.load(jokaAsset);
  fudaSets = FudaSets(poems);
  archipelago = await Archipelago.load();
  await GlyphAtlas.load();
  await CardFaces.load([YomifudaStyle.standard.background, TorifudaStyle.standard.background]);
  await loadVectorArt();
  FrameStats.instance.start();
  if (paths == null) {
    runApp(FudatobashiApp(progress: await Progress.open(AppDatabase())));
  } else {
    final store = DataStore(paths, dialogs: SystemFileDialogs(paths.temp));
    await store.start();
    runApp(AppRoot(store: store));
  }
  // Loaded in the background: the first celebration is at least a run away.
  unawaited(sounds.load());
  unawaited(music.load());
}
