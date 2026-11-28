import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/library_controller.dart';
import '../library/mp3_library.dart';
import '../playback/audio_engine.dart';
import '../playback/playback_controller.dart';
import '../playback/playback_settings.dart';
import '../playback/system_controls.dart';
import 'screens/about_screen.dart';
import 'screens/empty_library_screen.dart';
import 'screens/library_screen.dart';
import 'screens/now_playing_screen.dart';
import 'screens/soft_scaffold.dart';
import 'theme.dart';

/// The app on the "Key screens — Soft Keys" design: a real library
/// ([LibraryController]) and real playback ([PlaybackController]). The screens
/// only take values and callbacks.
class DesignPreviewApp extends StatefulWidget {
  const DesignPreviewApp({
    super.key,
    this.library,
    this.engine,
    this.settings,
    this.connectLockScreen,
  });

  /// Defaults to the app's Documents folder and the system file picker.
  final Mp3Library? library;

  /// Defaults to just_audio.
  final AudioEngine? engine;

  /// Defaults to the app's preferences.
  final PlaybackSettings? settings;

  /// F9: puts the player on the lock screen. Defaults to [SystemControls]
  /// with the real player, and to nothing with a test [engine].
  final Future<Object?> Function(PlaybackController player)? connectLockScreen;

  @override
  State<DesignPreviewApp> createState() => _DesignPreviewAppState();
}

class _DesignPreviewAppState extends State<DesignPreviewApp> with WidgetsBindingObserver {
  late final _player = PlaybackController(
    widget.engine ?? JustAudioEngine(),
    settings: widget.settings ?? PlaybackSettings(),
  );
  late final _library = LibraryController(widget.library ?? Mp3Library());
  final _messenger = GlobalKey<ScaffoldMessengerState>();
  late final StreamSubscription<SoftTrack> _failures;

  @override
  void initState() {
    super.initState();
    // The player plays whatever is in the library; a removed current track stops.
    _library.addListener(() => _player.setTracks(_library.tracks));
    // Failures can come from any screen, or with the app in the background.
    _failures = _player.failures.listen((t) => _messenger.currentState
        ?.showSnackBar(SnackBar(content: Text('Couldn\'t play "${t.title}".'))));
    WidgetsBinding.instance.addObserver(this);
    _library.refresh();
    final connect = widget.connectLockScreen ?? (widget.engine == null ? SystemControls.start : null);
    if (connect != null) {
      // Playback works without it, so a failure is only logged.
      unawaited(connect(_player).then<void>((_) {}, onError: (Object e, StackTrace stack) {
        FlutterError.reportError(FlutterErrorDetails(exception: e, stack: stack, library: 'playback'));
      }));
    }
  }

  /// F2: files copied in through the Files app show up when the app returns.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _library.refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _failures.cancel();
    _library.dispose();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MP3 in ma pocket',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: _messenger,
      theme: buildSoftTheme(Brightness.light),
      darkTheme: buildSoftTheme(Brightness.dark),
      themeMode: ThemeMode.system,
      home: _Home(player: _player, library: _library),
    );
  }
}

class _Home extends StatelessWidget {
  const _Home({required this.player, required this.library});

  final PlaybackController player;
  final LibraryController library;

  Future<void> _import(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    String? error;
    try {
      final result = await library.import();
      if (result != null && result.failed > 0) {
        error = result.failed == 1
            ? "Couldn't import 1 file."
            : "Couldn't import ${result.failed} files.";
      }
    } on PlatformException {
      error = "Couldn't open Files.";
    } on FileSystemException {
      error = "Couldn't save the files.";
    }
    if (error != null) messenger.showSnackBar(SnackBar(content: Text(error)));
  }

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
          final t = player.current;
          if (t == null) {
            // The track's file went away (deleted in the Files app): close.
            WidgetsBinding.instance.addPostFrameCallback((_) {
              // Only once, and only this route, even if it rebuilds while closing.
              final route = ModalRoute.of(context);
              if (context.mounted && route != null && route.isCurrent) Navigator.of(context).pop();
            });
            return const SoftScaffold(child: SizedBox.expand());
          }
          return NowPlayingScreen(
            title: t.title,
            trackNumber: player.currentIndex! + 1,
            trackCount: player.tracks.length,
            playing: player.playing,
            position: player.position,
            duration: player.duration,
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

  /// F5: confirms with an iOS action sheet; tapping outside cancels.
  Future<void> _confirmDelete(BuildContext context, int index) async {
    final t = player.tracks[index];
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showCupertinoModalPopup<bool>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        message: Text('"${t.title}" will be deleted from this app. This can\'t be undone.'),
        actions: [
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
      ),
    );
    if (ok != true) return;
    try {
      await library.delete(t);
    } on FileSystemException {
      messenger.showSnackBar(const SnackBar(content: Text("Couldn't delete the file.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([player, library]),
      builder: (context, _) {
        // Plain ground until the first read, then the first-run screen or the list.
        if (!library.loaded) return const SoftScaffold(child: SizedBox.expand());
        if (player.tracks.isEmpty) {
          return EmptyLibraryScreen(
            onImport: () => _import(context),
            onAbout: () => _openAbout(context),
          );
        }
        final cur = player.current;
        return LibraryScreen(
          tracks: player.tracks,
          currentIndex: player.currentIndex,
          playing: player.playing,
          progress: cur == null || player.duration == Duration.zero
              ? 0
              : player.position.inMilliseconds / player.duration.inMilliseconds,
          onTrackTap: player.playAt,
          onDelete: (i) => _confirmDelete(context, i),
          onImport: () => _import(context),
          onAbout: () => _openAbout(context),
          onOpenPlayer: () => _openPlayer(context),
          onPlayPause: player.togglePlay,
          currentDuration: player.duration == Duration.zero ? null : player.duration,
        );
      },
    );
  }
}
