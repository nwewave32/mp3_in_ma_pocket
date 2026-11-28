/// How many leading bytes [looksLikeMp3] needs to see.
const mp3SniffLength = 16 * 1024;

/// Whether [head], the start of a file, looks like MP3 audio: an ID3 tag, or
/// two MPEG audio frames in a row somewhere in it. Two chained frames rule out
/// a stray 0xFF in a PDF or image, and still allow junk or a WAV header
/// before the first frame. AAC (ADTS) has layer bits 00, so it doesn't pass.
bool looksLikeMp3(List<int> head) {
  if (head.length >= 3 && head[0] == 0x49 && head[1] == 0x44 && head[2] == 0x33) return true; // "ID3"
  for (var i = 0; i + 4 <= head.length; i++) {
    final length = mpegFrameLength(head, i);
    if (length == null) continue;
    final next = i + length;
    if (next + 4 <= head.length && mpegFrameLength(head, next) != null) return true;
  }
  return false;
}

// Bitrates in kbps by bitrate index; index 0 (free format) and 15 are invalid.
const _v1l1 = [0, 32, 64, 96, 128, 160, 192, 224, 256, 288, 320, 352, 384, 416, 448];
const _v1l2 = [0, 32, 48, 56, 64, 80, 96, 112, 128, 160, 192, 224, 256, 320, 384];
const _v1l3 = [0, 32, 40, 48, 56, 64, 80, 96, 112, 128, 160, 192, 224, 256, 320];
const _v2l1 = [0, 32, 48, 56, 64, 80, 96, 112, 128, 144, 160, 176, 192, 224, 256];
const _v2l23 = [0, 8, 16, 24, 32, 40, 48, 56, 64, 80, 96, 112, 128, 144, 160];

/// Bitrate in kbps of the MPEG audio frame whose header starts at [i], or
/// null if there is no valid header there.
int? mpegBitrate(List<int> b, int i) {
  if (b[i] != 0xFF || b[i + 1] & 0xE0 != 0xE0) return null;
  final version = (b[i + 1] >> 3) & 0x3; // 0: 2.5, 1: reserved, 2: 2, 3: 1
  final layer = (b[i + 1] >> 1) & 0x3; // 1: III, 2: II, 3: I, 0: reserved
  final bitrateIndex = b[i + 2] >> 4;
  final rateIndex = (b[i + 2] >> 2) & 0x3;
  if (version == 1 || layer == 0 || bitrateIndex == 0 || bitrateIndex == 15 || rateIndex == 3) {
    return null;
  }
  final v1 = version == 3;
  return switch (layer) {
    3 => v1 ? _v1l1 : _v2l1,
    2 => v1 ? _v1l2 : _v2l23,
    _ => v1 ? _v1l3 : _v2l23,
  }[bitrateIndex];
}

/// Sample rate in Hz of the valid frame header at [i].
int mpegSampleRate(List<int> b, int i) {
  final version = (b[i + 1] >> 3) & 0x3;
  return [44100, 48000, 32000][(b[i + 2] >> 2) & 0x3] ~/ (version == 3 ? 1 : (version == 2 ? 2 : 4));
}

/// Length in bytes of the MPEG audio frame whose header starts at [i], or
/// null if there is no valid header there.
int? mpegFrameLength(List<int> b, int i) {
  final kbps = mpegBitrate(b, i);
  if (kbps == null) return null;
  final v1 = (b[i + 1] >> 3) & 0x3 == 3;
  final layer = (b[i + 1] >> 1) & 0x3;
  final rate = mpegSampleRate(b, i);
  final padding = (b[i + 2] >> 1) & 0x1;
  if (layer == 3) return (12 * kbps * 1000 ~/ rate + padding) * 4;
  final perFrame = layer == 1 && !v1 ? 72 : 144;
  return perFrame * kbps * 1000 ~/ rate + padding;
}
