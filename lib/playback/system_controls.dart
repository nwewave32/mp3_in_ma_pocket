import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';

import 'playback_controller.dart';

/// F9: the lock screen, Control Center and AirPods show the current track and
/// drive [PlaybackController], so their buttons follow the app's rules: F7
/// previous, and next/previous still change track in repeat one.
class SystemControls extends BaseAudioHandler {
  SystemControls(this._player) {
    _player.addListener(_sync);
    _sync();
  }

  final PlaybackController _player;

  /// Registers with iOS. Call once, with the app's player.
  static Future<SystemControls> start(PlaybackController player) => AudioService.init(
        builder: () => SystemControls(player),
        config: const AudioServiceConfig(androidNotificationChannelName: 'Playback'),
      );

  /// How far the reported position may drift before iOS gets a new one. While
  /// playing, the lock screen advances the time on its own.
  static const _drift = Duration(seconds: 1);

  void _sync() {
    final track = _player.current;
    final duration = _player.duration == Duration.zero ? null : _player.duration;
    final item = track == null ? null : MediaItem(id: track.id, title: track.title, duration: duration);
    final old = mediaItem.value;
    // MediaItem equality is by id only; the length arrives after the track loads.
    final itemChanged = item?.id != old?.id || item?.duration != old?.duration;
    if (itemChanged) mediaItem.add(item);

    final playing = _player.playing;
    final next = PlaybackState(
      controls: track == null
          ? const []
          : [
              MediaControl.skipToPrevious,
              playing ? MediaControl.pause : MediaControl.play,
              // Greyed out on the last track with repeat off.
              if (_player.hasNext) MediaControl.skipToNext,
            ],
      systemActions: track == null ? const {} : const {MediaAction.seek},
      processingState: track == null ? AudioProcessingState.idle : AudioProcessingState.ready,
      playing: playing,
      updatePosition: _player.position,
      queueIndex: _player.currentIndex,
    );
    final last = playbackState.value;
    if (itemChanged ||
        next.playing != last.playing ||
        next.processingState != last.processingState ||
        next.queueIndex != last.queueIndex ||
        !listEquals(next.controls, last.controls) ||
        (next.updatePosition - last.position).abs() > _drift) {
      playbackState.add(next);
    }
  }

  @override
  Future<void> play() async => _player.play();

  @override
  Future<void> pause() async => _player.pause();

  @override
  Future<void> stop() async => _player.pause();

  @override
  Future<void> skipToNext() async => _player.next();

  @override
  Future<void> skipToPrevious() async => _player.previous();

  @override
  Future<void> seek(Duration position) async => _player.seek(position);
}
