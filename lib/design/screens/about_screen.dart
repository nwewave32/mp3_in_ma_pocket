import 'package:flutter/material.dart';

import '../tokens.dart';
import '../typography.dart';
import '../widgets/soft_header.dart';
import '../widgets/soft_key.dart';
import '../widgets/soft_surface.dart';
import 'soft_scaffold.dart';

/// 08S · About: privacy promise, privacy policy, licenses, version.
class AboutScreen extends StatelessWidget {
  const AboutScreen({
    super.key,
    required this.version,
    required this.onBack,
    required this.onPrivacyPolicy,
    required this.onLicenses,
    this.copyright = '© 2026 ireuisu',
  });

  /// e.g. "1.0.0 (1)" — read from package_info_plus in the real app.
  final String version;
  final VoidCallback onBack;
  final VoidCallback onPrivacyPolicy;
  final VoidCallback onLicenses;
  final String copyright;

  @override
  Widget build(BuildContext context) {
    final c = SoftColors.of(context);
    return SoftScaffold(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SoftHeader(
              title: 'ABOUT',
              leading: SoftSocketKey(
                socketSize: 52,
                keySize: 40,
                semanticLabel: 'Back to Library',
                onPressed: onBack,
                child: const Icon(Icons.chevron_left_rounded),
              ),
            ),
            const SizedBox(height: 16),
            SoftPanel(
              radius: 32,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LcdPanel(
                    height: 112,
                    radius: 18,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('SYS INFO', style: SoftText.lcdMicro(c)),
                            Text('v$version', style: SoftText.lcdMicro(c)),
                          ],
                        ),
                        Text('MP3 IN MA POCKET', style: SoftText.lcdHeadline(c)),
                        Text('OFFLINE · NO DATA COLLECTED', style: SoftText.lcdMicro(c)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 5),
                        child: SoftLed(on: true, size: 10),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Your files stay on this phone.',
                                style: SoftText.calloutStrong(c)),
                            const SizedBox(height: 3),
                            Text(
                              "This app plays the MP3s you add. It doesn't upload them or collect any data.",
                              style: SoftText.footnote(c),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SoftSurface(
              borderRadius: BorderRadius.circular(22),
              color: c.surface,
              shadows: SoftShadows.list(c),
              insetShadows: SoftShadows.faceHighlight(c),
              clip: true,
              child: Column(
                children: [
                  _AboutRow(
                    label: 'Privacy Policy',
                    icon: Icons.open_in_new_rounded,
                    iconLabel: 'Opens in browser',
                    onTap: onPrivacyPolicy,
                  ),
                  _AboutRow(
                    label: 'Open Source Licenses',
                    icon: Icons.chevron_right_rounded,
                    onTap: onLicenses,
                  ),
                  _AboutRow(label: 'Version', value: version, divider: false),
                ],
              ),
            ),
            const Spacer(),
            Text(
              '$copyright\nMade for the MP3s in your pocket.',
              textAlign: TextAlign.center,
              style: SoftText.footnote(c),
            ),
          ],
        ),
      ),
    );
  }
}

class _AboutRow extends StatelessWidget {
  const _AboutRow({
    required this.label,
    this.icon,
    this.iconLabel,
    this.value,
    this.onTap,
    this.divider = true,
  });

  final String label;
  final IconData? icon;
  final String? iconLabel;
  final String? value;
  final VoidCallback? onTap;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    final c = SoftColors.of(context);
    final row = Container(
      height: 64,
      padding: const EdgeInsets.only(left: 18, right: 12),
      decoration: BoxDecoration(
        border: divider ? Border(bottom: BorderSide(color: c.separator)) : null,
      ),
      child: Row(
        children: [
          Expanded(child: Text(label, style: SoftText.body(c))),
          if (value != null)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Text(value!, style: SoftText.duration(c)),
            ),
          if (icon != null)
            IgnorePointer(
              child: SoftSocketKey(
                socketSize: 44,
                keySize: 34,
                iconSize: 18,
                onPressed: () {},
                child: Icon(icon),
              ),
            ),
        ],
      ),
    );
    if (onTap == null) {
      return Semantics(label: '$label ${value ?? ''}', excludeSemantics: true, child: row);
    }
    return Semantics(
      button: true,
      label: iconLabel == null ? label : '$label, $iconLabel',
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: onTap, child: row),
    );
  }
}
