import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../tokens.dart';

/// Scaffold with the Soft Keys ground color and a status bar style that
/// matches light/dark.
class SoftScaffold extends StatelessWidget {
  const SoftScaffold({super.key, required this.child, this.bottom = true});

  final Widget child;
  final bool bottom;

  @override
  Widget build(BuildContext context) {
    final c = SoftColors.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: c.isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: c.ground,
        body: SafeArea(bottom: bottom, child: child),
      ),
    );
  }
}
