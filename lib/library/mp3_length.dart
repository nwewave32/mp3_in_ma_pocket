import 'dart:io';
import 'dart:math' as math;

import 'mp3_sniff.dart';

/// How many bytes after the ID3 tag [mp3Length] looks through for the first
/// frame, like [mp3SniffLength].
const mp3LengthScan = 16 * 1024;

/// The length of an MP3 from its first audio frame, without decoding it.
///
/// [audio] starts where the audio starts (after any ID3v2 tag), and
/// [audioBytes] counts the audio up to the end of the file, without an ID3v1
/// tag. A VBR file has a Xing/Info or VBRI frame with its frame count; any
/// other file is taken as constant bitrate and measured by its size. Null
/// when no frame is found.
Duration? mp3Length(List<int> audio, {required int audioBytes}) {
  for (var i = 0; i + 4 <= audio.length; i++) {
    final length = mpegFrameLength(audio, i);
    if (length == null) continue;
    // Two frames in a row, as in [looksLikeMp3], so a stray 0xFF before the
    // audio isn't taken for a frame. A lone frame counts only at the end of
    // the file, not at the end of the bytes looked at.
    final next = i + length;
    final chained = next + 4 <= audio.length && mpegFrameLength(audio, next) != null;
    final endsFile = audio.length >= audioBytes && next >= audioBytes;
    if (!chained && !endsFile) continue;
    return _fromFrame(audio, i, audioBytes - i);
  }
  return null;
}

/// Reads [file]'s length with [mp3Length]. Null if it can't be read or has
/// no MPEG audio frame.
Future<Duration?> readMp3Length(File file) async {
  try {
    final raf = await file.open();
    try {
      final size = await raf.length();
      final start = _id3v2Size(await raf.read(10));
      var end = size;
      if (size - start >= 128) {
        await raf.setPosition(size - 128);
        final tail = await raf.read(3);
        if (tail.length == 3 && tail[0] == 0x54 && tail[1] == 0x41 && tail[2] == 0x47) end -= 128; // "TAG"
      }
      if (start >= end) return null;
      await raf.setPosition(start);
      final audio = await raf.read(math.min(mp3LengthScan, end - start));
      return mp3Length(audio, audioBytes: end - start);
    } finally {
      await raf.close();
    }
  } on FileSystemException {
    return null;
  }
}

/// Size of the ID3v2 tag that [head] (the first 10 bytes) starts, or 0.
int _id3v2Size(List<int> head) {
  if (head.length < 10 || head[0] != 0x49 || head[1] != 0x44 || head[2] != 0x33) return 0; // "ID3"
  final size = (head[6] & 0x7F) << 21 | (head[7] & 0x7F) << 14 | (head[8] & 0x7F) << 7 | (head[9] & 0x7F);
  final footer = head[5] & 0x10 != 0 ? 10 : 0;
  return 10 + size + footer;
}

Duration? _fromFrame(List<int> b, int i, int bytes) {
  final v1 = (b[i + 1] >> 3) & 0x3 == 3;
  final layer = (b[i + 1] >> 1) & 0x3; // 1: III, 2: II, 3: I
  final rate = mpegSampleRate(b, i);
  final samples = switch (layer) {
    3 => 384,
    2 => 1152,
    _ => v1 ? 1152 : 576,
  };

  final frames = _xingFrames(b, i, v1: v1, layer: layer) ?? _vbriFrames(b, i);
  if (frames != null && frames > 0) {
    return Duration(microseconds: frames * samples * 1000000 ~/ rate);
  }

  // Constant bitrate: the frame's bitrate over the rest of the file.
  final kbps = mpegBitrate(b, i)!;
  if (bytes <= 0) return null;
  return Duration(microseconds: bytes * 8 * 1000 ~/ kbps);
}

/// Frame count from a Xing/Info header in the frame at [i], if it has one.
int? _xingFrames(List<int> b, int i, {required bool v1, required int layer}) {
  if (layer != 1) return null; // Layer III only.
  final mono = (b[i + 3] >> 6) == 3;
  final sideInfo = v1 ? (mono ? 17 : 32) : (mono ? 9 : 17);
  final at = i + 4 + sideInfo;
  if (!_tag(b, at, 'Xing') && !_tag(b, at, 'Info')) return null;
  if (at + 12 > b.length || b[at + 7] & 0x1 == 0) return null; // No frame count.
  return _int32(b, at + 8);
}

/// Frame count from a VBRI header (Fraunhofer encoders), always 32 bytes in.
int? _vbriFrames(List<int> b, int i) {
  final at = i + 4 + 32;
  if (!_tag(b, at, 'VBRI') || at + 18 > b.length) return null;
  return _int32(b, at + 14);
}

bool _tag(List<int> b, int at, String tag) {
  if (at + tag.length > b.length) return false;
  for (var k = 0; k < tag.length; k++) {
    if (b[at + k] != tag.codeUnitAt(k)) return false;
  }
  return true;
}

int _int32(List<int> b, int at) => b[at] << 24 | b[at + 1] << 16 | b[at + 2] << 8 | b[at + 3];
