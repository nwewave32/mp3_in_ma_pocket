import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mp3_in_ma_pocket/design/design_preview.dart';
import 'package:mp3_in_ma_pocket/design/screens/about_screen.dart';
import 'package:mp3_in_ma_pocket/design/screens/now_playing_screen.dart';
import 'package:mp3_in_ma_pocket/design/theme.dart';
import 'package:mp3_in_ma_pocket/design/widgets/player_controls.dart';

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(1170, 2532); // iPhone 14/15, 390×844 pt
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
}

Widget _wrap(Brightness b, Widget child) => MaterialApp(
      theme: buildSoftTheme(b),
      home: child,
    );

void main() {
  testWidgets('first run → import → library', (tester) async {
    _phone(tester);
    await tester.pumpWidget(const DesignPreviewApp());
    expect(find.text('MP3 IN MA POCKET'), findsOneWidget);
    await tester.tap(find.text('Import MP3s'));
    await tester.pump();
    expect(find.text('LIBRARY · 13'), findsOneWidget);
  });

  for (final b in Brightness.values) {
    testWidgets('Now Playing renders without overflow ($b)', (tester) async {
      _phone(tester);
      await tester.pumpWidget(_wrap(
        b,
        NowPlayingScreen(
          title: 'Econ 101 - Lecture 03',
          trackNumber: 6,
          trackCount: 12,
          playing: true,
          position: const Duration(minutes: 12, seconds: 4),
          duration: const Duration(minutes: 48, seconds: 10),
          shuffle: false,
          repeat: SoftRepeat.all,
          onClose: () {},
          onPlayPause: () {},
          onPrevious: () {},
          onNext: () {},
          onSeek: (_) {},
          onShuffleChanged: (_) {},
          onRepeatChanged: (_) {},
        ),
      ));
      expect(tester.takeException(), isNull);
      expect(find.text('NOW PLAYING'), findsOneWidget);
    });

    testWidgets('About renders without overflow ($b)', (tester) async {
      _phone(tester);
      await tester.pumpWidget(_wrap(
        b,
        AboutScreen(
          version: '1.0.0 (1)',
          onBack: () {},
          onPrivacyPolicy: () {},
          onLicenses: () {},
        ),
      ));
      expect(tester.takeException(), isNull);
      expect(find.text('Open Source Licenses'), findsOneWidget);
    });
  }
}
