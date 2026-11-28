import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

/// Repeat modes the engine understands (F11).
enum EngineLoop { off, all, one }

/// What the app needs from an audio player. [JustAudioEngine] is the real one;
/// tests use a fake. The queue holds file paths, which double as track ids.
abstract class AudioEngine {
  /// Fires whenever any of the getters below may have changed.
  Stream<void> get changes;

  /// Paths of queue items that failed to play (not audio, unreadable). The
  /// engine may already have moved on to the next item when this fires.
  Stream<String> get errors;

  bool get playing;

  /// True once the last track has played to its end with repeat off.
  bool get completed;

  /// Path of the current queue item, or null when nothing is loaded.
  String? get currentPath;
  Duration get position;

  /// Length of the current file; null until it has loaded.
  Duration? get duration;

  /// Whether there is a track before/after the current one in play order.
  /// Repeat one doesn't count: the buttons still change track.
  bool get hasPrevious;
  bool get hasNext;

  /// Replaces the queue and loads [index]. Throws if the file can't be played.
  Future<void> load(List<String> paths, {required int index});
  Future<void> insert(int index, String path);
  Future<void> removeAt(int index);

  /// Starts playing; returns once the request is sent, not when playback ends.
  void play();
  Future<void> pause();
  Future<void> stop();
  Future<void> seek(Duration position);
  Future<void> seekToPrevious();
  Future<void> seekToNext();
  Future<void> setLoop(EngineLoop loop);
  Future<void> setShuffle(bool enabled);
  Future<void> dispose();
}

/// The queue index [offset] steps from [current] in play [order] (the queue
/// indices in the order they play, shuffled or not), or null past either end
/// unless [wrap].
int? neighborInPlayOrder({
  required int? current,
  required List<int> order,
  required int offset,
  required bool wrap,
}) {
  final at = current == null ? -1 : order.indexOf(current);
  if (at < 0) return null;
  final to = at + offset;
  if (to >= 0 && to < order.length) return order[to];
  return wrap ? order[to % order.length] : null;
}

class JustAudioEngine implements AudioEngine {
  /// F8: the music category ("playback" on iOS) plays with the silent switch
  /// on and keeps going when the screen locks (UIBackgroundModes audio is set
  /// in Info.plist).
  static const sessionConfiguration = AudioSessionConfiguration.music();

  /// F10: just_audio pauses for a call or alarm and resumes after it, and
  /// pauses when headphones are unplugged. This is its default; it's spelled
  /// out so it can't be turned off unnoticed.
  static const handlesInterruptions = true;

  JustAudioEngine() {
    unawaited(AudioSession.instance
        .then((s) => s.configure(sessionConfiguration))
        .catchError((Object e, StackTrace stack) {
      // Without it the silent switch mutes playback; make that visible.
      FlutterError.reportError(FlutterErrorDetails(exception: e, stack: stack, library: 'playback'));
    }));
    _subscriptions = [
      _player.playerStateStream.listen(_changed),
      _player.sequenceStateStream.listen(_changed),
      _player.durationStream.listen(_changed),
      _player.createPositionStream().listen(_changed),
      _player.errorStream.listen(_failed),
    ];
  }

  final _player = AudioPlayer(handleInterruptions: handlesInterruptions);
  final _changes = StreamController<void>.broadcast();
  final _errors = StreamController<String>.broadcast();
  late final List<StreamSubscription<Object?>> _subscriptions;

  void _changed(Object? _) => _changes.add(null);

  void _failed(PlayerException e) {
    final sequence = _player.sequence;
    final i = e.index;
    final path = i != null && i < sequence.length ? sequence[i].tag as String? : currentPath;
    if (path != null) _errors.add(path);
  }

  @override
  Stream<void> get changes => _changes.stream;

  @override
  Stream<String> get errors => _errors.stream;

  @override
  bool get playing => _player.playing;

  @override
  bool get completed => _player.processingState == ProcessingState.completed;

  @override
  String? get currentPath => _player.sequenceState.currentSource?.tag as String?;

  @override
  Duration get position => _player.position;

  @override
  Duration? get duration => _player.duration;

  @override
  bool get hasPrevious => _neighbor(-1) != null;

  @override
  bool get hasNext => _neighbor(1) != null;

  static AudioSource _source(String path) => AudioSource.file(path, tag: path);

  @override
  Future<void> load(List<String> paths, {required int index}) async {
    await _player.setAudioSources([for (final p in paths) _source(p)], initialIndex: index);
  }

  @override
  Future<void> insert(int index, String path) => _player.insertAudioSource(index, _source(path));

  @override
  Future<void> removeAt(int index) => _player.removeAudioSourceAt(index);

  @override
  void play() => unawaited(_player.play().catchError((Object e, StackTrace stack) {
        // A playback failure also arrives on errorStream, which reports it;
        // an interrupted play (another load or stop came first) is expected.
        if (e is PlayerException || e is PlayerInterruptedException) return;
        FlutterError.reportError(FlutterErrorDetails(exception: e, stack: stack, library: 'playback'));
      }));

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> seekToPrevious() => _seekToNeighbor(-1);

  @override
  Future<void> seekToNext() => _seekToNeighbor(1);

  // just_audio's own next/previous stay on the current track in repeat one,
  // so repeat one wraps like repeat all here.
  int? _neighbor(int offset) => neighborInPlayOrder(
        current: _player.currentIndex,
        order: _player.effectiveIndices,
        offset: offset,
        wrap: _player.loopMode != LoopMode.off,
      );

  Future<void> _seekToNeighbor(int offset) async {
    final index = _neighbor(offset);
    if (index != null) await _player.seek(Duration.zero, index: index);
  }

  @override
  Future<void> setLoop(EngineLoop loop) => _player.setLoopMode(switch (loop) {
        EngineLoop.off => LoopMode.off,
        EngineLoop.all => LoopMode.all,
        EngineLoop.one => LoopMode.one,
      });

  @override
  Future<void> setShuffle(bool enabled) => _player.setShuffleModeEnabled(enabled);

  @override
  Future<void> dispose() async {
    for (final s in _subscriptions) {
      await s.cancel();
    }
    await _changes.close();
    await _errors.close();
    await _player.dispose();
  }
}
