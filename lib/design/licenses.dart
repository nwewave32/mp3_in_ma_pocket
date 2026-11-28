import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Registers the bundled fonts' OFL licenses so they appear in
/// `showLicensePage()` (About › Open Source Licenses).
void registerFontLicenses() {
  LicenseRegistry.addLicense(() async* {
    const fonts = {
      'DotGothic16': 'assets/licenses/OFL-DotGothic16.txt',
      'Galmuri11': 'assets/licenses/OFL-Galmuri.txt',
      'JetBrains Mono': 'assets/licenses/OFL-JetBrainsMono.txt',
      'Space Grotesk': 'assets/licenses/OFL-SpaceGrotesk.txt',
      'Pretendard': 'assets/licenses/OFL-Pretendard.txt',
    };
    for (final entry in fonts.entries) {
      final text = await rootBundle.loadString(entry.value);
      yield LicenseEntryWithLineBreaks([entry.key], text);
    }
  });
}
