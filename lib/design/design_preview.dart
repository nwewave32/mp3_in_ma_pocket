import 'dart:async';

import 'package:flutter/material.dart';

import 'screens/about_screen.dart';
import 'screens/empty_library_screen.dart';
import 'screens/library_screen.dart';
import 'screens/now_playing_screen.dart';
import 'theme.dart';
import 'widgets/player_controls.dart';

/// Clickable preview of "Key screens — Soft Keys" with fake playback state.
/// Replace [PreviewPlayer] with just_audio / shared_preferences when wiring
/// the real app; the screens only take values and callbacks.
class DesignPreviewApp extends StatefulWidget {
  const DesignPreviewApp({super.key});

  @override
  State<DesignPreviewApp> createState() => _DesignPreviewAppState();
}

class _DesignPreviewAppState extends State<DesignPreviewApp> {
  final _player = PreviewPlayer();

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MP3 in ma pocket',
      debugShowCheckedModeBanner: false,
      theme: buildSoftTheme(Brightness.light),
      darkTheme: buildSoftTheme(Brightness.dark),
      themeMode: ThemeMode.system,
      home: _Home(player: _player),
    );
  }
}

class _Home extends StatelessWidget {
  const _Home({required this.player});

  final PreviewPlayer player;

  void _openAbout(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (context) => AboutScreen(
        version: '1.0.0 (1)',
        onBack: () => Navigator.of(context).pop(),
        onPrivacyPolicy: () {},
        onLicenses: () => showLicensePage(
          context: context,
          applicationName: 'MP3 in ma pocket',
          applicationVersion: '1.0.0 (1)',
        ),
      ),
    ));
  }

  void _openPlayer(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (context) => ListenableBuilder(
        listenable: player,
        builder: (context, _) {
          final t = player.current!;
          return NowPlayingScreen(
            title: t.title,
            trackNumber: player.currentIndex! + 1,
            trackCount: player.tracks.length,
            playing: player.playing,
            position: player.position,
            duration: t.duration,
            shuffle: player.shuffle,
            repeat: player.repeat,
            onClose: () => Navigator.of(context).pop(),
            onPlayPause: player.togglePlay,
            onPrevious: player.previous,
            onNext: player.next,
            onSeek: player.seek,
            onShuffleChanged: player.setShuffle,
            onRepeatChanged: player.setRepeat,
          );
        },
      ),
    ));
  }

  Future<bool> _confirmDelete(BuildContext context, int index) async {
    final t = player.tracks[index];
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog.adaptive(
        title: const Text('Delete this file?'),
        content: Text('"${t.title}" will be removed from this app.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) player.delete(index);
    // The list rebuilds from the model, so the Dismissible itself never removes.
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: player,
      builder: (context, _) {
        if (player.tracks.isEmpty) {
          return EmptyLibraryScreen(
            onImport: player.importSamples,
            onAbout: () => _openAbout(context),
          );
        }
        final cur = player.current;
        return LibraryScreen(
          tracks: player.tracks,
          currentIndex: player.currentIndex,
          playing: player.playing,
          progress: cur == null
              ? 0
              : player.position.inMilliseconds / cur.duration.inMilliseconds,
          onTrackTap: player.playAt,
          onDelete: (i) => _confirmDelete(context, i),
          onImport: player.importSamples,
          onAbout: () => _openAbout(context),
          onOpenPlayer: () => _openPlayer(context),
          onPlayPause: player.togglePlay,
        );
      },
    );
  }
}

/// Fake player state for the preview only.
class PreviewPlayer extends ChangeNotifier {
  PreviewPlayer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final cur = current;
      if (!playing || cur == null) return;
      position += const Duration(seconds: 1);
      if (position >= cur.duration) {
        next();
      } else {
        notifyListeners();
      }
    });
  }

  late final Timer _timer;
  List<SoftTrack> tracks = const [];
  int? currentIndex;
  bool playing = false;
  Duration position = Duration.zero;
  bool shuffle = false;
  SoftRepeat repeat = SoftRepeat.all;

  SoftTrack? get current => currentIndex == null ? null : tracks[currentIndex!];

  static const _samples = [
    ('01 Night Drive', 252),
    ('02 Slow Static', 228),
    ('03 Paper Moon', 302),
    ('Audiobook - Chapter 01', 1935),
    ('Audiobook - Chapter 02', 1780),
    ('Econ 101 - Lecture 03', 2890),
    ('Econ 101 - Lecture 04', 3082),
    ('Field Recording 0914', 727),
    ('Morning Walk', 201),
    ('Voice Memo 12', 58),
    ('Weekend Mix', 3764),
    ('Zine Reading', 1110),
    ('한강 산책 녹음', 412),
  ];

  void importSamples() {
    tracks = [
      for (final (title, secs) in _samples)
        SoftTrack(id: title, title: title, duration: Duration(seconds: secs)),
    ]..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    notifyListeners();
  }

  void playAt(int i) {
    currentIndex = i;
    position = Duration.zero;
    playing = true;
    notifyListeners();
  }

  void togglePlay() {
    if (current == null) return;
    playing = !playing;
    notifyListeners();
  }

  /// F7: more than 3s in → restart, else previous track.
  void previous() {
    if (current == null) return;
    if (position.inSeconds > 3 || currentIndex == 0) {
      position = Duration.zero;
    } else {
      currentIndex = currentIndex! - 1;
      position = Duration.zero;
    }
    notifyListeners();
  }

  void next() {
    if (current == null) return;
    if (repeat == SoftRepeat.one) {
      position = Duration.zero;
    } else if (currentIndex! < tracks.length - 1) {
      currentIndex = currentIndex! + 1;
      position = Duration.zero;
    } else if (repeat == SoftRepeat.all) {
      currentIndex = 0;
      position = Duration.zero;
    } else {
      playing = false;
      position = Duration.zero;
    }
    notifyListeners();
  }

  void seek(Duration d) {
    final cur = current;
    if (cur == null) return;
    position = d < Duration.zero ? Duration.zero : (d > cur.duration ? cur.duration : d);
    notifyListeners();
  }

  void setShuffle(bool v) {
    shuffle = v;
    notifyListeners();
  }

  void setRepeat(SoftRepeat r) {
    repeat = r;
    notifyListeners();
  }

  void delete(int i) {
    final removingCurrent = i == currentIndex;
    tracks = [...tracks]..removeAt(i);
    if (removingCurrent) {
      // F5: deleting the playing track stops playback.
      currentIndex = null;
      playing = false;
      position = Duration.zero;
    } else if (currentIndex != null && i < currentIndex!) {
      currentIndex = currentIndex! - 1;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }
}
