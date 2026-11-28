import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:pocket_mp3/design/design_preview.dart';
import 'package:pocket_mp3/design/screens/about_screen.dart';
import 'package:pocket_mp3/design/screens/library_screen.dart';
import 'package:pocket_mp3/design/screens/now_playing_screen.dart';
import 'package:pocket_mp3/design/theme.dart';
import 'package:pocket_mp3/design/widgets/player_controls.dart';
import 'package:pocket_mp3/design/widgets/track_row.dart';
import 'package:pocket_mp3/library/mp3_library.dart';

import 'fake_audio_engine.dart';
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

    await withRealIo(tester, () => tester.pumpWidget(DesignPreviewApp(library: library, engine: FakeAudioEngine())));
    expect(find.text('POCKET.MP3'), findsOneWidget);

    await withRealIo(tester, () => tester.tap(find.text('Import MP3s')));

    expect(find.text('LIBRARY · 2'), findsOneWidget);
    // F4: A→Z, ".mp3" hidden; files with no audio frame have no length.
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

    await withRealIo(tester, () => tester.pumpWidget(DesignPreviewApp(library: library, engine: FakeAudioEngine())));
    expect(find.text('LIBRARY · 2'), findsOneWidget);

    await swipeAllTheWay(tester, 'Old A');
    expect(find.textContaining("can't be undone"), findsOneWidget);
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

  group('F5: delete asks with the row still in place', () {
    late Directory docs;

    Future<void> start(WidgetTester tester) async {
      phone(tester);
      final root = await tempRoot(tester, 'swipe_test');
      docs = Directory(p.join(root.path, 'Documents'))..createSync();
      for (final name in ['Old A.mp3', 'Old B.mp3']) {
        File(p.join(docs.path, name)).writeAsStringSync('ID3');
      }
      final library = Mp3Library(directory: () async => docs, picker: () async => const []);
      await tester.pumpWidget(DesignPreviewApp(library: library, engine: FakeAudioEngine()));
      await settleIo(tester);
    }

    Finder sheet() => find.byType(CupertinoActionSheet);
    // Not slid away: the title is still on screen.
    bool rowOnScreen(WidgetTester tester) => tester.getCenter(find.text('Old A')).dx > 0;

    testWidgets('a short swipe reveals Delete and stays open; tapping it asks', (tester) async {
      await start(tester);

      await tester.drag(find.text('Old A'), const Offset(-80, 0));
      await tester.pumpAndSettle();
      expect(sheet(), findsNothing);
      expect(find.bySemanticsLabel('Delete'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Delete'));
      await tester.pumpAndSettle();
      expect(sheet(), findsOneWidget);
      expect(rowOnScreen(tester), isTrue);
    });

    for (final scale in [1.0, 1.5]) {
      testWidgets('the open Delete label stays on one line on a small phone (text ×$scale)',
          (tester) async {
        await start(tester);
        tester.view.physicalSize = const Size(750, 1334); // iPhone SE, 375×667 pt
        tester.view.devicePixelRatio = 2.0;
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await tester.pumpAndSettle();

        await tester.drag(find.text('Old A'), const Offset(-80, 0));
        await tester.pumpAndSettle();

        final pane = tester.getRect(find.byType(TrackDeleteBackground));
        final label = tester.getRect(find.text('Delete'));
        expect(label.height, lessThan(15 * scale * 1.5), reason: 'wrapped onto two lines');
        expect(pane.contains(label.topLeft) && pane.contains(label.bottomRight - const Offset(1, 1)),
            isTrue, reason: 'label spills out of the pane');
      });
    }

    testWidgets('a full swipe asks at once; cancelling outside closes the row and keeps the file',
        (tester) async {
      await start(tester);

      await swipeAllTheWay(tester, 'Old A');
      expect(sheet(), findsOneWidget);
      expect(rowOnScreen(tester), isTrue);

      await tester.tapAt(const Offset(195, 100)); // outside the sheet
      await tester.pumpAndSettle();
      expect(sheet(), findsNothing);
      expect(find.bySemanticsLabel('Delete'), findsNothing);
      expect(tester.getTopLeft(find.text('Old A')).dx,
          tester.getTopLeft(find.text('Old B')).dx);
      expect(File(p.join(docs.path, 'Old A.mp3')).existsSync(), isTrue);
    });

    testWidgets('tapping an open row closes it instead of playing', (tester) async {
      await start(tester);
      await tester.drag(find.text('Old A'), const Offset(-80, 0));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Old A'));
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Delete'), findsNothing);
      expect(find.byType(SoftMiniPlayer), findsNothing);
    });

    testWidgets('VoiceOver can tap rows, keys, the mini player and the open Delete button',
        (tester) async {
      final semantics = tester.ensureSemantics();
      await start(tester);

      Future<void> voiceOverTap(Pattern label) async {
        final node = tester.getSemantics(find.bySemanticsLabel(label));
        expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue, reason: '$label');
        node.owner!.performAction(node.id, SemanticsAction.tap);
        await tester.pumpAndSettle();
      }

      await voiceOverTap(RegExp('^Old A'));
      expect(find.byType(SoftMiniPlayer), findsOneWidget);

      await voiceOverTap('Open Now Playing: Old A');
      expect(find.text('NOW PLAYING'), findsOneWidget);
      await voiceOverTap('Repeat one');
      expect(find.text('RPT ONE'), findsOneWidget);
      await voiceOverTap('Pause');
      expect(find.text('‖ PAUSE'), findsOneWidget);
      await voiceOverTap('Close');

      await tester.drag(find.text('Old B'), const Offset(-80, 0));
      await tester.pumpAndSettle();
      await voiceOverTap('Delete');
      expect(sheet(), findsOneWidget);
      semantics.dispose();
    });

    testWidgets("VoiceOver can delete through the row's actions", (tester) async {
      final semantics = tester.ensureSemantics();
      await start(tester);

      final row = tester.getSemantics(find.bySemanticsLabel(RegExp('^Old A')));
      final id = CustomSemanticsAction.getIdentifier(const CustomSemanticsAction(label: 'Delete'));
      expect(row.getSemanticsData().customSemanticsActionIds, contains(id));

      row.owner!.performAction(row.id, SemanticsAction.customAction, id);
      await tester.pumpAndSettle();
      expect(sheet(), findsOneWidget);
      semantics.dispose();
    });
  });

  Widget nowPlaying({VoidCallback? onClose, SoftRepeat repeat = SoftRepeat.all, ValueChanged<SoftRepeat>? onRepeat}) =>
      _wrap(
        Brightness.light,
        NowPlayingScreen(
          title: 'Lecture 01',
          trackNumber: 1,
          trackCount: 2,
          playing: true,
          position: Duration.zero,
          duration: const Duration(minutes: 3),
          shuffle: false,
          repeat: repeat,
          onClose: onClose ?? () {},
          onPlayPause: () {},
          onPrevious: () {},
          onNext: () {},
          onSeek: (_) {},
          onShuffleChanged: (_) {},
          onRepeatChanged: onRepeat ?? (_) {},
        ),
      );

  testWidgets('Now Playing closes on a slow pull past the threshold, not on a short one',
      (tester) async {
    phone(tester);
    var closed = 0;
    await tester.pumpWidget(nowPlaying(onClose: () => closed++));

    // Slow and short: springs back.
    await tester.timedDrag(find.text('NOW PLAYING'), const Offset(0, 80), const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(closed, 0);

    // Slow but long, starting on the grabber area: closes.
    await tester.timedDrag(find.text('NOW PLAYING'), const Offset(0, 200), const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(closed, 1);
  });

  testWidgets('F11: tapping the repeat switch steps off → all → one → off; labels pick directly',
      (tester) async {
    phone(tester);
    var repeat = SoftRepeat.off;
    await tester.pumpWidget(StatefulBuilder(
      builder: (context, setState) => nowPlaying(
        repeat: repeat,
        onRepeat: (r) => setState(() => repeat = r),
      ),
    ));
    final knobWell = find.byType(SoftRepeatSelector);

    final seen = <SoftRepeat>[];
    for (var i = 0; i < 3; i++) {
      await tester.tapAt(tester.getTopLeft(knobWell) + const Offset(87, 22));
      await tester.pump();
      seen.add(repeat);
    }
    expect(seen, [SoftRepeat.all, SoftRepeat.one, SoftRepeat.off]);

    await tester.tap(find.bySemanticsLabel('Repeat one'));
    await tester.pump();
    expect(repeat, SoftRepeat.one);
  });

  testWidgets('the Library title and its count clear the header keys on a small phone',
      (tester) async {
    tester.view.physicalSize = const Size(750, 1334); // iPhone SE, 375×667 pt
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_wrap(
      Brightness.light,
      LibraryScreen(
        tracks: [for (var i = 0; i < 1000; i++) SoftTrack(id: '$i', title: 'Track $i')],
        currentIndex: null,
        playing: false,
        progress: 0,
        onTrackTap: (_) {},
        onDelete: (_) async => false,
        onImport: () {},
        onAbout: () {},
        onOpenPlayer: () {},
        onPlayPause: () {},
      ),
    ));

    final title = tester.getRect(find.text('LIBRARY · 1000'));
    for (final key in ['About', 'Import MP3s']) {
      final rect = tester.getRect(find.bySemanticsLabel(key));
      expect(title.overlaps(rect), isFalse, reason: '$key overlaps the title');
    }
  });

  testWidgets('an unexpected delete error is logged and the row closes', (tester) async {
    phone(tester);
    await tester.pumpWidget(_wrap(
      Brightness.light,
      LibraryScreen(
        tracks: const [SoftTrack(id: 'a', title: 'Old A')],
        currentIndex: null,
        playing: false,
        progress: 0,
        onTrackTap: (_) {},
        onDelete: (_) async => throw StateError('not in the library'),
        onImport: () {},
        onAbout: () {},
        onOpenPlayer: () {},
        onPlayPause: () {},
      ),
    ));
    await tester.drag(find.text('Old A'), const Offset(-80, 0));
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Delete'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isStateError);
    expect(find.bySemanticsLabel('Delete'), findsNothing);
  });

  testWidgets('VoiceOver can open the About links', (tester) async {
    final semantics = tester.ensureSemantics();
    phone(tester);
    final opened = <String>[];
    await tester.pumpWidget(_wrap(
      Brightness.light,
      AboutScreen(
        version: '1.0.0 (1)',
        onBack: () => opened.add('back'),
        onPrivacyPolicy: () => opened.add('privacy'),
        onLicenses: () => opened.add('licenses'),
      ),
    ));
    for (final label in ['Privacy Policy, Opens in browser', 'Open Source Licenses', 'Back to Library']) {
      final node = tester.getSemantics(find.bySemanticsLabel(label));
      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue, reason: label);
      node.owner!.performAction(node.id, SemanticsAction.tap);
    }
    expect(opened, ['privacy', 'licenses', 'back']);
    semantics.dispose();
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
