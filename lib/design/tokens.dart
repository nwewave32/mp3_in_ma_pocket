// Design tokens for "MP3 in ma pocket" — Soft Keys direction.
// Source of truth: design/tokens.json and the "Key screens — Soft Keys" canvas.
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// Color tokens. Light = clear/soft gray hardware, Dark = smoke hardware with
/// an orange-glowing LCD. Read with `SoftColors.of(context)`.
@immutable
class SoftColors extends ThemeExtension<SoftColors> {
  const SoftColors({
    required this.brightness,
    required this.ground,
    required this.surface,
    required this.separator,
    required this.text,
    required this.textSecondary,
    required this.icon,
    required this.iconDisabled,
    required this.panelTop,
    required this.panelBottom,
    required this.well,
    required this.faceTop,
    required this.faceBottom,
    required this.facePressedTop,
    required this.facePressedBottom,
    required this.grip,
    required this.grabber,
    required this.lcd,
    required this.lcdInk,
    required this.lcdGlow,
    required this.accent,
    required this.accentTop,
    required this.accentBottom,
    required this.accentPressedTop,
    required this.accentPressedBottom,
    required this.onAccent,
    required this.accentText,
    required this.rowPlaying,
    required this.dangerTop,
    required this.dangerBottom,
    required this.ledOff,
  });

  final Brightness brightness;

  /// App background.
  final Color ground;

  /// Flat list panel.
  final Color surface;
  final Color separator;
  final Color text;
  final Color textSecondary;
  final Color icon;
  final Color iconDisabled;

  /// Raised device panel gradient (top → bottom).
  final Color panelTop;
  final Color panelBottom;

  /// Recessed socket ("well") a key sits in.
  final Color well;

  /// Raised key face gradient, normal and pressed.
  final Color faceTop;
  final Color faceBottom;
  final Color facePressedTop;
  final Color facePressedBottom;
  final Color grip;
  final Color grabber;

  /// LCD window.
  final Color lcd;
  final Color lcdInk;

  /// Text glow on the LCD. Transparent in light mode.
  final Color lcdGlow;

  /// Orange: only for live things (play, primary action, progress, LED on).
  final Color accent;
  final Color accentTop;
  final Color accentBottom;
  final Color accentPressedTop;
  final Color accentPressedBottom;

  /// Ink on orange. Never white (white on orange fails 4.5:1).
  final Color onAccent;

  /// Orange used as text (playing row).
  final Color accentText;
  final Color rowPlaying;
  final Color dangerTop;
  final Color dangerBottom;
  final Color ledOff;

  bool get isDark => brightness == Brightness.dark;

  static SoftColors of(BuildContext context) =>
      Theme.of(context).extension<SoftColors>() ?? light;

  static const light = SoftColors(
    brightness: Brightness.light,
    ground: Color(0xFFE6E7E9),
    surface: Color(0xFFEEEFF1),
    separator: Color(0xFFDFE0E3),
    text: Color(0xFF16181A),
    textSecondary: Color(0xFF5E646A),
    icon: Color(0xFF5E646A),
    iconDisabled: Color(0xFFB4B8BD),
    panelTop: Color(0xFFF3F4F5),
    panelBottom: Color(0xFFE3E4E7),
    well: Color(0xFFD9DADD),
    faceTop: Color(0xFFFCFCFD),
    faceBottom: Color(0xFFE3E4E7),
    facePressedTop: Color(0xFFDFE0E3),
    facePressedBottom: Color(0xFFECEDEF),
    grip: Color(0xFFB9BDC2),
    grabber: Color(0xFFC4C7CB),
    lcd: Color(0xFFD5DDC8),
    lcdInk: Color(0xFF26301F),
    lcdGlow: Color(0x00000000),
    accent: Color(0xFFFF6A13),
    accentTop: Color(0xFFFF8A45),
    accentBottom: Color(0xFFF2600A),
    accentPressedTop: Color(0xFFE8590A),
    accentPressedBottom: Color(0xFFFF7A2E),
    onAccent: Color(0xFF16181A),
    accentText: Color(0xFF9A3412),
    rowPlaying: Color(0xFFDFE0E3),
    dangerTop: Color(0xFFE5483B),
    dangerBottom: Color(0xFFC9281C),
    ledOff: Color(0x3314181C),
  );

