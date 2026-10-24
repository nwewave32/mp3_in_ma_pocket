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

import 'test_helpers.dart';

Widget _wrap(Brightness b, Widget child) => MaterialApp(
      theme: buildSoftTheme(b),
      home: child,
    );

void main() {
  testWidgets('first run → import → library', (tester) async {
    phone(tester);
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

    await withRealIo(tester, () => tester.pumpWidget(DesignPreviewApp(library: library)));
    expect(find.text('MP3 IN MA POCKET'), findsOneWidget);

    await withRealIo(tester, () => tester.tap(find.text('Import MP3s')));

    expect(find.text('LIBRARY · 2'), findsOneWidget);
    // F4: A→Z, ".mp3" hidden, length unknown until playback reads it.
    final a = tester.getTopLeft(find.text('A song')).dy;
    final b = tester.getTopLeft(find.text('b song')).dy;
    expect(a, lessThan(b));
    expect(find.text('--:--'), findsNWidgets(2));
  });

  testWidgets('F5: a deleted track stays gone after the next import', (tester) async {
    phone(tester);
    final root = (await tester.runAsync(() => Directory.systemTemp.createTemp('delete_test')))!;
    addTearDown(() => root.deleteSync(recursive: true));
    final docs = Directory(p.join(root.path, 'Documents'))..createSync();
    for (final name in ['Old A.mp3', 'Old B.mp3']) {
      File(p.join(docs.path, name)).writeAsStringSync('ID3');
    }
    final newFile = File(p.join(root.path, 'New.mp3'))..writeAsStringSync('ID3');
    final library = Mp3Library(directory: () async => docs, picker: () async => [newFile.path]);

    await withRealIo(tester, () => tester.pumpWidget(DesignPreviewApp(library: library)));
    expect(find.text('LIBRARY · 2'), findsOneWidget);

    await tester.drag(find.text('Old A'), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(find.text('Delete this file?'), findsOneWidget);
    await tester.tap(find.text('Delete').last);
    await settleIo(tester);
    await tester.pumpAndSettle();

    expect(find.text('LIBRARY · 1'), findsOneWidget);
    expect(File(p.join(docs.path, 'Old A.mp3')).existsSync(), isFalse);

    await withRealIo(tester, () => tester.tap(find.bySemanticsLabel('Import MP3s')));

    expect(find.text('LIBRARY · 2'), findsOneWidget);
    expect(find.text('Old A'), findsNothing);
    expect(find.text('Old B'), findsOneWidget);
    expect(find.text('New'), findsOneWidget);
  });

  for (final b in Brightness.values) {
    testWidgets('Now Playing renders without overflow ($b)', (tester) async {
      phone(tester);
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
      phone(tester);
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
