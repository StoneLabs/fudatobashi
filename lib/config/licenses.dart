/// Bundled third-party font licenses: shown on the credits screen
/// (`lib/ui/settings/credits_screen.dart`) and registered with Flutter's
/// `LicenseRegistry` in `main.dart` so they also appear in `showLicensePage`.
/// Author/foundry names are copied from each license file's own copyright
/// header.
library;

class FontCredit {
  const FontCredit({required this.name, required this.author, required this.license, required this.licenseAsset});

  final String name;
  final String author;
  final String license;
  final String licenseAsset;
}

const fontCredits = [
  FontCredit(
    name: 'Dela Gothic One',
    author: 'The Dela Gothic Project Authors',
    license: 'SIL Open Font License 1.1',
    licenseAsset: 'assets/fonts/OFL-delagothicone.txt',
  ),
  FontCredit(
    name: 'Reggae One',
    author: 'The Reggae Project Authors',
    license: 'SIL Open Font License 1.1',
    licenseAsset: 'assets/fonts/OFL-reggaeone.txt',
  ),
  FontCredit(
    name: 'Yuji Syuku',
    author: 'The Yuji Project Authors',
    license: 'SIL Open Font License 1.1',
    licenseAsset: 'assets/fonts/OFL-YujiSyuku.txt',
  ),
  FontCredit(
    name: 'Zen Kaku Gothic New',
    author: 'The Zen Kaku Gothic Project Authors',
    license: 'SIL Open Font License 1.1',
    licenseAsset: 'assets/fonts/OFL-zenkakugothicnew.txt',
  ),
  FontCredit(
    name: 'TeX Gyre Schola',
    author: 'GUST e-foundry (GUST, the Polish TeX Users Group)',
    license: 'GUST Font License',
    licenseAsset: 'assets/fonts/GUST-FONT-LICENSE.txt',
  ),
];

const soundsLicenseAsset = 'assets/sounds/License.txt';
