import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

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

  /// File name without ".mp3" (PRD decision: file names, in Files app order).
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
    this.currentDuration,
  });

  final List<SoftTrack> tracks;
  final int? currentIndex;

  /// The player's length for the current track, once loaded. Shown on its
  /// row so it matches Now Playing and the lock screen.
  final Duration? currentDuration;
  final bool playing;
  final double progress;
  final ValueChanged<int> onTrackTap;

  /// Asks for confirmation and deletes. The row closes again if the track
  /// is still in the list when this completes.
  final Future<void> Function(int index) onDelete;
  final VoidCallback onImport;
  final VoidCallback onAbout;
  final VoidCallback onOpenPlayer;
  final VoidCallback onPlayPause;

  static const double _miniPlayerSpace = 76 + 30 + 16;

  @override
  Widget build(BuildContext context) {
    final current = currentIndex == null ? null : tracks[currentIndex!];
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return SoftScaffold(
      bottom: false,
      child: Stack(
        children: [
          Column(
            children: [
              Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: _header()),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  child: _list(bottomPadding: current == null ? 24 : _miniPlayerSpace + bottomInset),
                ),
              ),
            ],
          ),
          if (current != null)
            Positioned(
              left: 12,
              right: 12,
              bottom: 30 + bottomInset * 0.4,
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

  Widget _header() => SoftHeader(
        title: 'LIBRARY · ${tracks.length}',
        // About on the left, like Back and Close on the other
        // screens, so the centered title has room for the count.
        leading: SoftSocketKey(
          socketSize: 38,
          keySize: 28,
          semanticLabel: 'About',
          onPressed: onAbout,
          child: const SoftInfoGlyph(),
        ),
        trailing: SoftSocketKey(
          socketSize: 60,
          keySize: 46,
          tone: SoftKeyTone.accent,
          semanticLabel: 'Import MP3s',
          onPressed: onImport,
          child: const Icon(Icons.add_rounded, size: 24),
        ),
      );

  Widget _list({required double bottomPadding}) => TrackListPanel(
        // Opening a row, or tapping another, closes the open one.
        child: SlidableAutoCloseBehavior(
          child: ListView.builder(
            padding: EdgeInsets.only(bottom: bottomPadding),
            itemCount: tracks.length,
            itemBuilder: (context, i) {
              final t = tracks[i];
              final length = i == currentIndex ? currentDuration ?? t.duration : t.duration;
              return _DeletableRow(
                key: ValueKey(t.id),
                onDelete: () => onDelete(i),
                builder: (onTap) => TrackRow(
                  title: t.title,
                  duration: length == null ? '--:--' : formatDuration(length),
                  playing: i == currentIndex,
                  onTap: onTap,
                ),
                onTap: () => onTrackTap(i),
              );
            },
          ),
        ),
      );
}

/// F5, iOS style: a short swipe left reveals Delete and stays open; tapping
/// it, or swiping all the way, asks for confirmation with the row still in
/// place. Nothing looks deleted until the user confirms.
class _DeletableRow extends StatefulWidget {
  const _DeletableRow({
    super.key,
    required this.onDelete,
    required this.onTap,
    required this.builder,
  });

  final Future<void> Function() onDelete;
  final VoidCallback onTap;

  /// Builds the row with the tap handler to use.
  final Widget Function(VoidCallback onTap) builder;

  @override
  State<_DeletableRow> createState() => _DeletableRowState();
}

class _DeletableRowState extends State<_DeletableRow> with SingleTickerProviderStateMixin {
  late final _slidable = SlidableController(this);

  @override
  void dispose() {
    _slidable.dispose();
    super.dispose();
  }

  Future<bool> _confirm() async {
    // Back to the revealed Delete button while the sheet asks.
    _slidable.openEndActionPane();
    try {
      await widget.onDelete();
    } catch (e, stack) {
      // Called from a gesture, so nothing above would see it.
      FlutterError.reportError(FlutterErrorDetails(exception: e, stack: stack, library: 'library'));
    }
    // A kept row closes. A deleted one closes too until the list rebuilds
    // without it on the next frame.
    if (mounted) _slidable.close();
    // The list rebuilds from the model, so the pane never dismisses the row.
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Slidable(
      // DismissiblePane needs a keyed Slidable.
      key: widget.key,
      controller: _slidable,
      endActionPane: ActionPane(
        motion: const BehindMotion(),
        extentRatio: 0.25,
        dismissible: DismissiblePane(
          confirmDismiss: () {
            HapticFeedback.mediumImpact();
            return _confirm();
          },
          onDismissed: () {},
        ),
        children: [
          Expanded(
            child: Semantics(
              button: true,
              label: 'Delete',
              excludeSemantics: true,
              onTap: _confirm,
              child: GestureDetector(onTap: _confirm, child: const TrackDeleteBackground()),
            ),
          ),
        ],
      ),
      // VoiceOver can't swipe a row, so Delete is also one of its actions.
      child: Semantics(
        customSemanticsActions: {const CustomSemanticsAction(label: 'Delete'): _confirm},
        // While open, a tap on the row closes it instead of playing.
        child: widget.builder(() => _slidable.ratio != 0 ? _slidable.close() : widget.onTap()),
      ),
    );
  }
}
