import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

import '../library/mp3_library.dart';
import 'screens/about_screen.dart';
import 'screens/empty_library_screen.dart';
import 'screens/library_screen.dart';
import 'screens/now_playing_screen.dart';
import 'theme.dart';
import 'widgets/player_controls.dart';

/// Clickable preview of "Key screens — Soft Keys" with fake playback state.
/// Importing is real (F1); replace [PreviewPlayer] with just_audio /
/// shared_preferences when wiring playback. The screens only take values and
/// callbacks.
class DesignPreviewApp extends StatefulWidget {
  const DesignPreviewApp({super.key, this.library});

  /// Defaults to the app's Documents folder and the system file picker.
  final Mp3Library? library;

  @override
  State<DesignPreviewApp> createState() => _DesignPreviewAppState();
}

class _DesignPreviewAppState extends State<DesignPreviewApp> {
  final _player = PreviewPlayer();
  late final _library = widget.library ?? Mp3Library();
  bool _importing = false;

  @override
  void initState() {
    super.initState();
    // An unreadable folder just means an empty library on launch.
    unawaited(_reload().catchError((Object _) {}, test: (e) => e is FileSystemException));
  }

  Future<void> _reload() async {
    final files = await _library.list();
    _player.setTracks([
      for (final f in files) SoftTrack(id: f.path, title: p.basenameWithoutExtension(f.path)),
    ]..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase())));
  }

  Future<void> _import(BuildContext context) async {
    if (_importing) return;
    _importing = true;
    final messenger = ScaffoldMessenger.of(context);
    String? error;
    try {
      final result = await _library.importFromPicker();
      if (result == null) return;
      await _reload();
      if (result.failed > 0) {
        error = result.failed == 1
            ? "Couldn't import 1 file."
            : "Couldn't import ${result.failed} files.";
      }
    } on PlatformException {
      error = "Couldn't open Files.";
    } on FileSystemException {
      error = "Couldn't save the files.";
    } finally {
      _importing = false;
    }
    if (error != null) messenger.showSnackBar(SnackBar(content: Text(error)));
  }

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
      home: _Home(player: _player, onImport: _import),
    );
  }
}

class _Home extends StatelessWidget {
  const _Home({required this.player, required this.onImport});

  final PreviewPlayer player;
  final void Function(BuildContext context) onImport;

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
            duration: player.lengthOf(t),
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
            onImport: () => onImport(context),
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
              : player.position.inMilliseconds / player.lengthOf(cur).inMilliseconds,
          onTrackTap: player.playAt,
          onDelete: (i) => _confirmDelete(context, i),
          onImport: () => onImport(context),
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
      if (position >= lengthOf(cur)) {
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

  /// Stand-in length until just_audio reads the real one (F6).
  Duration lengthOf(SoftTrack t) => t.duration ?? const Duration(minutes: 3);

  /// Replaces the list, keeping the current track selected if it's still there.
  void setTracks(List<SoftTrack> next) {
    final currentId = current?.id;
    tracks = next;
    final i = currentId == null ? -1 : next.indexWhere((t) => t.id == currentId);
    if (i >= 0) {
      currentIndex = i;
    } else {
      currentIndex = null;
      playing = false;
      position = Duration.zero;
    }
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
    final len = lengthOf(cur);
    position = d < Duration.zero ? Duration.zero : (d > len ? len : d);
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
