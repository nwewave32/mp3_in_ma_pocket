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
    return SoftScaffold(
      child: _DragToClose(
        onClose: onClose,
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
              Expanded(child: _device(c)),
            ],
          ),
        ),
      ),
    );
  }

  /// The player body: display, seek bar, transport, shuffle and repeat.
  Widget _device(SoftColors c) => SoftPanel(
        radius: SoftRadius.device,
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _display(c),
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
      );

  /// The LCD: track number, play state, title, shuffle and repeat.
  Widget _display(SoftColors c) {
    String two(int n) => n.toString().padLeft(2, '0');
    return LcdPanel(
      height: 172,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('TRACK ${two(trackNumber)}/${two(trackCount)}', style: SoftText.lcdMeta(c)),
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
    );
  }
}

/// Follows a downward drag and closes past [_distance] or on a flick, so a
/// slow pull on the grabber works as well as a quick swipe.
class _DragToClose extends StatefulWidget {
  const _DragToClose({required this.onClose, required this.child});

  final VoidCallback onClose;
  final Widget child;

  @override
  State<_DragToClose> createState() => _DragToCloseState();
}

class _DragToCloseState extends State<_DragToClose> {
  static const double _distance = 120;
  static const double _flickVelocity = 400;

  double _offset = 0;
  bool _dragging = false;

  void _end(double velocity) {
    if (_offset > _distance || velocity > _flickVelocity) {
      widget.onClose();
    } else {
      setState(() {
        _dragging = false;
        _offset = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onVerticalDragStart: (_) => setState(() => _dragging = true),
      onVerticalDragUpdate: (d) =>
          setState(() => _offset = (_offset + d.delta.dy).clamp(0.0, double.infinity)),
      onVerticalDragEnd: (d) => _end(d.primaryVelocity ?? 0),
      onVerticalDragCancel: () => _end(0),
      child: AnimatedContainer(
        duration: _dragging ? Duration.zero : SoftMotion.knob,
        curve: SoftMotion.curve,
        transform: Matrix4.translationValues(0, _offset, 0),
        child: widget.child,
      ),
    );
  }
}
