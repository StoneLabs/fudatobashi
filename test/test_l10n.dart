// Shared by every test that renders UI text: loads assets/l10n/*.json from
// disk, the same way the app loads them at startup (see `Localization.load`).
import 'dart:io';

import 'package:fudatobashi/l10n/localization.dart';

void loadTestL10n() => Localization.loadFromSource(
      indexJson: File('assets/l10n/languages.json').readAsStringSync(),
      jsonByCode: {
        'en': File('assets/l10n/en.json').readAsStringSync(),
        'ja': File('assets/l10n/ja.json').readAsStringSync(),
      },
    );