  static const dark = SoftColors(
    brightness: Brightness.dark,
    ground: Color(0xFF121315),
    surface: Color(0xFF1C1E21),
    separator: Color(0xFF2A2D30),
    text: Color(0xFFF1F2F3),
    textSecondary: Color(0xFF9AA0A6),
    icon: Color(0xFFC3C7CC),
    iconDisabled: Color(0xFF5A5E63),
    panelTop: Color(0xFF2C2F33),
    panelBottom: Color(0xFF1F2124),
    well: Color(0xFF17181A),
    faceTop: Color(0xFF43464B),
    faceBottom: Color(0xFF2F3236),
    facePressedTop: Color(0xFF2A2C30),
    facePressedBottom: Color(0xFF34373B),
    grip: Color(0xFF5A5E63),
    grabber: Color(0xFF3A3D41),
    lcd: Color(0xFF0B0C0A),
    lcdInk: Color(0xFFFF8A3D),
    lcdGlow: Color(0x8CFF8A3D),
    accent: Color(0xFFFF7A2E),
    accentTop: Color(0xFFFF8A45),
    accentBottom: Color(0xFFF2600A),
    accentPressedTop: Color(0xFFE8590A),
    accentPressedBottom: Color(0xFFFF7A2E),
    onAccent: Color(0xFF16181A),
    accentText: Color(0xFFFF8A3D),
    rowPlaying: Color(0xFF141517),
    dangerTop: Color(0xFFE5483B),
    dangerBottom: Color(0xFFC9281C),
    ledOff: Color(0x33FFFFFF),
  );

  @override
  SoftColors copyWith({
    Brightness? brightness,
    Color? ground,
    Color? surface,
    Color? separator,
    Color? text,
    Color? textSecondary,
    Color? icon,
    Color? iconDisabled,
    Color? panelTop,
    Color? panelBottom,
    Color? well,
    Color? faceTop,
    Color? faceBottom,
    Color? facePressedTop,
    Color? facePressedBottom,
    Color? grip,
    Color? grabber,
    Color? lcd,
    Color? lcdInk,
    Color? lcdGlow,
    Color? accent,
    Color? accentTop,
    Color? accentBottom,
    Color? accentPressedTop,
    Color? accentPressedBottom,
    Color? onAccent,
    Color? accentText,
    Color? rowPlaying,
    Color? dangerTop,
    Color? dangerBottom,
    Color? ledOff,
  }) {
    return SoftColors(
      brightness: brightness ?? this.brightness,
      ground: ground ?? this.ground,
      surface: surface ?? this.surface,
      separator: separator ?? this.separator,
      text: text ?? this.text,
      textSecondary: textSecondary ?? this.textSecondary,
      icon: icon ?? this.icon,
      iconDisabled: iconDisabled ?? this.iconDisabled,
      panelTop: panelTop ?? this.panelTop,
      panelBottom: panelBottom ?? this.panelBottom,
      well: well ?? this.well,
      faceTop: faceTop ?? this.faceTop,
      faceBottom: faceBottom ?? this.faceBottom,
      facePressedTop: facePressedTop ?? this.facePressedTop,
      facePressedBottom: facePressedBottom ?? this.facePressedBottom,
      grip: grip ?? this.grip,
      grabber: grabber ?? this.grabber,
      lcd: lcd ?? this.lcd,
      lcdInk: lcdInk ?? this.lcdInk,
      lcdGlow: lcdGlow ?? this.lcdGlow,
      accent: accent ?? this.accent,
      accentTop: accentTop ?? this.accentTop,
      accentBottom: accentBottom ?? this.accentBottom,
      accentPressedTop: accentPressedTop ?? this.accentPressedTop,
      accentPressedBottom: accentPressedBottom ?? this.accentPressedBottom,
      onAccent: onAccent ?? this.onAccent,
      accentText: accentText ?? this.accentText,
      rowPlaying: rowPlaying ?? this.rowPlaying,
      dangerTop: dangerTop ?? this.dangerTop,
      dangerBottom: dangerBottom ?? this.dangerBottom,
      ledOff: ledOff ?? this.ledOff,
    );
  }

