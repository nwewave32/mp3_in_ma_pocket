import 'package:flutter/material.dart';

import '../tokens.dart';
import '../typography.dart';
import '../widgets/player_controls.dart';
import '../widgets/soft_header.dart';
import '../widgets/soft_key.dart';
import '../widgets/soft_surface.dart';
import 'soft_scaffold.dart';

/// 02S · First run. No "+" here: the single entry point is "Import MP3s".
/// Transport keys are shown disabled to hint where playback will happen.
class EmptyLibraryScreen extends StatelessWidget {
  const EmptyLibraryScreen({super.key, required this.onImport, required this.onAbout});

  final VoidCallback onImport;
  final VoidCallback onAbout;

  @override
  Widget build(BuildContext context) {
    final c = SoftColors.of(context);
    return SoftScaffold(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SoftHeader(
              title: 'MP3 IN MA POCKET',
              trailing: Transform.translate(
                offset: const Offset(3, 0),
                child: SoftSocketKey(
                  socketSize: 38,
                  keySize: 28,
                  semanticLabel: 'About',
                  onPressed: onAbout,
                  child: const SoftInfoGlyph(),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: SoftPanel(
                  width: 260,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      LcdPanel(
                        height: 132,
                        radius: SoftRadius.lcdSmall,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('00/00', style: SoftText.lcdMicro(c)),
                                Text('--:--', style: SoftText.lcdMicro(c)),
                              ],
                            ),
                            Text('NO TRACKS', style: SoftText.lcdHeadline(c)),
                            Text('INSERT MP3_', style: SoftText.lcd(c, size: 14)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      const SoftTransport(playing: false, compact: true),
                    ],
                  ),
                ),
              ),
            ),
            Text(
              'Load your own MP3s.\nThey never leave this phone.',
              textAlign: TextAlign.center,
              style: SoftText.callout(c),
            ),
            const SizedBox(height: 16),
            SoftPillButton(
              label: 'Import MP3s',
              icon: Icons.file_download_outlined,
              onPressed: onImport,
            ),
            const SizedBox(height: 16),
            Text.rich(
              TextSpan(
                text: 'On a Mac? Drop files into\n',
                children: [
                  TextSpan(
                    text: 'Files › On My iPhone › MP3 in ma pocket',
                    style: SoftText.footnote(c).copyWith(
                      fontWeight: FontWeight.w600,
                      color: c.text,
                    ),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
              style: SoftText.footnote(c),
            ),
          ],
        ),
      ),
    );
  }
}
