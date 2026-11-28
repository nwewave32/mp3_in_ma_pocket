import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'mp3_length.dart';
import 'mp3_sniff.dart';

/// Opens a picker and returns the local paths of the files the user chose.
typedef Mp3Picker = Future<List<String>> Function();

/// Result of one import: how many files were copied and how many failed.
class ImportResult {
  const ImportResult({required this.imported, required this.failed});

  final int imported;
  final int failed;
}

/// The MP3s stored in the app's Documents folder, which the Files app shows
/// as "On My iPhone › MP3 in ma pocket" (F2).
class Mp3Library {
  Mp3Library({Future<Directory> Function()? directory, Mp3Picker? picker})
      : _directory = directory ?? getApplicationDocumentsDirectory,
        _picker = picker ?? _pickWithSystemPicker,
        _usesSystemPicker = picker == null;

  final Future<Directory> Function() _directory;
  final Mp3Picker _picker;
  final bool _usesSystemPicker;

  static bool isMp3(String path) => p.extension(path).toLowerCase() == '.mp3';

  /// Lengths read so far, with the file's size and modified time then.
  final _lengths = <String, ({int size, DateTime modified, Duration? length})>{};

  /// The length [lengthOf] last read for [path], without touching the file.
  Duration? cachedLength(String path) => _lengths[path]?.length;

  /// The track's length from its MP3 header, or null if it can't be read.
  /// Read again only when the file's size or modified time changes.
  Future<Duration?> lengthOf(String path) async {
    final stat = await File(path).stat();
    if (stat.type == FileSystemEntityType.notFound) {
      _lengths.remove(path);
      return null;
    }
    final known = _lengths[path];
    if (known != null && known.size == stat.size && known.modified == stat.modified) {
      return known.length;
    }
    final length = await readMp3Length(File(path));
    _lengths[path] = (size: stat.size, modified: stat.modified, length: length);
    return length;
  }

  /// MP3 files currently in the library folder (unsorted).
  Future<List<File>> list() async {
    final dir = await _directory();
    if (!await dir.exists()) return const [];
    return [
      await for (final e in dir.list(followLinks: false))
        if (e is File && isMp3(e.path)) e,
    ];
  }

  /// F5: removes a library file. A file that is already gone (deleted in the
  /// Files app) counts as removed.
  Future<void> delete(String path) async {
    final dir = await _directory();
    if (!p.isWithin(dir.path, path)) {
      throw ArgumentError.value(path, 'path', 'is not in the library');
    }
    _lengths.remove(path);
    try {
      await File(path).delete();
    } on PathNotFoundException {
      // Already gone.
    }
  }

  /// F1: lets the user pick several MP3s and copies them into the library.
  /// Returns null when the user cancels the picker.
  Future<ImportResult?> importFromPicker() async {
    final paths = await _picker();
    if (paths.isEmpty) return null;
    try {
      return await copyIn(paths);
    } finally {
      if (_usesSystemPicker) await _clearPickerCopies();
    }
  }

  /// The system picker hands us copies in tmp; don't keep them around.
  /// Note: on iOS this empties the app's whole tmp folder.
  static Future<void> _clearPickerCopies() async {
    try {
      await FilePicker.clearTemporaryFiles();
    } catch (_) {
      // Best effort: iOS purges tmp on its own, and the import already succeeded.
    }
  }

  /// Copies [sourcePaths] into the library folder, skipping non-MP3 files.
  Future<ImportResult> copyIn(Iterable<String> sourcePaths) async {
    final dir = await _directory();
    await dir.create(recursive: true);
    var imported = 0;
    var failed = 0;
    for (final source in sourcePaths) {
      // basename() keeps a crafted name like "../x.mp3" inside the library.
      final name = p.basename(source);
      if (!isMp3(name) || !await _looksLikeMp3(File(source))) {
        failed++;
        continue;
      }
      final target = await _freePath(dir, name);
      // Copy under a name list() ignores, so a failed copy never shows up as a
      // broken track.
      final part = File('$target.part');
      try {
        await File(source).copy(part.path);
        await part.rename(target);
        imported++;
      } on FileSystemException {
        failed++;
        try {
          await part.delete();
        } on FileSystemException {
          // Nothing was written.
        }
      }
    }
    return ImportResult(imported: imported, failed: failed);
  }

  /// Checks the first bytes, so a PDF renamed to ".mp3" isn't imported.
  /// A file that can't be read counts as not an MP3.
  static Future<bool> _looksLikeMp3(File file) async {
    try {
      final raf = await file.open();
      try {
        return looksLikeMp3(await raf.read(mp3SniffLength));
      } finally {
        await raf.close();
      }
    } on FileSystemException {
      return false;
    }
  }

  /// F3: "name.mp3", then "name 2.mp3", "name 3.mp3", … — never overwrites.
  static Future<String> _freePath(Directory dir, String name) async {
    final stem = p.basenameWithoutExtension(name);
    final ext = p.extension(name);
    var candidate = p.join(dir.path, name);
    for (var n = 2; await File(candidate).exists(); n++) {
      candidate = p.join(dir.path, '$stem $n$ext');
    }
    return candidate;
  }

  static Future<List<String>> _pickWithSystemPicker() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['mp3'],
    );
    return [
      for (final f in files)
        if (f.path != null) f.path!,
    ];
  }
}
