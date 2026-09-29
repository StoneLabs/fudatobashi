import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/widgets.dart';

import '../state/scope.dart';
import 'localization.dart';

/// UI strings, loaded from `assets/l10n/*.json` (see [Localization]).
/// Karuta content (kimariji, poems, set names) is always Japanese and does
/// not go through here.
///
/// Features add their own strings in an `extension FooStrings on S` using
/// [t] or [f]. Templates mark numbers as `{0}`, `{1}` … so `NumberedText` can
/// set them in display type.
class S {
  const S(this.code);

  /// The language in use, e.g. `'en'` or `'ja'`.
  final String code;

  static S of(BuildContext context) => S(
        Localization.resolve(
          ProgressScope.of(context).settings.language,
          PlatformDispatcher.instance.locale.languageCode,
        ),
      );

  bool get ja => code == 'ja';

  /// The same strings in another language, for bilingual sub-labels: with
  /// more than two languages this is Japanese, unless the UI is already
  /// Japanese, in which case it's English.
  S get other => S(ja ? 'en' : 'ja');

  String t(String key) => Localization.lookup(code, key);

  /// Fills `{0}`, `{1}` … in the template at [key] with [args].
  String f(String key, List<Object> args) {
    var out = t(key);
    for (var i = 0; i < args.length; i++) {
      out = out.replaceAll('{$i}', '${args[i]}');
    }
    return out;
  }

  // Modes
  String get training => t('training');
  String get startTraining => t('startTraining');
  String get freePlay => t('freePlay');
  String get weakCards => t('weakCards');
  String get guest => t('guest');
  String get untracked => t('untracked');
  String get guestNote => t('guestNote');

  // Navigation
  String get home => t('home');
  String get history => t('history');
  String get stats => t('stats');
  String get help => t('help');
  String get settings => t('settings');
  String get rank => t('rank');
  String get debug => t('debug');
  String get back => t('back');
  String get cancel => t('cancel');
  String get comingSoon => t('comingSoon');

  // Play
  String get start => t('start');
  String get undo => t('undo');
  String get end => t('end');
  String get again => t('again');
  String get done => t('done');
  String get dontRemember => t('dontRemember');
  String get tapToStart => t('tapToStart');
  String get swipeToStart => t('swipeToStart');

  // Results
  String get totalTime => t('totalTime');
  String get perCard => t('perCard');
  String get personalBest => t('personalBest');
  String get previousBest => t('previousBest');
  String get slowest => t('slowest');
  String get goalUp => t('goalUp');
  String get rating => t('rating');

  // Misc
  String cardsCount(int n) => f('cardsCount', [n]);
  String dueCount(int n) => f('dueCount', [n]);
  String dayStreak(int n) => f('dayStreak', [n]);
  String toNext(int points, String band) => f('toNext', [points, band]);
}
