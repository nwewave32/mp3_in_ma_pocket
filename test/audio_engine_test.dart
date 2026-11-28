import 'package:flutter_test/flutter_test.dart';

import 'package:pocket_mp3/playback/audio_engine.dart';

int? _step(int? current, List<int> order, int offset, {bool wrap = false}) =>
    neighborInPlayOrder(current: current, order: order, offset: offset, wrap: wrap);

/// Next/previous for every repeat mode, including repeat one (H1).
void main() {
  test('moves through the queue in order', () {
    expect(_step(1, [0, 1, 2], 1), 2);
    expect(_step(1, [0, 1, 2], -1), 0);
  });

  test('follows the shuffled play order, not queue positions', () {
    // Shuffled: queue item 2 plays first, then 0, then 1.
    expect(_step(0, [2, 0, 1], 1), 1);
    expect(_step(0, [2, 0, 1], -1), 2);
  });

  test('stops at either end without wrap (repeat off)', () {
    expect(_step(2, [0, 1, 2], 1), isNull);
    expect(_step(0, [0, 1, 2], -1), isNull);
  });

  test('wraps around with repeat all or one', () {
    expect(_step(2, [0, 1, 2], 1, wrap: true), 0);
    expect(_step(0, [0, 1, 2], -1, wrap: true), 2);
  });

  test('a single track wraps to itself, and an empty queue has no neighbor', () {
    expect(_step(0, [0], 1, wrap: true), 0);
    expect(_step(null, const [], 1, wrap: true), isNull);
  });
}
