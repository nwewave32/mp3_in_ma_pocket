import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pocket_mp3/playback/audio_engine.dart';

/// The iOS settings the requirements rest on. They aren't code, so a change
/// in Xcode would otherwise go unnoticed until a device check.
void main() {
  final plist = File('ios/Runner/Info.plist').readAsStringSync();
  final project = File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync();

  /// The value after [key] in Info.plist: `true`, `false`, a string, or the strings of an array.
  Object? value(String key) {
    final m = RegExp(
            '<key>${RegExp.escape(key)}</key>\\s*(<true/>|<false/>|<string>([^<]*)</string>|<array>([\\s\\S]*?)</array>)')
        .firstMatch(plist);
    if (m == null) return null;
    if (m[1] == '<true/>') return true;
    if (m[1] == '<false/>') return false;
    if (m[2] != null) return m[2];
    return [for (final s in RegExp('<string>([^<]*)</string>').allMatches(m[3]!)) s[1]];
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

  test('the app is pocket.mp3, and its Files folder matches the first-run hint', () {
    expect(value('CFBundleDisplayName'), 'pocket.mp3');
    // The Files app names the folder after the display name.
    final hint = File('lib/design/screens/empty_library_screen.dart').readAsStringSync();
    expect(hint, contains("'Files › On My iPhone › pocket.mp3'"));
  });

  test('bundle ID', () {
    final ids = RegExp(r'PRODUCT_BUNDLE_IDENTIFIER = ([^;]+);').allMatches(project).map((m) => m[1]).toSet();
    expect(ids, {'com.ireuisu.pocketmp3', 'com.ireuisu.pocketmp3.RunnerTests'});
  });
}
