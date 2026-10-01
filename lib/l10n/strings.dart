import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/widgets.dart';

import '../data/poem.dart';
import '../state/scope.dart';
import '../state/settings.dart';
import 'localization.dart';

/// UI strings, loaded from `assets/l10n/*.json` (see [Localization]).
/// Karuta content (poems, set names) is always Japanese and does not go
/// through here — except each card's kimariji (決まり字), which has its own
/// per-poem key below: the hiragana reading in Japanese, lowercase Hepburn
/// romaji of how it's actually read in English (see [kimariji]).
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

  /// Poem [id]'s kimariji (決まり字), for display: the hiragana reading in
  /// Japanese, lowercase Hepburn romaji of how it's read in competitive
  /// karuta otherwise (`kimariji001`–`kimariji100`, see
  /// `assets/l10n/HOW_TO_ADD_A_LANGUAGE.txt`). Never the string a sort or a
  /// kana count should use — that's still `Poem.kimariji`.
  String kimariji(int id) => t('kimariji${id.toString().padLeft(3, '0')}');

  /// The speaker button beside a card's kimariji (new-card page, card
  /// detail).
  String get kimarijiPlayLabel => t('kimarijiPlayLabel');

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

/// The player's [KimarijiScript] choice, with [KimarijiScript.auto] resolved
/// against the UI language (see [KimarijiScriptResolution.resolve]).
KimarijiScript resolvedKimarijiScript(BuildContext context) =>
    ProgressScope.of(context).settings.kimarijiScript.resolve(uiJapanese: S.of(context).ja);

/// The text to show for poem [id]'s kimariji, per [resolvedKimarijiScript]:
/// the hiragana straight from the card data, or the Hepburn romaji — the
/// English key, since the Japanese key holds hiragana. Every screen shows a
/// kimariji through this one function rather than deciding the script
/// itself; the new-card page is the one exception, pairing romaji with the
/// small kana beside it (see [resolvedKimarijiScript]). Never used for the
/// torifuda card itself, which always shows [Poem.torifuda].
String kimarijiFor(BuildContext context, int id) {
  final s = S.of(context);
  return resolvedKimarijiScript(context) == KimarijiScript.hiragana ? poems[id].kimariji : (s.ja ? s.other : s).kimariji(id);
}
