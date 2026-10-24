import 'package:flutter/material.dart';

import '../widgets/player_controls.dart';
import '../widgets/soft_header.dart';
import '../widgets/soft_key.dart';
import '../widgets/track_row.dart';
import 'soft_scaffold.dart';

/// Minimal track model for the design layer.
@immutable
class SoftTrack {
  const SoftTrack({required this.id, required this.title, this.duration});

  final String id;

  /// File name without ".mp3" (PRD decision: file names, sorted A→Z).
  final String title;

  /// Null until the file has been read (shown as "--:--").
  final Duration? duration;
}

/// 03S · Library. Quiet flat list + floating mini player.
/// Reserve [bottomInset] for the v2 ad banner (50pt) above the mini player.
class LibraryScreen extends StatelessWidget {
  const LibraryScreen({
    super.key,
    required this.tracks,
    required this.currentIndex,
    required this.playing,
    required this.progress,
    required this.onTrackTap,
    required this.onDelete,
    required this.onImport,
    required this.onAbout,
    required this.onOpenPlayer,
    required this.onPlayPause,
  });

  final List<SoftTrack> tracks;
  final int? currentIndex;
  final bool playing;
  final double progress;
  final ValueChanged<int> onTrackTap;

  /// Return true when the user confirmed deletion.
  final Future<bool> Function(int index) onDelete;
  final VoidCallback onImport;
  final VoidCallback onAbout;
  final VoidCallback onOpenPlayer;
  final VoidCallback onPlayPause;

  static const double _miniPlayerSpace = 76 + 30 + 16;

  @override
  Widget build(BuildContext context) {
    final current = currentIndex == null ? null : tracks[currentIndex!];
    return SoftScaffold(
      bottom: false,
      child: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SoftHeader(
                  title: 'LIBRARY · ${tracks.length}',
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SoftSocketKey(
                        socketSize: 38,
                        keySize: 28,
                        semanticLabel: 'About',
                        onPressed: onAbout,
                        child: const SoftInfoGlyph(),
                      ),
                      const SizedBox(width: 4),
                      SoftSocketKey(
                        socketSize: 60,
                        keySize: 46,
                        tone: SoftKeyTone.accent,
                        semanticLabel: 'Import MP3s',
                        onPressed: onImport,
                        child: const Icon(Icons.add_rounded, size: 24),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  child: TrackListPanel(
                    child: ListView.builder(
                      padding: EdgeInsets.only(
                        bottom: current == null
                            ? 24
                            : _miniPlayerSpace + MediaQuery.paddingOf(context).bottom,
                      ),
                      itemCount: tracks.length,
                      itemBuilder: (context, i) {
                        final t = tracks[i];
                        return Dismissible(
                          key: ValueKey(t.id),
                          direction: DismissDirection.endToStart,
                          background: const TrackDeleteBackground(),
                          confirmDismiss: (_) => onDelete(i),
                          child: TrackRow(
                            title: t.title,
                            duration: t.duration == null ? '--:--' : formatDuration(t.duration!),
                            playing: i == currentIndex,
                            onTap: () => onTrackTap(i),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (current != null)
            Positioned(
              left: 12,
              right: 12,
              bottom: 30 + MediaQuery.paddingOf(context).bottom * 0.4,
              child: SoftMiniPlayer(
                title: current.title,
                progress: progress,
                playing: playing,
                onOpen: onOpenPlayer,
                onPlayPause: onPlayPause,
              ),
            ),
        ],
      ),
    );
  }
}
