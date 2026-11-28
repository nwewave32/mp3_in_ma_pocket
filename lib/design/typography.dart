import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';

import 'tokens.dart';

/// Font families bundled in assets/fonts (see pubspec.yaml).
abstract final class SoftFonts {
  /// UI text uses the platform font (SF Pro on iOS). Inter was only the
  /// Figma/canvas stand-in.
  static const String? ui = null;
  static const String mono = 'JetBrainsMono';

  /// Track titles in the Library list. Space Grotesk has no Hangul, so
  /// Pretendard fills in Korean file names.
  static const String trackTitle = 'SpaceGrotesk';
  static const List<String> trackTitleFallback = ['Pretendard'];

  /// LCD-only pixel font. DotGothic16 has no Hangul, so Galmuri11 (also a
  /// pixel font) fills in Korean file names.
  static const String lcd = 'DotGothic16';
  static const List<String> lcdFallback = ['Galmuri11'];
}

/// Text styles. Pixel font appears ONLY inside the LCD.
abstract final class SoftText {
  // ---- UI ----
  static TextStyle body(SoftColors c) =>
      TextStyle(fontSize: 17, height: 22 / 17, color: c.text);
  static TextStyle bodyStrong(SoftColors c) =>
      body(c).copyWith(fontWeight: FontWeight.w600);
  static TextStyle button(SoftColors c) => TextStyle(
      fontSize: 17, height: 22 / 17, fontWeight: FontWeight.w600, color: c.onAccent);
  static TextStyle callout(SoftColors c) =>
      TextStyle(fontSize: 15, height: 1.45, color: c.textSecondary);
  static TextStyle calloutStrong(SoftColors c) =>
      TextStyle(fontSize: 15, height: 1.4, fontWeight: FontWeight.w600, color: c.text);
  static TextStyle footnote(SoftColors c) =>
      TextStyle(fontSize: 13, height: 1.45, color: c.textSecondary);

  /// A Library row's title; the playing row uses [trackTitleStrong].
  static TextStyle trackTitle(SoftColors c) => body(c).copyWith(
      fontFamily: SoftFonts.trackTitle, fontFamilyFallback: SoftFonts.trackTitleFallback);
  static TextStyle trackTitleStrong(SoftColors c) =>
      trackTitle(c).copyWith(fontWeight: FontWeight.w600);

  // ---- Mono (numbers, labels) ----
  /// Screen title: centered, uppercase, tracked out. e.g. "LIBRARY · 12".
  static TextStyle headerLabel(SoftColors c) => TextStyle(
      fontFamily: SoftFonts.mono,
      fontSize: 13,
      fontWeight: FontWeight.w500,
      letterSpacing: 13 * 0.14,
      color: c.textSecondary);
  static TextStyle microLabel(SoftColors c) => TextStyle(
      fontFamily: SoftFonts.mono,
      fontSize: 11,
      letterSpacing: 11 * 0.1,
      color: c.textSecondary);
  static TextStyle duration(SoftColors c) => TextStyle(
      fontFamily: SoftFonts.mono,
      fontSize: 14,
      height: 18 / 14,
      color: c.textSecondary,
      fontFeatures: const [FontFeature.tabularFigures()]);
  static TextStyle time(SoftColors c) =>
      duration(c).copyWith(fontSize: 13);

  // ---- LCD ----
  static TextStyle lcd(SoftColors c, {double size = 16, double? height}) => TextStyle(
        fontFamily: SoftFonts.lcd,
        fontFamilyFallback: SoftFonts.lcdFallback,
        fontSize: size,
        height: height,
        color: c.lcdInk,
        shadows: c.isDark ? [Shadow(color: c.lcdGlow, blurRadius: 8)] : null,
      );
  static TextStyle lcdTitle(SoftColors c) => lcd(c, size: 27, height: 1.12);
  static TextStyle lcdHeadline(SoftColors c) => lcd(c, size: 24, height: 1.1);
  static TextStyle lcdMeta(SoftColors c) => lcd(c, size: 13);
  static TextStyle lcdMicro(SoftColors c) => lcd(c, size: 12);
}
