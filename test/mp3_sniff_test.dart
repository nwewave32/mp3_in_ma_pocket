import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:pocket_mp3/library/mp3_sniff.dart';

import 'test_helpers.dart';

void main() {
  test('an ID3 tag is enough', () {
    expect(looksLikeMp3(ascii.encode('ID3')), isTrue);
  });

  test('two MPEG audio frames in a row', () {
    expect(looksLikeMp3(mpegFrames(2)), isTrue);
  });

  test('MPEG-2 Layer III frames (half-size) chain too', () {
    // 80 kbps at 22.05 kHz: 72 × 80000 / 22050 = 261 bytes.
    final frame = [0xFF, 0xF3, 0x90, 0x00, ...List.filled(257, 0)];
    expect(looksLikeMp3([...frame, ...frame]), isTrue);
  });

  test('junk or a WAV header before the first frame is allowed', () {
    expect(looksLikeMp3([...ascii.encode('RIFF....WAVEfmt '), ...List.filled(40, 7), ...mpegFrames(2)]),
        isTrue);
  });

  test('a lone frame header, as a stray 0xFF in a PDF, is not enough', () {
    final pdf = [...ascii.encode('%PDF-1.4\n'), 0xFF, 0xFB, 0x90, 0x00, ...List.filled(1000, 0x20)];
    expect(looksLikeMp3(pdf), isFalse);
  });

  test('AAC (ADTS) is not MP3', () {
    final adts = [0xFF, 0xF1, 0x50, 0x80, ...List.filled(400, 0)];
    expect(looksLikeMp3([...adts, ...adts, ...adts]), isFalse);
  });

  test('empty or text is not MP3', () {
    expect(looksLikeMp3(const []), isFalse);
    expect(looksLikeMp3(ascii.encode('just some notes')), isFalse);
  });
}
