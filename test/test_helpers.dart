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
