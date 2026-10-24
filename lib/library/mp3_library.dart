import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

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

  /// MP3 files currently in the library folder (unsorted).
  Future<List<File>> list() async {
    final dir = await _directory();
    if (!await dir.exists()) return const [];
    return [
      await for (final e in dir.list(followLinks: false))
        if (e is File && isMp3(e.path)) e,
    ];
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
      if (!isMp3(name)) {
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
