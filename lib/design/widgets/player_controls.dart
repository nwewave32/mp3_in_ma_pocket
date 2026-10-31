import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../tokens.dart';
import '../typography.dart';
import 'soft_key.dart';
import 'soft_surface.dart';

/// Repeat cycles off → all → one (F11).
enum SoftRepeat { off, all, one }

extension SoftRepeatLabel on SoftRepeat {
  String get label => switch (this) {
        SoftRepeat.off => 'OFF',
        SoftRepeat.all => 'ALL',
        SoftRepeat.one => 'ONE',
      };
}

/// Formats seconds as m:ss or h:mm:ss.
String formatDuration(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return h > 0 ? '$h:${m.toString().padLeft(2, '0')}:$s' : '$m:$s';
}

/// Prev / Play-Pause / Next in one shared socket.
class SoftTransport extends StatelessWidget {
  const SoftTransport({
    super.key,
    required this.playing,
    this.onPrevious,
    this.onPlayPause,
    this.onNext,
    this.compact = false,
  });

  final bool playing;
  final VoidCallback? onPrevious;
  final VoidCallback? onPlayPause;
  final VoidCallback? onNext;

  /// Compact = first-run device (48 / 88×50). Regular = Now Playing (66 / 136×70).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final side = compact ? 48.0 : 66.0;
    final playW = compact ? 88.0 : 136.0;
    final playH = compact ? 50.0 : 70.0;
    return SoftWell(
      height: compact ? 66 : 88,
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SoftKey(
            width: side,
            height: side,
            iconSize: compact ? 20 : 26,
            semanticLabel: 'Previous',
            onPressed: onPrevious,
            child: const Icon(Icons.skip_previous_rounded),
          ),
          SizedBox(width: compact ? 6 : 8),
          SoftKey(
            width: playW,
            height: playH,
            tone: SoftKeyTone.accent,
            iconSize: compact ? 26 : 34,
            semanticLabel: playing ? 'Pause' : 'Play',
            onPressed: onPlayPause,
            child: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
          ),
          SizedBox(width: compact ? 6 : 8),
          SoftKey(
            width: side,
            height: side,
            iconSize: compact ? 20 : 26,
            semanticLabel: 'Next',
            onPressed: onNext,
            child: const Icon(Icons.skip_next_rounded),
          ),
        ],
      ),
    );
  }
}

/// Seek bar: recessed track, orange progress, pill thumb with grip lines.
class SoftSeekBar extends StatelessWidget {
  const SoftSeekBar({
    super.key,
    required this.position,
    required this.duration,
    this.onSeek,
  });

  final Duration position;
  final Duration duration;
  final ValueChanged<Duration>? onSeek;

