import 'package:flutter/material.dart';

import '../l10n/data_strings.dart';
import '../l10n/strings.dart';
import '../state/data_store.dart';
import 'app.dart';
import 'manga/manga.dart';
import 'recovery/recovery_screen.dart';
import 'settings/data_actions.dart';

/// The app from its start: the app once the data has opened, the recovery
/// screen when it hasn't. A restore or a fresh start builds it all again, as
/// if the app had just started.
class AppRoot extends StatelessWidget {
  const AppRoot({super.key, required this.store});

  final DataStore store;

  @override
  Widget build(BuildContext context) => DataStoreScope(
        store: store,
        child: ListenableBuilder(
          listenable: store,
          builder: (context, _) {
            final navigator = GlobalKey<NavigatorState>();
            final notice = store.takeNotice();
            if (notice != null) WidgetsBinding.instance.addPostFrameCallback((_) => _tell(navigator, notice));
            return switch (store.state) {
              DataOpened(:final progress) =>
                FudatobashiApp(key: ObjectKey(progress), progress: progress, navigatorKey: navigator),
              final DataFailed failed => MaterialApp(
                  key: ObjectKey(failed),
                  title: appTitle,
                  navigatorKey: navigator,
                  debugShowCheckedModeBanner: false,
                  theme: buildMangaTheme(),
                  builder: withUiFont,
                  home: RecoveryScreen(store: store, error: failed.error),
                ),
            };
          },
        ),
      );

  static void _tell(GlobalKey<NavigatorState> navigator, DataNotice notice) {
    final context = navigator.currentState?.overlay?.context;
    if (context == null) return;
    final s = S.of(context);
    switch (notice) {
      case DataNotice.restored:
        MangaToast.show(context, s.restoreDone);
      case DataNotice.restoreFailed:
        showDataProblem(context, s.restoreOpenFailed);
    }
  }
}
