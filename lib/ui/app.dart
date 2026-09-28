import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/design.dart';
import '../state/progress.dart';
import '../state/scope.dart';
import 'manga/manga.dart';
import 'onboarding/onboarding_screen.dart';
import 'shell/app_shell.dart';

class FudatobashiApp extends StatefulWidget {
  const FudatobashiApp({super.key, required this.progress});

  final Progress progress;

  @override
  State<FudatobashiApp> createState() => _FudatobashiAppState();
}

class _FudatobashiAppState extends State<FudatobashiApp> {
  @override
  void initState() {
    super.initState();
    widget.progress.addListener(_onProgressChanged);
  }

  @override
  void dispose() {
    widget.progress.removeListener(_onProgressChanged);
    super.dispose();
  }

  // The dev-mode PerformanceOverlay is a MaterialApp constructor argument, so
  // toggling it needs this widget itself to rebuild (a descendant depending
  // on ProgressScope would not re-run MaterialApp's own build).
  void _onProgressChanged() => setState(() {});

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
          title: 'Fudatobashi',
          debugShowCheckedModeBanner: false,
          showPerformanceOverlay: widget.progress.settings.showPerformanceOverlay,
          theme: buildMangaTheme(),
          // Text outside a Scaffold (balloons and toasts in the overlay) gets
          // the UI font, not Material's red "no Material" fallback.
          builder: (context, child) => DefaultTextStyle(style: Theme.of(context).textTheme.bodyMedium!, child: child!),
          home: const _FirstLaunchGate(),
        ),
      ),
    );
  }
}

/// Onboarding until the learning mode has been chosen, then the tabs.
class _FirstLaunchGate extends StatelessWidget {
  const _FirstLaunchGate();

  @override
  Widget build(BuildContext context) {
    final onboarded = ProgressScope.of(context).settings.onboarded;
    return AnimatedSwitcher(
      duration: Motion.route,
      switchInCurve: Motion.routeCurve,
      child: onboarded ? const AppShell(key: ValueKey('shell')) : const OnboardingScreen(key: ValueKey('onboarding')),
    );
  }
}