  double get _value => duration.inMilliseconds == 0
      ? 0
      : (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final c = SoftColors.of(context);
    final remaining = duration - position;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(builder: (context, constraints) {
          final w = constraints.maxWidth;
          void seekTo(double dx) {
            if (onSeek == null || w <= 0) return;
            final t = (dx / w).clamp(0.0, 1.0);
            onSeek!(Duration(milliseconds: (duration.inMilliseconds * t).round()));
          }

          const thumbW = 60.0;
          final thumbLeft = (_value * w - thumbW / 2).clamp(0.0, w - thumbW);
          return Semantics(
            slider: true,
            label: 'Seek',
            value: formatDuration(position),
            increasedValue: formatDuration(position + const Duration(seconds: 15)),
            decreasedValue: formatDuration(position - const Duration(seconds: 15)),
            onIncrease: onSeek == null
                ? null
                : () => onSeek!(position + const Duration(seconds: 15)),
            onDecrease: onSeek == null
                ? null
                : () => onSeek!(position - const Duration(seconds: 15)),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (d) => seekTo(d.localPosition.dx),
              onHorizontalDragUpdate: (d) => seekTo(d.localPosition.dx),
              child: SizedBox(
                height: 44,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.centerLeft,
                  children: [
                    SoftWell(
                      width: w,
                      height: 30,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.all(5),
                      child: FractionallySizedBox(
                        widthFactor: _value,
                        heightFactor: 1,
                        child: SoftSurface(
                          borderRadius: BorderRadius.circular(SoftRadius.pill),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [c.accentTop, c.accentBottom],
                          ),
                          insetShadows: SoftShadows.accentHighlight(c),
                        ),
                      ),
                    ),
                    Positioned(
                      left: thumbLeft,
                      child: SoftSurface(
                        width: thumbW,
                        height: 36,
                        borderRadius: BorderRadius.circular(SoftRadius.pill),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [c.faceTop, c.faceBottom],
                        ),
                        shadows: SoftShadows.key(c),
                        insetShadows: SoftShadows.faceHighlight(c),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(
                            3,
                            (i) => Container(
                              width: 2,
                              height: 12,
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              decoration: BoxDecoration(
                                color: c.grip,
                                borderRadius: BorderRadius.circular(1),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(formatDuration(position), style: SoftText.time(c)),
            Text('-${formatDuration(remaining)}', style: SoftText.time(c)),
          ],
        ),
      ],
    );
  }
}

/// Shuffle on/off switch with LED on the knob.
class SoftShuffleSwitch extends StatelessWidget {
  const SoftShuffleSwitch({super.key, required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = SoftColors.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          toggled: value,
          label: 'Shuffle',
          excludeSemantics: true,
          onTap: () => onChanged(!value),
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onChanged(!value);
            },
            child: SoftWell(
              width: 92,
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              alignment: null,
              child: AnimatedAlign(
                duration: SoftMotion.knob,
                curve: SoftMotion.curve,
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: _Knob(width: 50, child: SoftLed(on: value)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text('SHUFFLE', style: SoftText.microLabel(c)),
      ],
    );
  }
}

/// Three-position repeat selector: OFF / ALL / ONE.
class SoftRepeatSelector extends StatelessWidget {
  const SoftRepeatSelector({super.key, required this.value, required this.onChanged});

  final SoftRepeat value;
  final ValueChanged<SoftRepeat> onChanged;

  static const double _width = 174;
  static const double _knob = 54;

  @override
  Widget build(BuildContext context) {
    final c = SoftColors.of(context);
    final slot = (_width - 8 - _knob) / 2;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // F11: tapping the switch steps off → all → one → off; the labels
        // below pick a mode directly. Semantics come from the labels.
        ExcludeSemantics(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              HapticFeedback.selectionClick();
              onChanged(SoftRepeat.values[(value.index + 1) % SoftRepeat.values.length]);
            },
            child: SoftWell(
              width: _width,
              height: 44,
              alignment: null,
              child: Stack(
                children: [
                  AnimatedPositioned(
                    duration: SoftMotion.knob,
                    curve: SoftMotion.curve,
                    top: 4,
                    left: 4 + slot * value.index,
                    child: _Knob(width: _knob, child: SoftLed(on: value != SoftRepeat.off)),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(
          width: _width,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final r in SoftRepeat.values)
                Semantics(
                  inMutuallyExclusiveGroup: true,
                  checked: r == value,
                  label: 'Repeat ${r.label.toLowerCase()}',
                  excludeSemantics: true,
                  onTap: () => onChanged(r),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onChanged(r);
                    },
                    child: SizedBox(
                      width: 58,
                      height: 44,
                      child: Center(
                        child: Text(
                          r.label,
                          style: SoftText.microLabel(c).copyWith(
                            color: r == value ? c.text : c.textSecondary,
                            fontWeight: r == value ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Knob extends StatelessWidget {
  const _Knob({required this.width, required this.child});

  final double width;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = SoftColors.of(context);
    return SoftSurface(
      width: width,
      height: 36,
      borderRadius: BorderRadius.circular(SoftRadius.pill),
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [c.faceTop, c.faceBottom],
      ),
      shadows: SoftShadows.key(c),
      insetShadows: SoftShadows.faceHighlight(c),
      alignment: Alignment.center,
      child: child,
    );
  }
}

/// Floating mini player: LCD strip (tap → Now Playing) + play/pause key.
class SoftMiniPlayer extends StatelessWidget {
  const SoftMiniPlayer({
    super.key,
    required this.title,
    required this.progress,
    required this.playing,
    this.onOpen,
    this.onPlayPause,
  });

  final String title;
  final double progress;
  final bool playing;
  final VoidCallback? onOpen;
  final VoidCallback? onPlayPause;

  @override
  Widget build(BuildContext context) {
    final c = SoftColors.of(context);
    return SoftPanel(
      height: 76,
      radius: SoftRadius.pill,
      floating: true,
      padding: const EdgeInsets.only(left: 14, right: 8),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              button: true,
              label: 'Open Now Playing: $title',
              excludeSemantics: true,
              onTap: onOpen,
              child: GestureDetector(
                onTap: onOpen,
                child: LcdPanel(
                  height: 48,
                  radius: SoftRadius.pill,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        title.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: SoftText.lcd(c, size: 15),
                      ),
                      const SizedBox(height: 5),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 3,
                          backgroundColor: c.lcdInk.withValues(alpha: 0.2),
                          valueColor: AlwaysStoppedAnimation(c.lcdInk),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 2),
          SoftSocketKey(
            socketSize: 60,
            keySize: 48,
            tone: SoftKeyTone.accent,
            semanticLabel: playing ? 'Pause' : 'Play',
            onPressed: onPlayPause,
            child: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
          ),
        ],
      ),
    );
  }
}
