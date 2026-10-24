import 'package:flutter/material.dart';

import '../tokens.dart';
import '../typography.dart';

/// Paints inner shadows clipped to a rounded rect.
class InsetShadowPainter extends CustomPainter {
  const InsetShadowPainter({required this.borderRadius, required this.shadows});

  final BorderRadius borderRadius;
  final List<InsetShadow> shadows;

  @override
  void paint(Canvas canvas, Size size) {
    if (shadows.isEmpty || size.isEmpty) return;
    final bounds = Offset.zero & size;
    final rrect = borderRadius.toRRect(bounds);
    canvas.save();
    canvas.clipRRect(rrect);
    for (final s in shadows) {
      final paint = Paint()..color = s.color;
      if (s.blurRadius > 0) {
        paint.maskFilter =
            MaskFilter.blur(BlurStyle.normal, Shadow.convertRadiusToSigma(s.blurRadius));
      }
      final spread = s.blurRadius * 2 + s.offset.distance + 4;
      final path = Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(bounds.inflate(spread))
        ..addRRect(rrect.shift(s.offset));
      canvas.drawPath(path, paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(InsetShadowPainter old) =>
      old.borderRadius != borderRadius || old.shadows != shadows;
}

/// Base building block: a rounded box with fill, drop shadows and inner
/// shadows. Everything in the Soft Keys look is a SoftSurface.
class SoftSurface extends StatelessWidget {
  const SoftSurface({
    super.key,
    required this.borderRadius,
    this.color,
    this.gradient,
    this.shadows = const [],
    this.insetShadows = const [],
    this.width,
    this.height,
    this.padding,
    this.alignment,
    this.clip = false,
    this.child,
  });

  final BorderRadius borderRadius;
  final Color? color;
  final Gradient? gradient;
  final List<BoxShadow> shadows;
  final List<InsetShadow> insetShadows;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final AlignmentGeometry? alignment;

  /// Clip the child to the rounded shape (lists, LCD scrollers).
  final bool clip;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    Widget? content = child;
    if (content != null && alignment != null) {
      // Hug the child on axes without a fixed size (e.g. transport socket).
      content = Align(
        alignment: alignment!,
        widthFactor: width == null ? 1 : null,
        heightFactor: height == null ? 1 : null,
        child: content,
      );
    }
    if (padding != null) {
      content = Padding(padding: padding!, child: content);
    }
    if (clip && content != null) {
      content = ClipRRect(borderRadius: borderRadius, child: content);
    }
    return SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: gradient == null ? color : null,
          gradient: gradient,
          borderRadius: borderRadius,
          boxShadow: shadows,
        ),
        // Inner shadows are drawn over the fill but under the content.
        child: CustomPaint(
          painter: InsetShadowPainter(borderRadius: borderRadius, shadows: insetShadows),
          child: content ?? const SizedBox.shrink(),
        ),
      ),
    );
  }
}

/// Recessed socket that keys, switches and sliders sit in.
class SoftWell extends StatelessWidget {
  const SoftWell({
    super.key,
    this.width,
    this.height,
    this.radius = SoftRadius.pill,
    this.padding,
    this.alignment = Alignment.center,
    this.child,
  });

  final double? width;
  final double? height;
  final double radius;
  final EdgeInsetsGeometry? padding;
  final AlignmentGeometry? alignment;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final c = SoftColors.of(context);
    return SoftSurface(
      width: width,
      height: height,
      borderRadius: BorderRadius.circular(radius),
      color: c.well,
      shadows: SoftShadows.wellRim(c),
      insetShadows: SoftShadows.well(c),
      padding: padding,
      alignment: alignment,
      child: child,
    );
  }
}

/// Raised device panel (the "body" of the player).
class SoftPanel extends StatelessWidget {
  const SoftPanel({
    super.key,
    this.width,
    this.height,
    this.radius = SoftRadius.panel,
    this.padding = const EdgeInsets.all(22),
    this.floating = false,
    required this.child,
  });

  final double? width;
  final double? height;
  final double radius;
  final EdgeInsetsGeometry padding;

  /// Use the tighter floating shadow (mini player).
  final bool floating;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = SoftColors.of(context);
    return SoftSurface(
      width: width,
      height: height,
      borderRadius: BorderRadius.circular(radius),
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [c.panelTop, c.panelBottom],
      ),
      shadows: floating ? SoftShadows.floating(c) : SoftShadows.panel(c),
      insetShadows: SoftShadows.faceHighlight(c),
      padding: padding,
      child: child,
    );
  }
}

/// Recessed LCD window. Light: green-gray with dark ink. Dark: black with
/// orange glowing ink. Sets the LCD text style for its subtree.
class LcdPanel extends StatelessWidget {
  const LcdPanel({
    super.key,
    this.width,
    this.height,
    this.radius = SoftRadius.lcd,
    this.padding = const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
    this.clip = false,
    required this.child,
  });

  final double? width;
  final double? height;
  final double radius;
  final EdgeInsetsGeometry padding;
  final bool clip;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = SoftColors.of(context);
    return SoftSurface(
      width: width,
      height: height,
      borderRadius: BorderRadius.circular(radius),
      color: c.lcd,
      shadows: SoftShadows.wellRim(c),
      insetShadows: SoftShadows.lcd(c),
      padding: padding,
      clip: clip,
      child: DefaultTextStyle(style: SoftText.lcd(c), child: child),
    );
  }
}

/// Small status LED (shuffle/repeat on, now-playing marker).
class SoftLed extends StatelessWidget {
  const SoftLed({super.key, required this.on, this.size = 8});

  final bool on;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = SoftColors.of(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: on ? c.accent : c.ledOff,
        boxShadow: on ? [BoxShadow(color: c.accent, blurRadius: size * 0.75)] : null,
      ),
    );
  }
}
