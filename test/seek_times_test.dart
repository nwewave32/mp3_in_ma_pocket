import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mp3_in_ma_pocket/design/theme.dart';
import 'package:mp3_in_ma_pocket/design/widgets/player_controls.dart';

/// Seek bar times: elapsed and remaining tick together (device check 9-1),
/// and VoiceOver reads the same values.
void main() {
  const length = Duration(minutes: 3, seconds: 20, milliseconds: 500);
  String shown(Duration position) {
    final t = seekTimes(position, length);
    return '${formatDuration(t.elapsed)} -${formatDuration(t.remaining)}';
  }

  test('both change on the same whole second', () {
    expect(shown(const Duration(seconds: 10, milliseconds: 100)), '0:10 -3:10');
    expect(shown(const Duration(seconds: 10, milliseconds: 600)), '0:10 -3:10');
    expect(shown(const Duration(seconds: 11)), '0:11 -3:09');
  });

  test(
    'elapsed and remaining always add up to the length shown in the list',
    () {
      for (var ms = 0; ms <= length.inMilliseconds; ms += 250) {
        final t = seekTimes(Duration(milliseconds: ms), length);
        expect(t.elapsed + t.remaining, shownLength(length));
      }
      expect(formatDuration(shownLength(length)), '3:20');
    },
  );

  test('start, end and out-of-range positions', () {
    expect(shown(Duration.zero), '0:00 -3:20');
    expect(shown(length), '3:20 -0:00');
    expect(shown(const Duration(minutes: 5)), '3:20 -0:00');
    expect(shown(const Duration(seconds: -1)), '0:00 -3:20');
  });

  test('unknown length shows zeros', () {
    expect(seekTimes(const Duration(seconds: 5), Duration.zero), (
      elapsed: Duration.zero,
      remaining: Duration.zero,
    ));
  });

  group('VoiceOver', () {
    Future<SemanticsData> seekBar(
      WidgetTester tester,
      Duration position,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildSoftTheme(Brightness.light),
          home: Scaffold(
            body: SoftSeekBar(
              position: position,
              duration: length,
              onSeek: (_) {},
            ),
          ),
        ),
      );
      return tester
          .getSemantics(find.bySemanticsLabel('Seek'))
          .getSemanticsData();
    }

    testWidgets('reads the same time as the label', (tester) async {
      final handle = tester.ensureSemantics();
      final data = await seekBar(
        tester,
        const Duration(seconds: 30, milliseconds: 700),
      );
      expect(data.value, '0:30');
      expect(data.increasedValue, '0:45');
      expect(data.decreasedValue, '0:15');
      handle.dispose();
    });

    testWidgets(
      '15s back near the start and 15s on near the end stay in range',
      (tester) async {
        final handle = tester.ensureSemantics();
        var data = await seekBar(tester, const Duration(seconds: 5));
        expect(data.decreasedValue, '0:00');

        data = await seekBar(
          tester,
          const Duration(minutes: 3, seconds: 20, milliseconds: 400),
        );
        expect(data.value, '3:20');
        expect(data.increasedValue, '3:20');
        handle.dispose();
      },
    );
  });
}
