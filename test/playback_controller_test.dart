import 'package:flutter_test/flutter_test.dart';

import 'package:mp3_in_ma_pocket/design/screens/library_screen.dart';
import 'package:mp3_in_ma_pocket/design/widgets/player_controls.dart';
import 'package:mp3_in_ma_pocket/playback/audio_engine.dart';
import 'package:mp3_in_ma_pocket/playback/playback_controller.dart';

import 'fake_audio_engine.dart';

List<SoftTrack> _tracks(List<String> titles) =>
    [for (final t in titles) SoftTrack(id: '/docs/$t.mp3', title: t)];

void main() {
  late FakeAudioEngine engine;
  late PlaybackController player;

  setUp(() {
    engine = FakeAudioEngine(unplayable: {'/docs/Broken.mp3'});
    player = PlaybackController(engine);
    player.setTracks(_tracks(['A', 'B', 'C']));
  });

  tearDown(() => player.dispose());

  Future<void> playAt(int i) async {
    expect(await player.playAt(i), isTrue);
  }

  group('F6', () {
    test('nothing is loaded until a track is tapped', () async {
      await pumpEventQueue();
      expect(engine.loads, 0);
      expect(player.current, isNull);
      expect(player.playing, isFalse);
    });

    test('a tapped track plays, followed by the rest of the list', () async {
      await playAt(1);

      expect(engine.queue, ['/docs/A.mp3', '/docs/B.mp3', '/docs/C.mp3']);
      expect(player.current!.title, 'B');
      expect(player.playing, isTrue);
      expect(player.duration, const Duration(minutes: 3));

      engine.finishTrack();
      expect(player.current!.title, 'C');
    });

    test('a file that cannot be played reports false and plays nothing', () async {
      player.setTracks(_tracks(['A', 'Broken']));

      expect(await player.playAt(1), isFalse);
      expect(player.current, isNull);
      expect(player.playing, isFalse);
    });

    test('a tapped track that fails once playing starts stops instead of skipping', () async {
      final failed = <String>[];
      player.failures.listen((t) => failed.add(t.title));
      await playAt(0);

      // iOS moves to the next item, then reports the error.
      engine.failCurrent();
      await pumpEventQueue();

      expect(failed, ['A']);
      expect(player.current, isNull);
      expect(engine.playing, isFalse);
    });

    test('a later track that fails is reported and playback moves on', () async {
      final failed = <String>[];
      player.failures.listen((t) => failed.add(t.title));
      await playAt(0);
      engine
        ..position = const Duration(seconds: 1)
        ..emit();
      engine.finishTrack();

      engine.failCurrent();
      await pumpEventQueue();

      expect(failed, ['B']);
      expect(player.current!.title, 'C');
      expect(player.playing, isTrue);
    });

    test('a load failure is reported too', () async {
      final failed = <String>[];
      player.failures.listen((t) => failed.add(t.title));
      player.setTracks(_tracks(['A', 'Broken']));

      await player.playAt(1);
      await pumpEventQueue();

      expect(failed, ['Broken']);
    });

    test('a load failure also on the error stream is reported once', () async {
      final e = FakeAudioEngine(unplayable: {'/docs/Broken.mp3'}, loadFailureOnErrorStream: true);
      final p = PlaybackController(e)..setTracks(_tracks(['A', 'Broken']));
      addTearDown(p.dispose);
      final failed = <String>[];
      p.failures.listen((t) => failed.add(t.title));

      expect(await p.playAt(1), isFalse);
      await pumpEventQueue();
      expect(failed, ['Broken']);

      // Tapping it again tells the user again.
      await p.playAt(1);
      await pumpEventQueue();
      expect(failed, ['Broken', 'Broken']);
    });

    test('play/pause and seek, clamped to the track', () async {
      await playAt(0);

      player.togglePlay();
      await pumpEventQueue();
      expect(player.playing, isFalse);
      player.togglePlay();
      expect(player.playing, isTrue);

      player.seek(const Duration(minutes: 10));
      await pumpEventQueue();
      expect(player.position, const Duration(minutes: 3));
      player.seek(const Duration(seconds: -1));
      await pumpEventQueue();
      expect(player.position, Duration.zero);
    });

    test('next stops at the end of the list when repeat is off', () async {
      player.setRepeat(SoftRepeat.off);
      await playAt(2);

      player.next();
      await pumpEventQueue();
      expect(player.current!.title, 'C');
    });
  });

  test('with repeat one, next and previous still change track', () async {
    player.setRepeat(SoftRepeat.one);
    await playAt(1);

    player.next();
    await pumpEventQueue();
    expect(player.current!.title, 'C');

    player.previous();
    await pumpEventQueue();
    expect(player.current!.title, 'B');
  });

  test('a list change during the first load still reaches the queue', () async {
    final loading = player.playAt(0);
    player.setTracks(_tracks(['A', 'C', 'D']));
    expect(await loading, isTrue);
    await pumpEventQueue();

    expect(engine.queue, ['/docs/A.mp3', '/docs/C.mp3', '/docs/D.mp3']);
  });

  group('F7: previous', () {
    test('3 seconds or more in goes back to the start of the track', () async {
      await playAt(1);
      engine
        ..position = const Duration(seconds: 3)
        ..emit();

      player.previous();
      await pumpEventQueue();

      expect(player.current!.title, 'B');
      expect(player.position, Duration.zero);
    });

    test('under 3 seconds goes to the previous track', () async {
      await playAt(1);
      engine
        ..position = const Duration(milliseconds: 2900)
        ..emit();

      player.previous();
      await pumpEventQueue();

      expect(player.current!.title, 'A');
    });

    test('on the first track with repeat off, restarts it', () async {
      player.setRepeat(SoftRepeat.off);
      await playAt(0);

      player.previous();
      await pumpEventQueue();

      expect(player.current!.title, 'A');
      expect(player.position, Duration.zero);
    });
  });

  group('library changes while playing', () {
    test('other tracks added or removed: the current one plays on, no reload', () async {
      await playAt(1);
      engine
        ..position = const Duration(seconds: 42)
        ..emit();

      player.setTracks(_tracks(['A0', 'B', 'C', 'D']));
      await pumpEventQueue();

      expect(engine.loads, 1);
      expect(engine.queue, [for (final t in player.tracks) t.id]);
      expect(player.current!.title, 'B');
      expect(player.currentIndex, 1);
      expect(player.playing, isTrue);
      expect(player.position, const Duration(seconds: 42));
    });

    test('the current track removed: playback stops', () async {
      await playAt(1);

      player.setTracks(_tracks(['A', 'C']));
      await pumpEventQueue();

      expect(player.current, isNull);
      expect(player.playing, isFalse);
      expect(engine.playing, isFalse);
    });
  });

  test('F11: with repeat off, the end of the last track stops on it', () async {
    player.setRepeat(SoftRepeat.off);
    await playAt(2);

    engine.finishTrack();
    await pumpEventQueue();

    expect(player.current!.title, 'C');
    expect(player.playing, isFalse);
    expect(player.position, Duration.zero);
  });

  test('repeat and shuffle reach the engine', () async {
    await pumpEventQueue();
    expect(engine.loop, EngineLoop.all);

    player.setRepeat(SoftRepeat.one);
    player.setShuffle(true);
    await pumpEventQueue();

    expect(engine.loop, EngineLoop.one);
    expect(engine.shuffle, isTrue);
  });

  test('dispose releases the engine', () async {
    final e = FakeAudioEngine();
    PlaybackController(e).dispose();
    await pumpEventQueue();
    expect(e.disposed, isTrue);
  });
}
