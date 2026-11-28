import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:pocket_mp3/library/mp3_library.dart';

import 'test_helpers.dart';

void main() {
  late Directory root;
  late Directory library;
  late Directory picked;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('mp3_library_test');
    library = Directory(p.join(root.path, 'Documents'));
    picked = await Directory(p.join(root.path, 'picked')).create();
  });

  tearDown(() => root.delete(recursive: true));

  Future<String> pickedFile(String name, [String body = 'ID3']) async {
    final f = File(p.join(picked.path, name));
    await f.writeAsString(body);
    return f.path;
  }

  Mp3Library lib(List<String> picks) =>
      Mp3Library(directory: () async => library, picker: () async => picks);

  test('F1: copies several picked MP3s into the library folder', () async {
    final picks = [
      await pickedFile('01 Night Drive.mp3', 'ID3a'),
      await pickedFile('Lecture 03.MP3', 'ID3b'),
    ];

    final result = await lib(picks).importFromPicker();

    expect(result!.imported, 2);
    expect(result.failed, 0);
    expect(File(p.join(library.path, '01 Night Drive.mp3')).readAsStringSync(), 'ID3a');
    expect(File(p.join(library.path, 'Lecture 03.MP3')).readAsStringSync(), 'ID3b');
    // Copied, not moved.
    expect(File(picks.first).existsSync(), isTrue);
  });

  test('F1: skips files that are not MP3s', () async {
    final picks = [await pickedFile('song.mp3'), await pickedFile('notes.txt')];

    final result = await lib(picks).importFromPicker();

    expect(result!.imported, 1);
    expect(result.failed, 1);
    expect(File(p.join(library.path, 'notes.txt')).existsSync(), isFalse);
  });

  test('F1: a file renamed to .mp3 is not imported unless it is audio', () async {
    final frame = File(p.join(picked.path, 'no tag.mp3'))..writeAsBytesSync(mpegFrames(2));
    final picks = [
      await pickedFile('report.mp3', '%PDF-1.4'),
      await pickedFile('empty.mp3', ''),
      frame.path,
    ];

    final result = await lib(picks).importFromPicker();

    expect(result!.imported, 1);
    expect(result.failed, 2);
    expect(library.listSync().map((e) => p.basename(e.path)), ['no tag.mp3']);
  });

    test('cancelling the picker imports nothing', () async {
    expect(await lib(const []).importFromPicker(), isNull);
    expect(library.existsSync(), isFalse);
  });

  test('a missing source file counts as failed and leaves nothing behind', () async {
    final result = await lib([p.join(picked.path, 'gone.mp3')]).importFromPicker();

    expect(result!.imported, 0);
    expect(result.failed, 1);
    expect(library.listSync(), isEmpty);
  });

  test('F3: a name that is taken gets a number instead of overwriting', () async {
    await library.create();
    File(p.join(library.path, 'Lecture.mp3')).writeAsStringSync('old');
    File(p.join(library.path, 'Lecture 2.mp3')).writeAsStringSync('old 2');

    final result = await lib([await pickedFile('Lecture.mp3', 'ID3new')]).importFromPicker();

    expect(result!.imported, 1);
    expect(File(p.join(library.path, 'Lecture.mp3')).readAsStringSync(), 'old');
    expect(File(p.join(library.path, 'Lecture 2.mp3')).readAsStringSync(), 'old 2');
    expect(File(p.join(library.path, 'Lecture 3.mp3')).readAsStringSync(), 'ID3new');
  });

  test('F3: duplicates within one import are numbered too, keeping the extension', () async {
    final other = await Directory(p.join(root.path, 'other')).create();
    final second = File(p.join(other.path, 'Song.MP3'))..writeAsStringSync('ID3b');

    final result = await lib([await pickedFile('Song.MP3', 'ID3a'), second.path]).importFromPicker();

    expect(result!.imported, 2);
    expect(File(p.join(library.path, 'Song.MP3')).readAsStringSync(), 'ID3a');
    expect(File(p.join(library.path, 'Song 2.MP3')).readAsStringSync(), 'ID3b');
  });

  test('F5: delete removes the file; a file already gone is fine', () async {
    await library.create();
    final f = File(p.join(library.path, 'a.mp3'))..writeAsStringSync('');

    await lib(const []).delete(f.path);
    expect(f.existsSync(), isFalse);
    await lib(const []).delete(f.path);
  });

  test('delete refuses paths outside the library', () async {
    final outside = await pickedFile('outside.mp3');

    expect(() => lib(const []).delete(outside), throwsArgumentError);
    expect(File(outside).existsSync(), isTrue);
  });

  test('list returns only MP3 files at the top level', () async {
    await library.create();
    File(p.join(library.path, 'a.mp3')).writeAsStringSync('');
    File(p.join(library.path, 'b.Mp3')).writeAsStringSync('');
    File(p.join(library.path, '.DS_Store')).writeAsStringSync('');
    Directory(p.join(library.path, 'folder.mp3')).createSync();
    // Folders made in the Files app aren't read (folder import is out of scope).
    Directory(p.join(library.path, 'Album')).createSync();
    File(p.join(library.path, 'Album', 'c.mp3')).writeAsStringSync('');
    // Left behind if the app was killed mid-copy.
    File(p.join(library.path, 'd.mp3.part')).writeAsStringSync('');

    final names = (await lib(const []).list()).map((f) => p.basename(f.path)).toSet();

    expect(names, {'a.mp3', 'b.Mp3'});
  });
}
