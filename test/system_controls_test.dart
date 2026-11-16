import 'package:audio_service/audio_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mp3_in_ma_pocket/design/screens/library_screen.dart';
import 'package:mp3_in_ma_pocket/design/widgets/player_controls.dart';
import 'package:mp3_in_ma_pocket/playback/playback_controller.dart';
import 'package:mp3_in_ma_pocket/playback/system_controls.dart';

import 'fake_audio_engine.dart';

List<SoftTrack> _tracks(List<String> titles) =>
    [for (final t in titles) SoftTrack(id: '/docs/$t.mp3', title: t)];

/// F9: lock screen, Control Center and AirPods.
void main() {
  late FakeAudioEngine engine;
  late PlaybackController player;
  late SystemControls controls;

  setUp(() {
    engine = FakeAudioEngine();
    player = PlaybackController(engine)..setTracks(_tracks(['A', 'B', 'C']));
    controls = SystemControls(player);
  });

  tearDown(() => player.dispose());

  Future<void> playAt(int i) async {
    expect(await player.playAt(i), isTrue);
    await pumpEventQueue();
  }

  Future<void> remote(Future<void> Function() command) async {
    await command();
    await pumpEventQueue();
  }

  test('nothing is shown before a track is started', () {
    expect(controls.mediaItem.value, isNull);
    expect(controls.playbackState.value.processingState, AudioProcessingState.idle);
    expect(controls.playbackState.value.controls, isEmpty);
  });

  test('the playing track is shown with its length and the transport controls', () async {
    await playAt(1);

    final item = controls.mediaItem.value!;
    expect(item.title, 'B');
    expect(item.duration, const Duration(minutes: 3));
    final state = controls.playbackState.value;
    expect(state.playing, isTrue);
    expect(state.processingState, AudioProcessingState.ready);
    expect(state.controls, [MediaControl.skipToPrevious, MediaControl.pause, MediaControl.skipToNext]);
    expect(state.systemActions, contains(MediaAction.seek));
  });

  test('play, pause and the AirPods click', () async {
    await playAt(0);

    await remote(controls.pause);
    expect(player.playing, isFalse);
    expect(controls.playbackState.value.controls[1], MediaControl.play);

    await remote(controls.click);
    expect(player.playing, isTrue);
    await remote(controls.click);
    expect(player.playing, isFalse);

    await remote(controls.play);
    expect(player.playing, isTrue);
  });

  test('next, and previous with the F7 three-second rule', () async {
    await playAt(1);

    await remote(controls.skipToNext);
    expect(controls.mediaItem.value!.title, 'C');

    await remote(controls.skipToPrevious);
    expect(controls.mediaItem.value!.title, 'B');

    engine
      ..position = const Duration(seconds: 10)
      ..emit();
    await remote(controls.skipToPrevious);
    expect(controls.mediaItem.value!.title, 'B');
    expect(player.position, Duration.zero);
  });

  test('in repeat one, next from the lock screen still changes track', () async {
    player.setRepeat(SoftRepeat.one);
    await playAt(0);

    await remote(controls.skipToNext);

    expect(controls.mediaItem.value!.title, 'B');
  });

  test('next is greyed out on the last track with repeat off, and back with repeat all',
      () async {
    player.setRepeat(SoftRepeat.off);
    await playAt(2);
    expect(controls.playbackState.value.controls, isNot(contains(MediaControl.skipToNext)));

    player.setRepeat(SoftRepeat.all);
    await pumpEventQueue();
    expect(controls.playbackState.value.controls, contains(MediaControl.skipToNext));

    player.setRepeat(SoftRepeat.off);
    await pumpEventQueue();
    await remote(controls.skipToPrevious);
    expect(controls.mediaItem.value!.title, 'B');
    expect(controls.playbackState.value.controls, contains(MediaControl.skipToNext));
  });

  test('scrubbing on the lock screen seeks', () async {
    await playAt(0);

    await remote(() => controls.seek(const Duration(minutes: 1)));

    expect(player.position, const Duration(minutes: 1));
    expect(controls.playbackState.value.updatePosition, const Duration(minutes: 1));
  });

  test('position ticks while playing are not sent; a jump is', () async {
    await playAt(0);
    final sent = <PlaybackState>[];
    controls.playbackState.skip(1).listen(sent.add);

    for (var ms = 200; ms <= 800; ms += 200) {
      engine
        ..position = Duration(milliseconds: ms)
        ..emit();
    }
    await pumpEventQueue();
    expect(sent, isEmpty);

    engine
      ..position = const Duration(minutes: 2)
      ..emit();
    await pumpEventQueue();
    expect(sent, hasLength(1));
  });

  test('when the playing file is removed, the lock screen clears', () async {
    await playAt(1);

    player.setTracks(_tracks(['A', 'C']));
    await pumpEventQueue();

    expect(controls.mediaItem.value, isNull);
    expect(controls.playbackState.value.processingState, AudioProcessingState.idle);
  });
}
