import 'dart:async';

import 'package:flutter/foundation.dart';

import '../design/screens/library_screen.dart';
import '../design/widgets/player_controls.dart';
import 'audio_engine.dart';
import 'playback_settings.dart';

/// Playback of the library (F6, F7), backed by an [AudioEngine].
///
/// The engine's queue mirrors [tracks] once a track has been started, so
/// next/previous, repeat and shuffle follow the library order. The current
/// track is tracked by path, so library changes never jump to another song.
class PlaybackController extends ChangeNotifier {
  /// With [settings], shuffle and repeat are restored and saved (F12).
  PlaybackController(this._engine, {PlaybackSettings? settings}) : _settings = settings {
    _subscriptions = [
      _engine.changes.listen((_) => _onEngineChange()),
      _engine.errors.listen(_onEngineError),
    ];
    _enqueue(() => _engine.setLoop(_loopFor(repeat)));
    // Queued, so a track tapped right at launch already plays in the saved modes.
    if (settings != null) _enqueue(() => _restore(settings));
  }

  final AudioEngine _engine;
  final PlaybackSettings? _settings;

  /// Set once the user picks a mode, so a slow restore can't undo it.
  bool _shuffleChosen = false;
  bool _repeatChosen = false;
  late final List<StreamSubscription<Object?>> _subscriptions;
  final _failures = StreamController<SoftTrack>.broadcast();

  /// The track the user tapped, until it has actually played. If it fails
  /// first, playback stops instead of quietly moving to the next track.
  String? _requested;

  /// The last failure reported since the last tap, so a load failure that
  /// arrives both as an exception and on the error stream shows once.
  String? _reported;
  List<SoftTrack> _tracks = const [];

  /// Paths in the engine's queue; empty while nothing has been started.
  List<String> _queue = const [];

  /// Engine calls run one at a time, so a queue edit never interleaves with a load.
  Future<void> _ops = Future.value();
  bool _disposed = false;

  bool shuffle = false;
  SoftRepeat repeat = SoftRepeat.all;

  List<SoftTrack> get tracks => _tracks;

  /// Tracks that couldn't be played, for a message.
  Stream<SoftTrack> get failures => _failures.stream;

  int? get currentIndex {
    if (_queue.isEmpty) return null;
    final path = _engine.currentPath;
    final i = _tracks.indexWhere((t) => t.id == path);
    return i < 0 ? null : i;
  }

  SoftTrack? get current {
    final i = currentIndex;
    return i == null ? null : _tracks[i];
  }

  bool get playing => currentIndex != null && _engine.playing;
  Duration get position => currentIndex == null ? Duration.zero : _engine.position;

  /// Length of the current track; zero until it has loaded.
  Duration get duration => (currentIndex == null ? null : _engine.duration) ?? Duration.zero;

  /// Replaces the list. The current track keeps playing if it's still there;
  /// if its file is gone (F5, or removed in the Files app), playback stops.
  void setTracks(List<SoftTrack> next) {
    _tracks = next;
    _notify();
    // Always queued: a first playAt may be loading the old list right now.
    _enqueue(_syncQueue);
  }

  /// F6: plays track [index], then the rest of the list in order. Returns
  /// false (and reports it on [failures]) if the file can't be loaded.
  Future<bool> playAt(int index) {
    final track = _tracks[index];
    final paths = [for (final t in _tracks) t.id];
    return _serial(() async {
      _queue = paths;
      _requested = track.id;
      _reported = null;
      try {
        await _engine.load(paths, index: index);
      } on Exception {
        _queue = const [];
        _requested = null;
        _report(track);
        _notify();
        return false;
      }
      _engine.play();
      _notify();
      return true;
    });
  }

  void togglePlay() => _engine.playing ? pause() : play();

  /// Resumes the current track; does nothing before one has been started.
  void play() {
    if (current == null || _engine.playing) return;
    _engine.play();
  }

  /// Pauses the current track.
  void pause() {
    if (current == null || !_engine.playing) return;
    _enqueue(_engine.pause);
  }

  /// F7: 3s or more in → back to the start, else the previous track.
  void previous() {
    if (current == null) return;
    _enqueue(() => _engine.position >= const Duration(seconds: 3) || !_engine.hasPrevious
        ? _engine.seek(Duration.zero)
        : _engine.seekToPrevious());
  }

