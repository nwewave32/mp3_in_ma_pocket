import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mp3_in_ma_pocket/playback/audio_engine.dart';

/// The iOS settings the requirements rest on. They aren't code, so a change
/// in Xcode would otherwise go unnoticed until a device check.
void main() {
  final plist = File('ios/Runner/Info.plist').readAsStringSync();
  final project = File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync();

  /// The value after [key] in Info.plist: `true`, `false`, or the strings of an array.
  Object? value(String key) {
    final m = RegExp('<key>${RegExp.escape(key)}</key>\\s*(<true/>|<false/>|<array>([\\s\\S]*?)</array>)')
        .firstMatch(plist);
    if (m == null) return null;
    if (m[1] == '<true/>') return true;
    if (m[1] == '<false/>') return false;
    return [for (final s in RegExp('<string>([^<]*)</string>').allMatches(m[2]!)) s[1]];
  }

  test('F2: the app folder shows in the Files app', () {
    expect(value('UIFileSharingEnabled'), isTrue);
    expect(value('LSSupportsOpeningDocumentsInPlace'), isTrue);
  });

  test('F8: audio keeps playing in the background', () {
    expect(value('UIBackgroundModes'), contains('audio'));
  });

  test('F8: the playback category, which ignores the silent switch', () {
    expect(JustAudioEngine.sessionConfiguration.avAudioSessionCategory, AVAudioSessionCategory.playback);
  });

  test('F10: calls, alarms and unplugged headphones pause the player', () {
    expect(JustAudioEngine.handlesInterruptions, isTrue);
  });

  test('iPhone only, portrait only', () {
    expect(value('UISupportedInterfaceOrientations'), ['UIInterfaceOrientationPortrait']);
    expect(value('UISupportedInterfaceOrientations~ipad'), isNull);
    final families = RegExp(r'TARGETED_DEVICE_FAMILY = ([^;]+);').allMatches(project).map((m) => m[1]).toSet();
    expect(families, {'1'});
  });
}
