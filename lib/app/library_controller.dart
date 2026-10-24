import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../design/screens/library_screen.dart';
import '../library/mp3_library.dart';

/// The library as the app sees it: tracks read from the app folder, kept in
/// sync with the folder on import (F1), on return to the app (F2) and on
/// delete (F5).
class LibraryController extends ChangeNotifier {
  LibraryController(this._library);

  final Mp3Library _library;
  List<SoftTrack> _tracks = const [];
  int _generation = 0;
  bool _importing = false;
  bool _disposed = false;

  /// F4: file names without ".mp3", A→Z ignoring case.
  List<SoftTrack> get tracks => _tracks;

  /// Re-reads the folder. An unreadable folder keeps the current list.
  Future<void> refresh() async {
    // Reads can overlap (return to app during an import or delete); only the
    // newest one applies, so a read that started before a change can't undo it.
    final generation = ++_generation;
    final List<File> files;
    try {
      files = await _library.list();
    } on FileSystemException {
      return;
    }
    if (_disposed || generation != _generation) return;
    _tracks = [
      for (final f in files) SoftTrack(id: f.path, title: p.basenameWithoutExtension(f.path)),
    ]..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    notifyListeners();
  }

  /// Opens the picker and copies the chosen MP3s in. Returns null if the user
  /// cancels or an import is already running.
  ///
  /// Throws a `PlatformException` if the picker can't open and a
  /// [FileSystemException] if the library folder can't be written.
  Future<ImportResult?> import() async {
    if (_importing) return null;
    _importing = true;
    try {
      final result = await _library.importFromPicker();
      if (result != null) await refresh();
      return result;
    } finally {
      _importing = false;
    }
  }

  /// Deletes [track]'s file. Throws [FileSystemException] if it can't.
  Future<void> delete(SoftTrack track) async {
    await _library.delete(track.id);
    await refresh();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
