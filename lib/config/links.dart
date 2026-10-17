/// Addresses the app opens outside itself: web pages in the browser, the
/// developer's email in the mail app.
abstract final class Links {
  /// The source code and the issue tracker.
  static const repository = 'https://github.com/StoneLabs/fudatobashi';
  static const issues = '$repository/issues';

  /// Where "Contact the developer" sends email.
  static const developerEmail = 'fudatobashi-dev@sobadev.com';
  static const developerMailto = 'mailto:$developerEmail';

  /// The All Japan Karuta Association's competition rules (競技規程細則),
  /// the PDF the full rules in Help are copied from.
  static const karutaRules = 'https://www.karuta.or.jp/static/kitei/20200526-kyougi_saisoku.pdf';
}
