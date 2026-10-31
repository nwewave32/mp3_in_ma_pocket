import 'package:shared_preferences/shared_preferences.dart';

import '../design/widgets/player_controls.dart';

/// F12: shuffle and repeat, kept across launches in the app's preferences.
class PlaybackSettings {
  PlaybackSettings([SharedPreferencesAsync? prefs]) : _prefs = prefs ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _prefs;

  static const _shuffleKey = 'playback.shuffle';
  static const _repeatKey = 'playback.repeat';

  /// The saved modes; a missing or unknown value is null.
  Future<({bool? shuffle, SoftRepeat? repeat})> load() async {
    final shuffle = await _prefs.getBool(_shuffleKey);
    final repeat = await _prefs.getString(_repeatKey);
    return (
      shuffle: shuffle,
      repeat: SoftRepeat.values.where((r) => r.name == repeat).firstOrNull,
    );
  }

  Future<void> saveShuffle(bool value) => _prefs.setBool(_shuffleKey, value);

  Future<void> saveRepeat(SoftRepeat value) => _prefs.setString(_repeatKey, value.name);
}
