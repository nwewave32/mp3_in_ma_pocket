import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mp3_in_ma_pocket/design/licenses.dart';
import 'package:mp3_in_ma_pocket/design/screens/library_screen.dart';
import 'package:mp3_in_ma_pocket/design/theme.dart';

import 'test_helpers.dart';

/// Bundled fonts: in pubspec.yaml, on disk, used where intended, licensed.
void main() {
  testWidgets('Library track titles are in Space Grotesk with Pretendard for Hangul, the playing one SemiBold', (tester) async {
    phone(tester);
    await tester.pumpWidget(MaterialApp(
      theme: buildSoftTheme(Brightness.light),
      home: LibraryScreen(
        tracks: const [SoftTrack(id: '/a', title: 'Album'), SoftTrack(id: '/b', title: '강의 01')],
        currentIndex: 0,
        playing: true,
        progress: 0,
        onTrackTap: (_) {},
        onDelete: (_) async {},
        onImport: () {},
        onAbout: () {},
        onOpenPlayer: () {},
        onPlayPause: () {},
      ),
    ));

    TextStyle style(String text) => tester.widget<Text>(find.text(text)).style!;
    expect(style('Album').fontFamily, 'SpaceGrotesk');
    expect(style('Album').fontWeight, FontWeight.w600);
    expect(style('강의 01').fontFamily, 'SpaceGrotesk');
    // Space Grotesk has no Hangul.
    expect(style('강의 01').fontFamilyFallback, ['Pretendard']);
    expect(style('Album').fontFamilyFallback, ['Pretendard']);
    expect(style('강의 01').fontWeight, isNot(FontWeight.w600));
    // The duration column stays mono.
    expect(tester.widget<Text>(find.text('--:--').first).style!.fontFamily, 'JetBrainsMono');
  });

  test('every font file in pubspec.yaml is in the repo', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final assets = RegExp(r'- asset: (assets/fonts/\S+)').allMatches(pubspec).map((m) => m[1]!).toList();
    expect(assets, containsAll([
      'assets/fonts/SpaceGrotesk-Regular.ttf',
      'assets/fonts/SpaceGrotesk-Medium.ttf',
      'assets/fonts/SpaceGrotesk-SemiBold.ttf',
      'assets/fonts/Pretendard-Regular.otf',
      'assets/fonts/Pretendard-SemiBold.otf',
    ]));
    for (final a in assets) {
      expect(File(a).existsSync(), isTrue, reason: a);
    }
  });

  test('every bundled font has its license on the licenses page', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    registerFontLicenses();
    final packages = <String>{};
    await for (final entry in LicenseRegistry.licenses) {
      packages.addAll(entry.packages);
      // Reading the paragraphs fails if the license text is missing.
      expect(entry.paragraphs, isNotEmpty);
    }
    expect(packages, containsAll(['DotGothic16', 'Galmuri11', 'JetBrains Mono', 'Space Grotesk', 'Pretendard']));
  });

  test('the licenses are bundled', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    for (final f in ['OFL-DotGothic16.txt', 'OFL-Galmuri.txt', 'OFL-JetBrainsMono.txt', 'OFL-SpaceGrotesk.txt', 'OFL-Pretendard.txt']) {
      expect(await rootBundle.loadString('assets/licenses/$f'), contains('SIL Open Font License'), reason: f);
    }
  });
}