  /// Whether [next] would move: false on the last track with repeat off.
  bool get hasNext => current != null && _engine.hasNext;

  void next() {
    if (current == null) return;
    _enqueue(() async {
      if (_engine.hasNext) await _engine.seekToNext();
    });
  }

  void seek(Duration d) {
    if (current == null) return;
    final end = duration;
    final to = d < Duration.zero ? Duration.zero : (d > end ? end : d);
    _enqueue(() => _engine.seek(to));
  }

  void setShuffle(bool v) {
    shuffle = v;
    _shuffleChosen = true;
    _notify();
    _enqueue(() async {
      await _engine.setShuffle(v);
      _notify(); // hasNext follows the new play order.
    });
    final settings = _settings;
    if (settings != null) _enqueue(() => settings.saveShuffle(v));
  }

  void setRepeat(SoftRepeat r) {
    repeat = r;
    _repeatChosen = true;
    _notify();
    _enqueue(() async {
      await _engine.setLoop(_loopFor(r));
      _notify(); // hasNext follows the new repeat mode.
    });
    final settings = _settings;
    if (settings != null) _enqueue(() => settings.saveRepeat(r));
  }

  Future<void> _restore(PlaybackSettings settings) async {
    final saved = await settings.load();
    final s = saved.shuffle;
    final r = saved.repeat;
    if (s != null && !_shuffleChosen) {
      shuffle = s;
      await _engine.setShuffle(s);
    }
    if (r != null && !_repeatChosen) {
      repeat = r;
      await _engine.setLoop(_loopFor(r));
    }
    _notify();
  }

  static EngineLoop _loopFor(SoftRepeat r) => switch (r) {
        SoftRepeat.off => EngineLoop.off,
        SoftRepeat.all => EngineLoop.all,
        SoftRepeat.one => EngineLoop.one,
      };

  void _onEngineError(String path) {
    for (final t in _tracks) {
      if (t.id == path) _report(t);
    }
    if (path != _requested) return; // Mid-list: the engine skips to the next track.
    _requested = null;
    _enqueue(() async {
      _queue = const [];
      await _engine.stop();
      _notify();
    });
  }

  void _report(SoftTrack track) {
    if (track.id == _reported || _disposed) return;
    _reported = track.id;
    _failures.add(track);
  }

  void _onEngineChange() {
    if (_requested != null &&
        _engine.currentPath == _requested &&
        _engine.position > Duration.zero) {
      _requested = null; // It plays.
    }
    // Repeat off: after the last track, stop on it, ready to play again.
    if (_engine.completed && _engine.playing) {
      _enqueue(() async {
        await _engine.pause();
        await _engine.seek(Duration.zero);
      });
    }
    _notify();
  }

  /// Edits the engine's queue in place, so the current track plays on
  /// without a gap. Both lists are in the same order (by title), so removing
  /// what's gone and inserting what's new gives exactly [tracks].
  Future<void> _syncQueue() async {
    if (_queue.isEmpty) return;
    final want = [for (final t in _tracks) t.id];
    if (!want.contains(_engine.currentPath)) {
      _queue = const [];
      await _engine.stop();
      _notify();
      return;
    }
    final queue = [..._queue];
    final keep = want.toSet();
    for (var i = queue.length - 1; i >= 0; i--) {
      if (!keep.contains(queue[i])) {
        queue.removeAt(i);
        await _engine.removeAt(i);
      }
    }
    for (var i = 0; i < want.length; i++) {
      if (i >= queue.length || queue[i] != want[i]) {
        queue.insert(i, want[i]);
        await _engine.insert(i, want[i]);
      }
    }
    _queue = queue;
    _notify();
  }

  Future<T> _serial<T>(Future<T> Function() op) {
    final result = _ops.then((_) => op());
    _ops = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }

  /// Runs [op] in turn without waiting; failures are logged, not thrown.
  void _enqueue(Future<void> Function() op) {
    unawaited(_serial(op).catchError((Object e, StackTrace stack) {
      FlutterError.reportError(FlutterErrorDetails(exception: e, stack: stack, library: 'playback'));
    }));
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    for (final s in _subscriptions) {
      unawaited(s.cancel());
    }
    unawaited(_failures.close());
    // After the calls already queued, so none of them hits a disposed player.
    _enqueue(_engine.dispose);
    super.dispose();
  }
}
