import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:pocket_mp3/library/mp3_length.dart';

import 'test_helpers.dart';

/// F4: track lengths for the list, read from the MP3 header.
void main() {
  test('constant bitrate: measured by size', () {
    final audio = mpegFrames(100); // 41,700 bytes at 128 kbps
    expect(mp3Length(audio, audioBytes: audio.length), const Duration(microseconds: 2606250));
  });

  test('constant bitrate: the size counts past the bytes looked at', () {
    final audio = mpegFrames(10);
    // A 4 MB file at 128 kbps is 250 s, though only its start is read.
    expect(mp3Length(audio, audioBytes: 4000000), const Duration(seconds: 250));
  });

  test('junk before the first frame is not counted', () {
    final audio = [...List.filled(417, 0x20), ...mpegFrames(10)];
    expect(mp3Length(audio, audioBytes: audio.length), const Duration(microseconds: 260625));
  });

  test('VBR: the Xing frame count gives the length', () {
    final audio = xingMp3(1000); // 1000 × 1152 / 44100 s
    expect(mp3Length(audio, audioBytes: audio.length), const Duration(microseconds: 26122448));
  });

  test('VBR: a VBRI frame count gives the length', () {
    final first = [0xFF, 0xFB, 0x90, 0x00, ...List.filled(413, 0)];
    first.setAll(36, [...'VBRI'.codeUnits, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0x03, 0xE8]);
    final audio = [...first, ...mpegFrames(1)];
    expect(mp3Length(audio, audioBytes: audio.length), const Duration(microseconds: 26122448));
  });

  test('a lone frame header where the bytes looked at end is not taken for audio', () {
    // A stray 320 kbps header near the end of the first 16 KB of junk, in a
    // longer file: no second frame to confirm it.
    final audio = [...List.filled(mp3LengthScan - 100, 0), 0xFF, 0xFB, 0xE0, 0x00, ...List.filled(96, 0)];
    expect(mp3Length(audio, audioBytes: 4000000), isNull);
  });

  test('a file of a single frame has a length', () {
    final audio = mpegFrames(1);
    expect(mp3Length(audio, audioBytes: audio.length), const Duration(microseconds: 26062));
  });

  test('no MPEG frame: unknown', () {
    expect(mp3Length('ID3'.codeUnits, audioBytes: 3), isNull);
    expect(mp3Length(List.filled(1000, 0), audioBytes: 1000), isNull);
  });

  group('from a file', () {
    late Directory dir;
    setUp(() => dir = Directory.systemTemp.createTempSync('length_test'));
    tearDown(() => dir.deleteSync(recursive: true));

    File write(String name, List<int> bytes) => File(p.join(dir.path, name))..writeAsBytesSync(bytes);

    test('ID3v2 at the start and ID3v1 at the end are not audio', () async {
      final id3v2 = [...'ID3'.codeUnits, 4, 0, 0, 0, 0, 0, 100, ...List.filled(100, 0)];
      final id3v1 = [...'TAG'.codeUnits, ...List.filled(125, 0x20)];
      final file = write('tagged.mp3', [...id3v2, ...mpegFrames(10), ...id3v1]);
      expect(await readMp3Length(file), const Duration(microseconds: 260625));
    });

    test('an ID3 tag with no audio, or a missing file, is unknown', () async {
      expect(await readMp3Length(write('tag only.mp3', 'ID3'.codeUnits)), isNull);
      expect(await readMp3Length(File(p.join(dir.path, 'gone.mp3'))), isNull);
    });
  });
}
