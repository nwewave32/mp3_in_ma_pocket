import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:mp3_in_ma_pocket/design/design_preview.dart';
import 'package:mp3_in_ma_pocket/design/screens/about_screen.dart';
import 'package:mp3_in_ma_pocket/design/screens/now_playing_screen.dart';
import 'package:mp3_in_ma_pocket/design/theme.dart';
import 'package:mp3_in_ma_pocket/design/widgets/player_controls.dart';
import 'package:mp3_in_ma_pocket/library/mp3_library.dart';

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(1170, 2532); // iPhone 14/15, 390×844 pt
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
}

Widget _wrap(Brightness b, Widget child) => MaterialApp(
      theme: buildSoftTheme(b),
      home: child,
    );

/// Runs [action] in the real zone so the file I/O it starts can finish,
/// then rebuilds.
Future<void> _withRealIo(WidgetTester tester, Future<void> Function() action) async {
  await tester.runAsync(() async {
    await action();
    await Future<void>.delayed(const Duration(milliseconds: 100));
  });
  await tester.pump();
}

void main() {
  testWidgets('first run → import → library', (tester) async {
    _phone(tester);
    final root = (await tester.runAsync(() => Directory.systemTemp.createTemp('preview_test')))!;
    addTearDown(() => root.deleteSync(recursive: true));
    final picks = [
      for (final name in ['b song.mp3', 'A song.mp3'])
        (File(p.join(root.path, name))..writeAsStringSync('ID3')).path,
    ];
    final library = Mp3Library(
      directory: () async => Directory(p.join(root.path, 'Documents')),
      picker: () async => picks,
    );

    await _withRealIo(tester, () => tester.pumpWidget(DesignPreviewApp(library: library)));
    expect(find.text('MP3 IN MA POCKET'), findsOneWidget);

    await _withRealIo(tester, () => tester.tap(find.text('Import MP3s')));

    expect(find.text('LIBRARY · 2'), findsOneWidget);
    // F4: A→Z, ".mp3" hidden, length unknown until playback reads it.
    final a = tester.getTopLeft(find.text('A song')).dy;
    final b = tester.getTopLeft(find.text('b song')).dy;
    expect(a, lessThan(b));
    expect(find.text('--:--'), findsNWidgets(2));
  });

  for (final b in Brightness.values) {
    testWidgets('Now Playing renders without overflow ($b)', (tester) async {
      _phone(tester);
      await tester.pumpWidget(_wrap(
        b,
        NowPlayingScreen(
          title: 'Econ 101 - Lecture 03',
          trackNumber: 6,
          trackCount: 12,
          playing: true,
          position: const Duration(minutes: 12, seconds: 4),
          duration: const Duration(minutes: 48, seconds: 10),
          shuffle: false,
          repeat: SoftRepeat.all,
          onClose: () {},
          onPlayPause: () {},
          onPrevious: () {},
          onNext: () {},
          onSeek: (_) {},
          onShuffleChanged: (_) {},
          onRepeatChanged: (_) {},
        ),
      ));
      expect(tester.takeException(), isNull);
      expect(find.text('NOW PLAYING'), findsOneWidget);
    });

    testWidgets('About renders without overflow ($b)', (tester) async {
      _phone(tester);
      await tester.pumpWidget(_wrap(
        b,
        AboutScreen(
          version: '1.0.0 (1)',
          onBack: () {},
          onPrivacyPolicy: () {},
          onLicenses: () {},
        ),
      ));
      expect(tester.takeException(), isNull);
      expect(find.text('Open Source Licenses'), findsOneWidget);
    });
  }
}
