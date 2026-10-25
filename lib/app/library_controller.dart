import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../design/screens/library_screen.dart';
import '../library/mp3_library.dart';
import '../library/title_order.dart';

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
  bool _loaded = false;

  /// F4: file names without ".mp3", in [compareTitles] order.
  List<SoftTrack> get tracks => _tracks;

  /// False until the folder has been read once, so the first-run screen
  /// doesn't flash while a full library is loading.
  bool get loaded => _loaded;

  /// Re-reads the folder. An unreadable folder keeps the current list.
  Future<void> refresh() async {
    // Reads can overlap (return to app during an import or delete); only the
    // newest one applies, so a read that started before a change can't undo it.
    final generation = ++_generation;
    final List<File> files;
    try {
      files = await _library.list();
    } catch (e, stack) {
      // A FileSystemException is expected (folder unreadable for a moment);
      // anything else is a bug worth logging, but neither may crash the app.
      if (e is! FileSystemException) {
        FlutterError.reportError(
            FlutterErrorDetails(exception: e, stack: stack, library: 'library'));
      }
      // Nothing to keep on the first read: show the first-run screen.
      if (!_disposed && !_loaded) {
        _loaded = true;
        notifyListeners();
      }
      return;
    }
    if (_disposed || generation != _generation) return;
    _loaded = true;
    _tracks = [
      for (final f in files) SoftTrack(id: f.path, title: p.basenameWithoutExtension(f.path)),
    ]..sort((a, b) => compareTitles(a.title, b.title));
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
