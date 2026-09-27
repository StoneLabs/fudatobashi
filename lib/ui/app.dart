import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/design.dart';
import '../state/progress.dart';
import '../state/scope.dart';
import 'manga/manga.dart';
import 'onboarding/onboarding_screen.dart';
import 'shell/app_shell.dart';

class FudatobashiApp extends StatelessWidget {
  const FudatobashiApp({super.key, required this.progress});

  final Progress progress;

  @override
  Widget build(BuildContext context) {
    return ProgressScope(
      progress: progress,
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
          theme: buildMangaTheme(),
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
