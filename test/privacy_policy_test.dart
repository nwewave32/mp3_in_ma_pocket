import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pocket_mp3/app/legal.dart';
import 'package:pocket_mp3/design/design_preview.dart';
import 'package:pocket_mp3/library/mp3_library.dart';

import 'fake_audio_engine.dart';
import 'test_helpers.dart';

/// About › Privacy Policy opens the page on the legal site.
void main() {
  test('the page for an app lives under its path on the legal site', () {
    expect(privacyPolicyUrl('ipkong').toString(), 'https://ireuisu-legal.vercel.app/ipkong/privacy/');
    expect(privacyPolicyUrl(null), isNull);
  });

  test("pocket.mp3's page", () {
    expect(privacyPolicyUrl().toString(), 'https://ireuisu-legal.vercel.app/pocket-mp3/privacy/');
  });

  Future<void> openAbout(WidgetTester tester, {Uri? url, required Future<bool> Function(Uri) openUrl}) async {
    phone(tester);
    final empty = (await tempRoot(tester, 'privacy_test'));
    await withRealIo(
      tester,
      () => tester.pumpWidget(DesignPreviewApp(
        library: Mp3Library(directory: () async => empty, picker: () async => const []),
        engine: FakeAudioEngine(),
        privacyPolicy: url,
        openUrl: openUrl,
      )),
    );
    await tester.tap(find.bySemanticsLabel('About'));
    await tester.pumpAndSettle();
  }

  final url = Uri.parse('https://ireuisu-legal.vercel.app/example/privacy/');

  testWidgets('tapping it opens the page in the browser', (tester) async {
    final opened = <Uri>[];
    await openAbout(tester, url: url, openUrl: (u) async {
      opened.add(u);
      return true;
    });

    await tester.tap(find.text('Privacy Policy'));
    await tester.pump();

    expect(opened, [url]);
    expect(find.byType(SnackBar), findsNothing);
  });

  final failures = <String, Future<bool> Function(Uri)>{
    'refuses': (_) async => false,
    'throws': (_) async => throw PlatformException(code: 'ACTIVITY_NOT_FOUND'),
  };
  for (final MapEntry(key: how, value: fail) in failures.entries) {
    testWidgets('if the browser $how, it says so', (tester) async {
      await openAbout(tester, url: url, openUrl: fail);
      await tester.tap(find.text('Privacy Policy'));
      await tester.pump();
      expect(find.text("Couldn't open the privacy policy."), findsOneWidget);
    });
  }
}
