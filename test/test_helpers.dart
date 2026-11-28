import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(1170, 2532); // iPhone 14/15, 390×844 pt
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
}

/// Runs [action] in the real zone so the file I/O it starts can finish,
/// then rebuilds.
Future<void> withRealIo(WidgetTester tester, Future<void> Function() action) async {
  await tester.runAsync(() async {
    await action();
    await Future<void>.delayed(const Duration(milliseconds: 100));
  });
  await tester.pump();
}

/// A temp folder that is removed after the test.
Future<Directory> tempRoot(WidgetTester tester, String name) async {
  final root = (await tester.runAsync(() => Directory.systemTemp.createTemp(name)))!;
  addTearDown(() => root.deleteSync(recursive: true));
  return root;
}

/// Sends the app to the background and back, as switching to Files does.
void leaveAndReturn(WidgetTester tester) {
  for (final s in [
    AppLifecycleState.inactive,
    AppLifecycleState.hidden,
    AppLifecycleState.paused,
    AppLifecycleState.hidden,
    AppLifecycleState.inactive,
    AppLifecycleState.resumed,
  ]) {
    tester.binding.handleAppLifecycleStateChanged(s);
  }
}

/// Lets file I/O started from the test zone (e.g. by a widget's callback)
/// finish, rebuilding between steps. Unlike [withRealIo], timers the app
/// creates stay on the test clock; it moves forward 20ms in all, which
/// directory listing needs.
Future<void> settleIo(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
    await tester.pump(const Duration(milliseconds: 1));
  }
}

/// Swipes a library row all the way left over several frames, like a finger.
Future<void> swipeAllTheWay(WidgetTester tester, String title) async {
  await tester.timedDrag(find.text(title), const Offset(-500, 0), const Duration(milliseconds: 300));
  await tester.pumpAndSettle();
}

/// [count] silent MPEG-1 Layer III frames (128 kbps, 44.1 kHz, 417 bytes each).
List<int> mpegFrames(int count) => [
      for (var i = 0; i < count; i++) ...[0xFF, 0xFB, 0x90, 0x00, ...List.filled(413, 0)],
    ];

/// A VBR MP3 whose Xing header says it has [frames] frames (1152 samples
/// each at 44.1 kHz), followed by one audio frame.
List<int> xingMp3(int frames) {
  final first = [0xFF, 0xFB, 0x90, 0x00, ...List.filled(413, 0)];
  // MPEG-1 stereo: the Xing tag follows 32 bytes of side info.
  first.setAll(36, [
    ...'Xing'.codeUnits,
    0, 0, 0, 1, // flags: frame count present
    frames >> 24 & 0xFF, frames >> 16 & 0xFF, frames >> 8 & 0xFF, frames & 0xFF,
  ]);
  return [...first, ...mpegFrames(1)];
}
