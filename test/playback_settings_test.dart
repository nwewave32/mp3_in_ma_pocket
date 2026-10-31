import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'package:mp3_in_ma_pocket/design/screens/library_screen.dart';
import 'package:mp3_in_ma_pocket/design/widgets/player_controls.dart';
import 'package:mp3_in_ma_pocket/playback/audio_engine.dart';
import 'package:mp3_in_ma_pocket/playback/playback_controller.dart';
import 'package:mp3_in_ma_pocket/playback/playback_settings.dart';

import 'fake_audio_engine.dart';

/// Preferences that can't be read, like a storage error on the device.
class _UnreadableSettings extends PlaybackSettings {
  @override
  Future<({bool? shuffle, SoftRepeat? repeat})> load() async => throw StateError('storage');
}

/// F12: shuffle and repeat survive a relaunch.
void main() {
  Future<PlaybackController> launch(FakeAudioEngine engine) async {
    final player = PlaybackController(engine, settings: PlaybackSettings());
    addTearDown(player.dispose);
    await pumpEventQueue();
    return player;
  }

  test('first launch: shuffle off, repeat all', () async {
    final engine = FakeAudioEngine();
    final player = await launch(engine);

    expect(player.shuffle, isFalse);
    expect(player.repeat, SoftRepeat.all);
    expect(engine.loop, EngineLoop.all);
  });

  test('modes chosen before are back after a relaunch, in the engine too', () async {
    final first = await launch(FakeAudioEngine());
    first
      ..setShuffle(true)
      ..setRepeat(SoftRepeat.one);
    await pumpEventQueue();

    final engine = FakeAudioEngine();
    final again = await launch(engine);

    expect(again.shuffle, isTrue);
    expect(again.repeat, SoftRepeat.one);
    expect(engine.shuffle, isTrue);
    expect(engine.loop, EngineLoop.one);
  });

  test('a choice made while the saved modes are still loading wins', () async {
    (await launch(FakeAudioEngine())).setRepeat(SoftRepeat.off);
    await pumpEventQueue();

    final engine = FakeAudioEngine();
    final player = PlaybackController(engine, settings: PlaybackSettings());
    addTearDown(player.dispose);
    player.setRepeat(SoftRepeat.one); // before the restore has run
    await pumpEventQueue();

    expect(player.repeat, SoftRepeat.one);
    expect(engine.loop, EngineLoop.one);
  });

  test('unreadable settings are logged; playback starts in the default modes', () async {
    final reported = <Object>[];
    final previous = FlutterError.onError;
    FlutterError.onError = (d) => reported.add(d.exception);
    addTearDown(() => FlutterError.onError = previous);

    final engine = FakeAudioEngine();
    final player = PlaybackController(engine, settings: _UnreadableSettings())
      ..setTracks([const SoftTrack(id: '/docs/A.mp3', title: 'A')]);
    addTearDown(player.dispose);

    expect(await player.playAt(0), isTrue);
    expect(reported.single, isStateError);
    expect(player.shuffle, isFalse);
    expect(player.repeat, SoftRepeat.all);
    expect(engine.loop, EngineLoop.all);
    expect(player.playing, isTrue);
  });

  test('an unknown saved value falls back to the default', () async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.withData({'playback.repeat': 'sometimes'});

    final player = await launch(FakeAudioEngine());

    expect(player.repeat, SoftRepeat.all);
  });
}