  @override
  SoftColors lerp(ThemeExtension<SoftColors>? other, double t) {
    if (other is! SoftColors) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return SoftColors(
      brightness: t < 0.5 ? brightness : other.brightness,
      ground: l(ground, other.ground),
      surface: l(surface, other.surface),
      separator: l(separator, other.separator),
      text: l(text, other.text),
      textSecondary: l(textSecondary, other.textSecondary),
      icon: l(icon, other.icon),
      iconDisabled: l(iconDisabled, other.iconDisabled),
      panelTop: l(panelTop, other.panelTop),
      panelBottom: l(panelBottom, other.panelBottom),
      well: l(well, other.well),
      faceTop: l(faceTop, other.faceTop),
      faceBottom: l(faceBottom, other.faceBottom),
      facePressedTop: l(facePressedTop, other.facePressedTop),
      facePressedBottom: l(facePressedBottom, other.facePressedBottom),
      grip: l(grip, other.grip),
      grabber: l(grabber, other.grabber),
      lcd: l(lcd, other.lcd),
      lcdInk: l(lcdInk, other.lcdInk),
      lcdGlow: l(lcdGlow, other.lcdGlow),
      accent: l(accent, other.accent),
      accentTop: l(accentTop, other.accentTop),
      accentBottom: l(accentBottom, other.accentBottom),
      accentPressedTop: l(accentPressedTop, other.accentPressedTop),
      accentPressedBottom: l(accentPressedBottom, other.accentPressedBottom),
      onAccent: l(onAccent, other.onAccent),
      accentText: l(accentText, other.accentText),
      rowPlaying: l(rowPlaying, other.rowPlaying),
      dangerTop: l(dangerTop, other.dangerTop),
      dangerBottom: l(dangerBottom, other.dangerBottom),
      ledOff: l(ledOff, other.ledOff),
    );
  }
}

/// Spacing scale (4-based).
abstract final class SoftSpace {
  static const double s1 = 4;
  static const double s2 = 8;
  static const double s3 = 12;
  static const double s4 = 16;
  static const double s5 = 20;
  static const double s6 = 24;
  static const double s8 = 32;
  static const double s12 = 48;

  /// Minimum touch target.
  static const double minTap = 44;
  static const double rowHeight = 52;
  static const double headerHeight = 60;
}

/// Corner radii.
abstract final class SoftRadius {
  static const double lcdSmall = 16;
  static const double list = 20;
  static const double lcd = 22;
  static const double panel = 34;
  static const double device = 40;
  static const double pill = 999;
}

/// Motion.
abstract final class SoftMotion {
  /// Key press: sink 1px, shadow goes inside.
  static const Duration press = Duration(milliseconds: 90);

  /// Switch knob / repeat selector travel.
  static const Duration knob = Duration(milliseconds: 140);
  static const Curve curve = Curves.easeOut;
  static const double pressSink = 1;
}

/// An inner shadow (CSS `box-shadow: inset ...`). Flutter's BoxShadow has no
/// inset, so these are painted by [InsetShadowPainter].
@immutable
class InsetShadow {
  const InsetShadow({
    required this.color,
    this.offset = Offset.zero,
    this.blurRadius = 0,
  });

  final Color color;
  final Offset offset;
  final double blurRadius;

  static InsetShadow? lerp(InsetShadow? a, InsetShadow? b, double t) {
    if (a == null || b == null) return t < 0.5 ? a : b;
    return InsetShadow(
      color: Color.lerp(a.color, b.color, t)!,
      offset: Offset.lerp(a.offset, b.offset, t)!,
      blurRadius: lerpDouble(a.blurRadius, b.blurRadius, t)!,
    );
  }
}

/// Shadow recipes, resolved per brightness.
abstract final class SoftShadows {
  // ---- Outer (drop) shadows ----
  static List<BoxShadow> panel(SoftColors c) => c.isDark
      ? const [
          BoxShadow(color: Color(0x8C000000), offset: Offset(0, 20), blurRadius: 40),
          BoxShadow(color: Color(0x08FFFFFF), spreadRadius: 1),
        ]
      : const [
          BoxShadow(color: Color(0x2414181C), offset: Offset(0, 18), blurRadius: 36),
          BoxShadow(color: Color(0x1414181C), offset: Offset(0, 2), blurRadius: 4),
        ];

