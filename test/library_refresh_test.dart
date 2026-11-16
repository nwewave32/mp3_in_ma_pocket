import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:mp3_in_ma_pocket/design/design_preview.dart';
import 'package:mp3_in_ma_pocket/design/widgets/player_controls.dart';
import 'package:mp3_in_ma_pocket/library/mp3_library.dart';
import 'package:mp3_in_ma_pocket/playback/playback_controller.dart';

import 'fake_audio_engine.dart';
import 'test_helpers.dart';

/// A library whose list() calls the test answers one by one.
class _ControlledLibrary extends Mp3Library {
  final calls = <Completer<List<File>>>[];

  @override
  Future<List<File>> list() {
    final c = Completer<List<File>>();
    calls.add(c);
    return c.future;
  }

  @override
  Future<void> delete(String path) async {}
}

List<File> _files(List<String> names) => [for (final n in names) File('/docs/$n')];

/// F2: the library re-reads the app folder whenever the app comes back.
void main() {
  late Directory docs;
  late Mp3Library library;
  late FakeAudioEngine engine;

  Future<void> start(WidgetTester tester, List<String> names) async {
    phone(tester);
    final root = await tempRoot(tester, 'refresh_test');
    docs = Directory(p.join(root.path, 'Documents'))..createSync();
    for (final n in names) {
      File(p.join(docs.path, n)).writeAsStringSync('ID3');
    }
    library = Mp3Library(directory: () async => docs, picker: () async => const []);
    engine = FakeAudioEngine();
    await tester.pumpWidget(DesignPreviewApp(library: library, engine: engine));
    await settleIo(tester);
  }

  Future<void> returnToApp(WidgetTester tester) async {
    leaveAndReturn(tester);
    await settleIo(tester);
  }

  SoftMiniPlayer miniPlayer(WidgetTester tester) => tester.widget(find.byType(SoftMiniPlayer));

  testWidgets('files added or removed through the Files app show up on return', (tester) async {
    await start(tester, ['Lecture 01.mp3']);
    expect(find.text('LIBRARY · 1'), findsOneWidget);

    File(p.join(docs.path, 'Lecture 02.mp3')).writeAsStringSync('ID3');
    File(p.join(docs.path, 'cover.jpg')).writeAsStringSync('');
    await returnToApp(tester);

    expect(find.text('LIBRARY · 2'), findsOneWidget);
    expect(find.text('Lecture 02'), findsOneWidget);

    File(p.join(docs.path, 'Lecture 01.mp3')).deleteSync();
    await returnToApp(tester);

    expect(find.text('LIBRARY · 1'), findsOneWidget);
    expect(find.text('Lecture 01'), findsNothing);
  });

  testWidgets('removing the playing track in Files stops playback', (tester) async {
    await start(tester, ['Lecture 01.mp3', 'Lecture 02.mp3']);
    await tester.tap(find.text('Lecture 01'));
    await tester.pump();
    expect(miniPlayer(tester).title, 'Lecture 01');

    File(p.join(docs.path, 'Lecture 01.mp3')).deleteSync();
    await returnToApp(tester);

    expect(find.text('LIBRARY · 1'), findsOneWidget);
    expect(find.byType(SoftMiniPlayer), findsNothing);
  });

  testWidgets('Now Playing closes when its track is removed in Files', (tester) async {
    await start(tester, ['Lecture 01.mp3', 'Lecture 02.mp3']);
    await tester.tap(find.text('Lecture 01'));
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('Open Now Playing: Lecture 01'));
    await tester.pumpAndSettle();
    expect(find.text('NOW PLAYING'), findsOneWidget);

    File(p.join(docs.path, 'Lecture 01.mp3')).deleteSync();
    await returnToApp(tester);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('NOW PLAYING'), findsNothing);
    expect(find.text('LIBRARY · 1'), findsOneWidget);
  });

  testWidgets('a file that cannot be played shows a message', (tester) async {
    phone(tester);
    final root = await tempRoot(tester, 'broken_test');
    docs = Directory(p.join(root.path, 'Documents'))..createSync();
    final broken = File(p.join(docs.path, 'Broken.mp3'))..writeAsStringSync('not audio');
    library = Mp3Library(directory: () async => docs, picker: () async => const []);
    await tester.pumpWidget(DesignPreviewApp(
      library: library,
      engine: FakeAudioEngine(unplayable: {broken.path}),
    ));
    await settleIo(tester);

    await tester.tap(find.text('Broken'));
    await tester.pump();

    expect(find.text('Couldn\'t play "Broken".'), findsOneWidget);
    expect(find.byType(SoftMiniPlayer), findsNothing);
  });

  testWidgets('changes to other tracks keep the current track and position', (tester) async {
    await start(tester, ['Lecture 01.mp3', 'Lecture 02.mp3']);
    await tester.tap(find.text('Lecture 01'));
    await tester.pump();
    engine
      ..position = const Duration(seconds: 5)
      ..emit();
    await tester.pump();
    final before = miniPlayer(tester).progress;
    expect(before, greaterThan(0));

    File(p.join(docs.path, 'Lecture 02.mp3')).deleteSync();
    File(p.join(docs.path, 'A first.mp3')).writeAsStringSync('ID3');
    await returnToApp(tester);

    expect(find.text('A first'), findsOneWidget);
    expect(find.text('Lecture 02'), findsNothing);
    expect(miniPlayer(tester).title, 'Lecture 01');
    expect(miniPlayer(tester).playing, isTrue);
    expect(miniPlayer(tester).progress, before);
  });

  testWidgets('F12: shuffle and repeat are back after the app is relaunched', (tester) async {
    Future<void> openNowPlaying() async {
      await tester.tap(find.text('Lecture 01'));
      await tester.pump();
      await tester.tap(find.bySemanticsLabel('Open Now Playing: Lecture 01'));
      await tester.pumpAndSettle();
    }

    await start(tester, ['Lecture 01.mp3', 'Lecture 02.mp3']);
    await openNowPlaying();
    expect(find.text('SHUF OFF'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Shuffle'));
    await tester.tap(find.bySemanticsLabel('Repeat one'));
    await tester.pumpAndSettle();

    // Relaunch: a new app with a new player, same preferences.
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(DesignPreviewApp(library: library, engine: FakeAudioEngine()));
    await settleIo(tester);
    await openNowPlaying();

    expect(find.text('SHUF ON'), findsOneWidget);
    expect(find.text('RPT ONE'), findsOneWidget);
  });

  testWidgets('F9: the lock screen gets the app\'s player', (tester) async {
    PlaybackController? connected;
    phone(tester);
    final root = await tempRoot(tester, 'lock_test');
    docs = Directory(p.join(root.path, 'Documents'))..createSync();
    File(p.join(docs.path, 'Lecture 01.mp3')).writeAsStringSync('ID3');
    library = Mp3Library(directory: () async => docs, picker: () async => const []);
    await tester.pumpWidget(DesignPreviewApp(
      library: library,
      engine: FakeAudioEngine(),
      connectLockScreen: (player) async => connected = player,
    ));
    await settleIo(tester);

    await tester.tap(find.text('Lecture 01'));
    await tester.pump();
    expect(connected!.current!.title, 'Lecture 01');
  });

  testWidgets('F9: if the lock screen cannot be reached, it is logged and playback still works',
      (tester) async {
    phone(tester);
    final root = await tempRoot(tester, 'lock_fail_test');
    docs = Directory(p.join(root.path, 'Documents'))..createSync();
    File(p.join(docs.path, 'Lecture 01.mp3')).writeAsStringSync('ID3');
    library = Mp3Library(directory: () async => docs, picker: () async => const []);
    await tester.pumpWidget(DesignPreviewApp(
      library: library,
      engine: FakeAudioEngine(),
      connectLockScreen: (_) async => throw PlatformException(code: 'unavailable'),
    ));
    await settleIo(tester);

    expect(tester.takeException(), isA<PlatformException>());

    await tester.tap(find.text('Lecture 01'));
    await tester.pump();
    expect(miniPlayer(tester).title, 'Lecture 01');
    expect(miniPlayer(tester).playing, isTrue);
  });

  testWidgets('an older reload finishing late does not overwrite a newer one', (tester) async {
    phone(tester);
    final library = _ControlledLibrary();
    await tester.pumpWidget(DesignPreviewApp(library: library, engine: FakeAudioEngine()));
    leaveAndReturn(tester);
    expect(library.calls, hasLength(2));

    library.calls[1].complete(_files(['New.mp3']));
    await tester.pump();
    library.calls[0].complete(_files(['Old A.mp3', 'Old B.mp3']));
    await tester.pump();

    expect(find.text('LIBRARY · 1'), findsOneWidget);
    expect(find.text('New'), findsOneWidget);
    expect(find.text('Old A'), findsNothing);
  });

  testWidgets('an unreadable folder keeps the current list', (tester) async {
    phone(tester);
    final library = _ControlledLibrary();
    await tester.pumpWidget(DesignPreviewApp(library: library, engine: FakeAudioEngine()));
    library.calls[0].complete(_files(['Lecture 01.mp3']));
    await tester.pump();

    leaveAndReturn(tester);
    library.calls[1].completeError(const FileSystemException('Operation not permitted'));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('LIBRARY · 1'), findsOneWidget);
    expect(find.text('Lecture 01'), findsOneWidget);
  });

  testWidgets('F4: nothing shows until the first read, so the first-run screen never flashes',
      (tester) async {
    phone(tester);
    final library = _ControlledLibrary();
    await tester.pumpWidget(DesignPreviewApp(library: library, engine: FakeAudioEngine()));

    expect(find.text('Import MP3s'), findsNothing);
    expect(find.textContaining('LIBRARY'), findsNothing);

    library.calls[0].complete(_files(['Lecture 01.mp3']));
    await tester.pump();
    expect(find.text('LIBRARY · 1'), findsOneWidget);
  });

  testWidgets('F4: an unreadable folder on first launch shows the first-run screen',
      (tester) async {
    phone(tester);
    final library = _ControlledLibrary();
    await tester.pumpWidget(DesignPreviewApp(library: library, engine: FakeAudioEngine()));

    library.calls[0].completeError(const FileSystemException('Operation not permitted'));
    await tester.pump();

    expect(find.text('Import MP3s'), findsOneWidget);
  });

  testWidgets('F4: an unexpected error on first launch is logged and shows the first-run screen',
      (tester) async {
    phone(tester);
    final library = _ControlledLibrary();
    await tester.pumpWidget(DesignPreviewApp(library: library, engine: FakeAudioEngine()));

    library.calls[0].completeError(StateError('no documents folder'));
    await tester.pump();

    expect(tester.takeException(), isStateError);
    expect(find.text('Import MP3s'), findsOneWidget);
  });

  testWidgets('F4: deleting the last track brings back the first-run screen', (tester) async {
    await start(tester, ['Lecture 01.mp3']);

    await swipeAllTheWay(tester, 'Lecture 01');
    await tester.tap(find.text('Delete').last);
    await settleIo(tester);
    await tester.pumpAndSettle();

    expect(find.text('Import MP3s'), findsOneWidget);
    expect(find.textContaining('On My iPhone'), findsOneWidget);
  });

  testWidgets('F4: the list follows Files app order', (tester) async {
    await start(tester, ['Lecture 10.mp3', 'lecture 2.mp3', 'Intro.mp3']);

    final ys = [
      for (final t in ['Intro', 'lecture 2', 'Lecture 10']) tester.getTopLeft(find.text(t)).dy,
    ];
    expect(ys, orderedEquals([...ys]..sort()));
  });

  testWidgets('a read that started before a delete cannot bring the track back', (tester) async {
    phone(tester);
    final library = _ControlledLibrary();
    await tester.pumpWidget(DesignPreviewApp(library: library, engine: FakeAudioEngine()));
    library.calls[0].complete(_files(['Lecture 01.mp3', 'Lecture 02.mp3']));
    await tester.pump();

    // Back from another app: a read starts and sees both files…
    leaveAndReturn(tester);
    // …while the user deletes Lecture 01.
    await swipeAllTheWay(tester, 'Lecture 01');
    await tester.tap(find.text('Delete').last);
    await tester.pump();
    expect(library.calls, hasLength(3));

    library.calls[2].complete(_files(['Lecture 02.mp3']));
    await tester.pump();
    library.calls[1].complete(_files(['Lecture 01.mp3', 'Lecture 02.mp3']));
    await tester.pumpAndSettle();

    expect(find.text('LIBRARY · 1'), findsOneWidget);
    expect(find.text('Lecture 01'), findsNothing);
  });
}
