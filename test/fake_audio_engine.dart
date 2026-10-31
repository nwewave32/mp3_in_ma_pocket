import 'dart:async';

import 'package:mp3_in_ma_pocket/playback/audio_engine.dart';

/// An [AudioEngine] that keeps a queue in memory and plays nothing. Tests
/// move it along with [finishTrack] or by setting [position].
class FakeAudioEngine implements AudioEngine {
  FakeAudioEngine({this.unplayable = const {}, this.loadFailureOnErrorStream = false});

  /// Paths whose load fails, like a corrupt file.
  final Set<String> unplayable;

  /// Also reports a load failure on [errors], as just_audio may.
  final bool loadFailureOnErrorStream;

  final _changes = StreamController<void>.broadcast(sync: true);
  final _errors = StreamController<String>.broadcast(sync: true);
  List<String> queue = [];
  int? index;
  int loads = 0;
  EngineLoop loop = EngineLoop.off;
  bool shuffle = false;
  bool disposed = false;

  @override
  bool playing = false;
  @override
  bool completed = false;
  @override
  Duration position = Duration.zero;
  @override
  Duration? duration;

  /// Tells listeners that a field set from the test changed.
  void emit() => _changes.add(null);

  /// The current item fails to play; like iOS, the queue moves on first.
  void failCurrent() {
    final path = currentPath!;
    if (index! < queue.length - 1) _moveBy(1);
    emit();
    _errors.add(path);
  }

  /// Plays the current track to its end, as the real player would.
  void finishTrack() {
    if (loop == EngineLoop.one) {
      position = Duration.zero;
    } else if (index! < queue.length - 1 || loop == EngineLoop.all) {
      _moveBy(1);
    } else {
      position = duration ?? Duration.zero;
      completed = true;
    }
    emit();
  }

  @override
  Stream<void> get changes => _changes.stream;

  @override
  Stream<String> get errors => _errors.stream;

  @override
  String? get currentPath => index == null ? null : queue[index!];

  @override
  bool get hasPrevious => index != null && (index! > 0 || loop != EngineLoop.off);

  @override
  bool get hasNext => index != null && (index! < queue.length - 1 || loop != EngineLoop.off);

  void _moveBy(int step) {
    index = (index! + step) % queue.length;
    position = Duration.zero;
  }

  @override
  Future<void> load(List<String> paths, {required int index}) async {
    loads++;
    if (unplayable.contains(paths[index])) {
      if (loadFailureOnErrorStream) _errors.add(paths[index]);
      throw Exception('unplayable');
    }
    queue = [...paths];
    this.index = index;
    position = Duration.zero;
    duration = const Duration(minutes: 3);
    completed = false;
    emit();
  }

  @override
  Future<void> insert(int index, String path) async {
    queue.insert(index, path);
    if (this.index != null && index <= this.index!) this.index = this.index! + 1;
    emit();
  }

  @override
  Future<void> removeAt(int index) async {
    queue.removeAt(index);
    if (this.index != null && index < this.index!) this.index = this.index! - 1;
    emit();
  }

  @override
  void play() {
    playing = true;
    emit();
  }

  @override
  Future<void> pause() async {
    playing = false;
    emit();
  }

  @override
  Future<void> stop() async {
    playing = false;
    emit();
  }

  @override
  Future<void> seek(Duration position) async {
    this.position = position;
    completed = false;
    emit();
  }

  @override
  Future<void> seekToPrevious() async {
    if (hasPrevious) _moveBy(-1);
    emit();
  }

  @override
  Future<void> seekToNext() async {
    if (hasNext) _moveBy(1);
    emit();
  }

  @override
  Future<void> setLoop(EngineLoop loop) async => this.loop = loop;

  @override
  Future<void> setShuffle(bool enabled) async => shuffle = enabled;

  @override
  Future<void> dispose() async {
    disposed = true;
    await _changes.close();
    await _errors.close();
  }
}