  static List<BoxShadow> floating(SoftColors c) => c.isDark
      ? const [
          BoxShadow(color: Color(0x99000000), offset: Offset(0, 12), blurRadius: 28),
          BoxShadow(color: Color(0x0AFFFFFF), spreadRadius: 1),
        ]
      : const [
          BoxShadow(color: Color(0x2E14181C), offset: Offset(0, 12), blurRadius: 28),
          BoxShadow(color: Color(0x1414181C), offset: Offset(0, 2), blurRadius: 4),
        ];

  static List<BoxShadow> list(SoftColors c) => c.isDark
      ? const [
          BoxShadow(color: Color(0x66000000), offset: Offset(0, 4), blurRadius: 12),
          BoxShadow(color: Color(0x08FFFFFF), spreadRadius: 1),
        ]
      : const [
          BoxShadow(color: Color(0x1A14181C), offset: Offset(0, 1), blurRadius: 3),
        ];

  static List<BoxShadow> key(SoftColors c) => c.isDark
      ? const [
          BoxShadow(color: Color(0x80000000), offset: Offset(0, 3), blurRadius: 6),
          BoxShadow(color: Color(0x66000000), offset: Offset(0, 1), blurRadius: 1),
        ]
      : const [
          BoxShadow(color: Color(0x2E000000), offset: Offset(0, 3), blurRadius: 6),
          BoxShadow(color: Color(0x1F000000), offset: Offset(0, 1), blurRadius: 1),
        ];

  static List<BoxShadow> accentKey(SoftColors c) => c.isDark
      ? const [
          BoxShadow(color: Color(0x80000000), offset: Offset(0, 3), blurRadius: 8),
        ]
      : const [
          BoxShadow(color: Color(0x59C2410C), offset: Offset(0, 3), blurRadius: 6),
          BoxShadow(color: Color(0x26000000), offset: Offset(0, 1), blurRadius: 1),
        ];

  /// The thin highlight under a well's lower rim.
  static List<BoxShadow> wellRim(SoftColors c) => c.isDark
      ? const [BoxShadow(color: Color(0x0DFFFFFF), offset: Offset(0, 1))]
      : const [BoxShadow(color: Color(0xF2FFFFFF), offset: Offset(0, 1))];

  // ---- Inner shadows ----
  static List<InsetShadow> well(SoftColors c) => c.isDark
      ? const [
          InsetShadow(color: Color(0x99000000), offset: Offset(0, 3), blurRadius: 6),
          InsetShadow(color: Color(0x0DFFFFFF), offset: Offset(0, -1), blurRadius: 1),
        ]
      : const [
          InsetShadow(color: Color(0x33000000), offset: Offset(0, 3), blurRadius: 6),
          InsetShadow(color: Color(0xB3FFFFFF), offset: Offset(0, -2), blurRadius: 2),
        ];

  static List<InsetShadow> lcd(SoftColors c) => c.isDark
      ? const [
          InsetShadow(color: Color(0xB3000000), offset: Offset(0, 3), blurRadius: 8),
        ]
      : const [
          InsetShadow(color: Color(0x38000000), offset: Offset(0, 3), blurRadius: 7),
          InsetShadow(color: Color(0x99FFFFFF), offset: Offset(0, -1), blurRadius: 1),
        ];

  /// Top highlight on raised faces and panels.
  static List<InsetShadow> faceHighlight(SoftColors c) => c.isDark
      ? const [InsetShadow(color: Color(0x1FFFFFFF), offset: Offset(0, 1))]
      : const [InsetShadow(color: Color(0xFFFFFFFF), offset: Offset(0, 1))];

  static List<InsetShadow> accentHighlight(SoftColors c) =>
      const [InsetShadow(color: Color(0x73FFFFFF), offset: Offset(0, 1))];

  static List<InsetShadow> pressed(SoftColors c) => c.isDark
      ? const [InsetShadow(color: Color(0x8C000000), offset: Offset(0, 2), blurRadius: 5)]
      : const [InsetShadow(color: Color(0x33000000), offset: Offset(0, 2), blurRadius: 5)];

  static List<InsetShadow> accentPressed(SoftColors c) =>
      const [InsetShadow(color: Color(0x59782800), offset: Offset(0, 2), blurRadius: 5)];

  static List<InsetShadow> playingRow(SoftColors c) => c.isDark
      ? const [InsetShadow(color: Color(0x8C000000), offset: Offset(0, 2), blurRadius: 5)]
      : const [InsetShadow(color: Color(0x24000000), offset: Offset(0, 2), blurRadius: 4)];
}
