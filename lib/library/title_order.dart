/// F4: library order, as the Files app sorts names — ignoring case, numbers
/// by value ("Lecture 2" before "Lecture 10").
int compareTitles(String a, String b) {
  final ka = _sortKey(a);
  final kb = _sortKey(b);
  final byChunks = _compareChunks(ka, kb);
  if (byChunks != 0) return byChunks;
  // Equal by the rules above ("01" vs "1", "a" vs "A"): keep a fixed order.
  final byKey = ka.compareTo(kb);
  return byKey != 0 ? byKey : a.compareTo(b);
}

/// Lower case, with Hangul composed: names copied from a Mac often keep
/// decomposed jamo, which would otherwise sort apart from the same name typed
/// on the phone.
String _sortKey(String s) => _composeHangul(s.toLowerCase());

final _chunk = RegExp(r'\d+|\D+');

int _compareChunks(String a, String b) {
  final ca = _chunk.allMatches(a).map((m) => m[0]!).toList();
  final cb = _chunk.allMatches(b).map((m) => m[0]!).toList();
  for (var i = 0; i < ca.length && i < cb.length; i++) {
    final x = ca[i];
    final y = cb[i];
    final c = _isDigits(x) && _isDigits(y) ? _compareNumbers(x, y) : x.compareTo(y);
    if (c != 0) return c;
  }
  return ca.length.compareTo(cb.length);
}

/// Chunks are all digits or none, so the first character decides.
bool _isDigits(String s) {
  final c = s.codeUnitAt(0);
  return c >= 0x30 && c <= 0x39;
}

/// Compares digit strings by value without parsing, so any length works.
int _compareNumbers(String a, String b) {
  final x = a.replaceFirst(RegExp('^0+'), '');
  final y = b.replaceFirst(RegExp('^0+'), '');
  return x.length != y.length ? x.length.compareTo(y.length) : x.compareTo(y);
}

/// Composes conjoining jamo (L V [T]) into Hangul syllables (Unicode §3.12).
String _composeHangul(String s) {
  const lBase = 0x1100, vBase = 0x1161, tBase = 0x11A7, sBase = 0xAC00;
  const lCount = 19, vCount = 21, tCount = 28;
  final units = s.codeUnits;
  final out = StringBuffer();
  for (var i = 0; i < units.length; i++) {
    final l = units[i] - lBase;
    final v = i + 1 < units.length ? units[i + 1] - vBase : -1;
    if (l < 0 || l >= lCount || v < 0 || v >= vCount) {
      out.writeCharCode(units[i]);
      continue;
    }
    var t = i + 2 < units.length ? units[i + 2] - tBase : 0;
    if (t <= 0 || t >= tCount) t = 0;
    out.writeCharCode(sBase + (l * vCount + v) * tCount + t);
    i += t == 0 ? 1 : 2;
  }
  return out.toString();
}
