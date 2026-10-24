import 'package:flutter/material.dart';

import '../tokens.dart';
import '../typography.dart';
import '../widgets/player_controls.dart';
import '../widgets/soft_header.dart';
import '../widgets/soft_key.dart';
import '../widgets/soft_surface.dart';
import 'soft_scaffold.dart';

/// 04S / 05S · Now Playing. The one screen where the app becomes a device.
/// Drag down (or the chevron key) to close.
class NowPlayingScreen extends StatelessWidget {
  const NowPlayingScreen({
    super.key,
    required this.title,
    required this.trackNumber,
    required this.trackCount,
    required this.playing,
    required this.position,
    required this.duration,
    required this.shuffle,
    required this.repeat,
    required this.onClose,
    required this.onPlayPause,
    required this.onPrevious,
    required this.onNext,
    required this.onSeek,
    required this.onShuffleChanged,
    required this.onRepeatChanged,
  });

  final String title;
  final int trackNumber;
  final int trackCount;
  final bool playing;
  final Duration position;
  final Duration duration;
  final bool shuffle;
  final SoftRepeat repeat;
  final VoidCallback onClose;
  final VoidCallback onPlayPause;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final ValueChanged<Duration> onSeek;
  final ValueChanged<bool> onShuffleChanged;
  final ValueChanged<SoftRepeat> onRepeatChanged;

  @override
  Widget build(BuildContext context) {
    final c = SoftColors.of(context);
    String two(int n) => n.toString().padLeft(2, '0');
    return SoftScaffold(
      child: GestureDetector(
        onVerticalDragEnd: (d) {
          if ((d.primaryVelocity ?? 0) > 400) onClose();
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 5,
                  decoration: BoxDecoration(
                    color: c.grabber,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SoftHeader(
                title: 'NOW PLAYING',
                leading: SoftSocketKey(
                  socketSize: 52,
                  keySize: 40,
                  semanticLabel: 'Close',
                  onPressed: onClose,
                  child: const Icon(Icons.keyboard_arrow_down_rounded),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: SoftPanel(
                  radius: SoftRadius.device,
                  padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      LcdPanel(
                        height: 172,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('TRACK ${two(trackNumber)}/${two(trackCount)}',
                                    style: SoftText.lcdMeta(c)),
                                Text(playing ? '▶ PLAY' : '‖ PAUSE', style: SoftText.lcdMeta(c)),
                              ],
                            ),
                            Text(
                              title.toUpperCase(),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: SoftText.lcdTitle(c),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('SHUF ${shuffle ? 'ON' : 'OFF'}', style: SoftText.lcdMeta(c)),
                                Text('RPT ${repeat.label}', style: SoftText.lcdMeta(c)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      SoftSeekBar(position: position, duration: duration, onSeek: onSeek),
                      const SizedBox(height: 20),
                      Center(
                        child: SoftTransport(
                          playing: playing,
                          onPrevious: onPrevious,
                          onPlayPause: onPlayPause,
                          onNext: onNext,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SoftShuffleSwitch(value: shuffle, onChanged: onShuffleChanged),
                          SoftRepeatSelector(value: repeat, onChanged: onRepeatChanged),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
