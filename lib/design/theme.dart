import 'package:flutter/material.dart';

import 'tokens.dart';

/// Build the app theme. Use with `themeMode: ThemeMode.system` so the app
/// follows the device light/dark setting (PRD requirement).
ThemeData buildSoftTheme(Brightness brightness) {
  final c = brightness == Brightness.dark ? SoftColors.dark : SoftColors.light;
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    scaffoldBackgroundColor: c.ground,
    colorScheme: ColorScheme.fromSeed(
      seedColor: c.accent,
      brightness: brightness,
      primary: c.accent,
      onPrimary: c.onAccent,
      surface: c.ground,
      onSurface: c.text,
      error: c.dangerBottom,
    ),
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    extensions: <ThemeExtension<dynamic>>[c],
  );
}
