import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../tokens.dart';
import 'soft_surface.dart';

enum SoftKeyTone {
  /// Gray key: prev/next, close, about, secondary actions.
  neutral,

  /// Orange key: play/pause, import. One per area.
  accent,
}

/// The visual face of a key (no gestures).
class SoftKeyFace extends StatelessWidget {
  const SoftKeyFace({
    super.key,
    required this.width,
    required this.height,
    this.radius,
    this.tone = SoftKeyTone.neutral,
    this.pressed = false,
    this.enabled = true,
    this.iconSize = 22,
    required this.child,
  });

  final double width;
  final double height;
  final double? radius;
  final SoftKeyTone tone;
  final bool pressed;
  final bool enabled;
  final double iconSize;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = SoftColors.of(context);
    final accent = tone == SoftKeyTone.accent && enabled;
    final List<Color> colors;
    final List<BoxShadow> shadows;
    final List<InsetShadow> insets;
    if (accent) {
      colors = pressed
          ? [c.accentPressedTop, c.accentPressedBottom]
          : [c.accentTop, c.accentBottom];
      shadows = pressed ? const [] : SoftShadows.accentKey(c);
      insets = pressed ? SoftShadows.accentPressed(c) : SoftShadows.accentHighlight(c);
    } else {
      colors = pressed
          ? [c.facePressedTop, c.facePressedBottom]
          : [c.faceTop, c.faceBottom];
      shadows = pressed ? const [] : SoftShadows.key(c);
      insets = pressed ? SoftShadows.pressed(c) : SoftShadows.faceHighlight(c);
    }
    final fg = accent ? c.onAccent : (enabled ? c.icon : c.iconDisabled);

    return AnimatedContainer(
      duration: SoftMotion.press,
      curve: SoftMotion.curve,
      transform: Matrix4.translationValues(0, pressed ? SoftMotion.pressSink : 0, 0),
      child: SoftSurface(
        width: width,
        height: height,
        borderRadius: BorderRadius.circular(radius ?? height / 2),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
        ),
        shadows: shadows,
        insetShadows: insets,
        alignment: Alignment.center,
        child: IconTheme.merge(
          data: IconThemeData(color: fg, size: iconSize),
          child: DefaultTextStyle.merge(
            style: TextStyle(color: fg),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Shared press behaviour: tracks pressed state, light haptic on tap,
/// button semantics. [builder] receives the pressed flag.
class _Pressable extends StatefulWidget {
  const _Pressable({
    required this.onPressed,
    required this.semanticLabel,
    required this.builder,
  });

  final VoidCallback? onPressed;
  final String? semanticLabel;
  final Widget Function(BuildContext context, bool pressed) builder;

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null;

  void _set(bool v) {
    if (_enabled && _pressed != v) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.semanticLabel,
      excludeSemantics: widget.semanticLabel != null,
      // Excluding the children also drops the gesture's tap action.
      onTap: widget.semanticLabel != null && _enabled ? widget.onPressed : null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _set(true),
        onTapUp: (_) => _set(false),
        onTapCancel: () => _set(false),
        onTap: _enabled
            ? () {
                HapticFeedback.lightImpact();
                widget.onPressed!();
              }
            : null,
        child: widget.builder(context, _pressed),
      ),
    );
  }
}

/// A raised key without its own socket — use inside a shared [SoftWell]
/// (e.g. the prev / play / next transport capsule).
/// Disabled when [onPressed] is null.
class SoftKey extends StatelessWidget {
  const SoftKey({
    super.key,
    required this.child,
    required this.onPressed,
    this.width = 56,
    this.height = 56,
    this.radius,
    this.tone = SoftKeyTone.neutral,
    this.iconSize = 22,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final double width;
  final double height;
  final double? radius;
  final SoftKeyTone tone;
  final double iconSize;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return _Pressable(
      onPressed: onPressed,
      semanticLabel: semanticLabel,
      builder: (context, pressed) => SoftKeyFace(
        width: width,
        height: height,
        radius: radius,
        tone: tone,
        pressed: pressed,
        enabled: onPressed != null,
        iconSize: iconSize,
        child: child,
      ),
    );
  }
}

/// A key in its own round/pill socket, with a hit area of at least
/// [SoftSpace.minTap] even when the visual is smaller (e.g. the ⓘ key).
class SoftSocketKey extends StatelessWidget {
  const SoftSocketKey({
    super.key,
    required this.child,
    required this.onPressed,
    this.socketSize = 60,
    this.keySize = 46,
    this.tone = SoftKeyTone.neutral,
    this.iconSize = 20,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final double socketSize;
  final double keySize;
  final SoftKeyTone tone;
  final double iconSize;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final hit = socketSize < SoftSpace.minTap ? SoftSpace.minTap : socketSize;
    return _Pressable(
      onPressed: onPressed,
      semanticLabel: semanticLabel,
      builder: (context, pressed) => SizedBox(
        width: hit,
        height: hit,
        child: Center(
          child: SoftWell(
            width: socketSize,
            height: socketSize,
            child: SoftKeyFace(
              width: keySize,
              height: keySize,
              tone: tone,
              pressed: pressed,
              enabled: onPressed != null,
              iconSize: iconSize,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// A full-width pill button in a pill socket (e.g. "Import MP3s").
class SoftPillButton extends StatelessWidget {
  const SoftPillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.tone = SoftKeyTone.accent,
    this.height = 60,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final SoftKeyTone tone;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = SoftColors.of(context);
    final fg = tone == SoftKeyTone.accent ? c.onAccent : c.text;
    return SoftWell(
      height: height + 16,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: LayoutBuilder(
        builder: (context, constraints) => _Pressable(
          onPressed: onPressed,
          semanticLabel: label,
          builder: (context, pressed) => SoftKeyFace(
            width: constraints.maxWidth,
            height: height,
            tone: tone,
            pressed: pressed,
            enabled: onPressed != null,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: fg),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
