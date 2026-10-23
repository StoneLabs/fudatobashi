import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/design.dart';
import '../state/progress.dart';
import '../state/reminders.dart';
import '../state/scope.dart';
import 'manga/manga.dart';
import 'onboarding/language_picker_screen.dart';
import 'onboarding/onboarding_screen.dart';
import 'shell/app_shell.dart';
import 'sound/sounds.dart';

const appTitle = 'Fudatobashi';

/// Text outside a Scaffold (balloons and toasts in the overlay) gets the UI
/// font, not Material's red "no Material" fallback.
Widget withUiFont(BuildContext context, Widget? child) =>
    DefaultTextStyle(style: Theme.of(context).textTheme.bodyMedium!, child: child!);

class FudatobashiApp extends StatefulWidget {
  const FudatobashiApp({super.key, required this.progress, this.navigatorKey});

  final Progress progress;
  final GlobalKey<NavigatorState>? navigatorKey;

  @override
  State<FudatobashiApp> createState() => _FudatobashiAppState();
}

class _FudatobashiAppState extends State<FudatobashiApp> {
  @override
  void initState() {
    super.initState();
    widget.progress.addListener(_onProgressChanged);
    music.applySettings(widget.progress.settings);
    reminders.attach(widget.progress);
  }

  @override
  void dispose() {
    widget.progress.removeListener(_onProgressChanged);
    reminders.detach(widget.progress);
    super.dispose();
  }

  // The dev-mode PerformanceOverlay is a MaterialApp constructor argument, so
  // toggling it needs this widget itself to rebuild (a descendant depending
  // on ProgressScope would not re-run MaterialApp's own build). Settings
  // changes (the Music switch, its volume slider) reach here too, the one
  // place that keeps the music player in step with them.
  void _onProgressChanged() {
    music.applySettings(widget.progress.settings);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ProgressScope(
      progress: widget.progress,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
          systemNavigationBarColor: Palette.paper,
          systemNavigationBarIconBrightness: Brightness.dark,
          systemNavigationBarContrastEnforced: false,
        ),
        child: MaterialApp(
          title: appTitle,
          navigatorKey: widget.navigatorKey,
          debugShowCheckedModeBanner: false,
          showPerformanceOverlay: widget.progress.settings.showPerformanceOverlay,
          theme: buildMangaTheme(),
          builder: withUiFont,
          home: const _FirstLaunchGate(),
        ),
      ),
    );
  }
}

/// The language picker (a fresh install only) until a language is picked,
/// then onboarding until the learning mode has been chosen, then the tabs.
class _FirstLaunchGate extends StatelessWidget {
  const _FirstLaunchGate();

  @override
  Widget build(BuildContext context) {
    final settings = ProgressScope.of(context).settings;
    final page = !settings.languagePicked
        ? const LanguagePickerScreen(key: ValueKey('language'))
        : settings.onboarded
            ? const AppShell(key: ValueKey('shell'))
            : const OnboardingScreen(key: ValueKey('onboarding'));
    return AnimatedSwitcher(duration: Motion.route, switchInCurve: Motion.routeCurve, child: page);
  }
}
