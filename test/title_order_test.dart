import 'package:flutter_test/flutter_test.dart';

import 'package:pocket_mp3/library/title_order.dart';

List<String> _sorted(List<String> titles) => [...titles]..sort(compareTitles);

/// F4: the library lists titles the way the Files app does.
void main() {
  test('ignores case', () {
    expect(_sorted(['banana', 'Apple', 'cherry']), ['Apple', 'banana', 'cherry']);
  });

  test('numbers sort by value', () {
    expect(
      _sorted(['Lecture 10', 'Lecture 2', 'Lecture 1', 'Lecture 02b']),
      ['Lecture 1', 'Lecture 2', 'Lecture 02b', 'Lecture 10'],
    );
    expect(_sorted(['Track 100000000000000000001', 'Track 99']),
        ['Track 99', 'Track 100000000000000000001']);
  });

  test('a shorter name comes first', () {
    expect(_sorted(['Lecture 1 notes', 'Lecture 1', 'Lecture']),
        ['Lecture', 'Lecture 1', 'Lecture 1 notes']);
  });

  test('names that differ only in case or leading zeros keep a fixed order', () {
    expect(_sorted(['song', 'Song']), _sorted(['Song', 'song']));
    expect(_sorted(['Track 1', 'Track 01']), _sorted(['Track 01', 'Track 1']));
  });

  test('Hangul from a Mac (decomposed) sorts with Hangul typed on the phone', () {
    // "가나" written as conjoining jamo, as macOS stores file names.
    const decomposedGana = '가나';
    expect(_sorted(['다', decomposedGana, '가']), ['가', decomposedGana, '다']);
    // With a final consonant: "각" decomposed sorts after "가" and before "나".
    const decomposedGak = '각';
    expect(_sorted(['나', decomposedGak, '가']), ['가', decomposedGak, '나']);
  });

  test('Latin before Hangul', () {
    expect(_sorted(['강의 1', 'Lecture 1']), ['Lecture 1', '강의 1']);
  });
}
