import 'package:flutter/material.dart';

import '../../config/design.dart';

/// Material theme in the manga palette. Widgets mostly draw themselves; this
/// sets the UI font, colours and the defaults of the few Material widgets
/// still in use (dialogs, sliders, text fields).
ThemeData buildMangaTheme() {
  const scheme = ColorScheme.light(
    primary: Palette.ink,
    onPrimary: Palette.paper,
    secondary: Palette.pink,
    onSecondary: Palette.ink,
    tertiary: Palette.sea,
    surface: Palette.paper,
    onSurface: Palette.ink,
    error: Palette.pinkDeep,
  );
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: Fonts.ui,
    scaffoldBackgroundColor: Palette.paper,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(bodyColor: Palette.ink, displayColor: Palette.ink),
    textSelectionTheme: const TextSelectionThemeData(selectionColor: Palette.pink, cursorColor: Palette.ink),
  );
}
