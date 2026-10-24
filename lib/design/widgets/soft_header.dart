import 'package:flutter/material.dart';

import '../tokens.dart';
import '../typography.dart';

/// Screen header: centered mono uppercase title with optional leading and
/// trailing controls. Used on every Soft Keys screen.
class SoftHeader extends StatelessWidget {
  const SoftHeader({super.key, required this.title, this.leading, this.trailing});

  final String title;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = SoftColors.of(context);
    return SizedBox(
      height: SoftSpace.headerHeight,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Semantics(
            header: true,
            child: Text(title, style: SoftText.headerLabel(c), textAlign: TextAlign.center),
          ),
          if (leading != null) Align(alignment: Alignment.centerLeft, child: leading),
          if (trailing != null) Align(alignment: Alignment.centerRight, child: trailing),
        ],
      ),
    );
  }
}

/// The small ⓘ glyph used on the About key.
class SoftInfoGlyph extends StatelessWidget {
  const SoftInfoGlyph({super.key, this.size = 13});

  final double size;

  @override
  Widget build(BuildContext context) {
    final color = IconTheme.of(context).color;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _InfoPainter(color ?? const Color(0xFF5E646A))),
    );
  }
}

class _InfoPainter extends CustomPainter {
  _InfoPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3 * s
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(12 * s, 10.5 * s), Offset(12 * s, 18.5 * s), paint);
    canvas.drawCircle(Offset(12 * s, 5.5 * s), 1.6 * s, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_InfoPainter old) => old.color != color;
}
