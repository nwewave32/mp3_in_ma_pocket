import 'package:flutter/material.dart';

import '../tokens.dart';
import '../typography.dart';
import 'soft_surface.dart';

/// One library row: file name (".mp3" hidden) in Space Grotesk + mono duration.
/// The playing row sinks into the panel and gets an orange LED.
class TrackRow extends StatelessWidget {
  const TrackRow({
    super.key,
    required this.title,
    required this.duration,
    this.playing = false,
    this.showDivider = true,
    this.onTap,
  });

  final String title;
  final String duration;
  final bool playing;
  final bool showDivider;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = SoftColors.of(context);
    final row = Container(
      height: SoftSpace.rowHeight,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: showDivider ? Border(bottom: BorderSide(color: c.separator)) : null,
      ),
      child: Row(
        children: [
          if (playing) ...[
            const SoftLed(on: true, size: 10),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: playing
                  ? SoftText.trackTitleStrong(c).copyWith(color: c.accentText)
                  : SoftText.trackTitle(c),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            duration,
            style: SoftText.duration(c).copyWith(color: playing ? c.accentText : null),
          ),
        ],
      ),
    );

    return Semantics(
      button: true,
      selected: playing,
      label: '$title, $duration${playing ? ', now playing' : ''}',
      excludeSemantics: true,
      // The gesture's own tap action is excluded with the children.
      onTap: onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: playing
            ? SoftSurface(
                borderRadius: BorderRadius.zero,
                color: c.rowPlaying,
                insetShadows: SoftShadows.playingRow(c),
                child: row,
              )
            : row,
      ),
    );
  }
}

/// Red "Delete" background revealed when a row is swiped left (F5).
class TrackDeleteBackground extends StatelessWidget {
  const TrackDeleteBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final c = SoftColors.of(context);
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [c.dangerTop, c.dangerBottom],
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      // One line always: shrinks instead of wrapping in the narrow open pane
      // or with a large text size.
      child: const FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          'Delete',
          maxLines: 1,
          softWrap: false,
          style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

/// Flat list panel the rows sit on.
class TrackListPanel extends StatelessWidget {
  const TrackListPanel({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = SoftColors.of(context);
    return SoftSurface(
      borderRadius: BorderRadius.circular(SoftRadius.list),
      color: c.surface,
      shadows: SoftShadows.list(c),
      insetShadows: SoftShadows.faceHighlight(c),
      clip: true,
      child: child,
    );
  }
}
