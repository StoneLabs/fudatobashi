import 'package:flutter/widgets.dart';

import '../../data/reader_onsets.dart';
import '../../domain/ikkiuchi_call.dart';
import '../../l10n/strings.dart';

/// The reader in a match (一騎打ち): the [call] read now and how far into
/// it, run on by the board's time ([advance]). Its listeners are told when
/// a call starts or stops, and each time another of its sounds is heard.
class IkkiuchiReader extends ChangeNotifier {
  IkkiuchiCall? get call => _call;
  IkkiuchiCall? _call;

  /// The call's sounds heard so far.
  int get heard => _heard;
  int _heard = 0;

  /// Each call read takes the next number, so what shows it starts afresh.
  int get serial => _serial;
  int _serial = 0;

  /// Ms into the call.
  double _ms = 0;

  /// Card [id]'s call in the player's script, timed by the reader's first
  /// recording of it, if any.
  static IkkiuchiCall callFor(BuildContext context, int id) => IkkiuchiCall(
        id,
        kimarijiSoundsFor(context, id),
        recorded: readerOnsets.of(id).firstOrNull?.onsets ?? const [],
      );

  /// Starts reading [call] from its beginning.
  void read(IkkiuchiCall call) {
    _call = call;
    _serial++;
    _ms = 0;
    _heard = call.heardAt(0);
    notifyListeners();
  }

  /// Nothing is read.
  void stop() {
    if (_call == null) return;
    _call = null;
    _heard = 0;
    notifyListeners();
  }

  void advance(double ms) {
    final call = _call;
    if (call == null) return;
    _ms += ms;
    final heard = call.heardAt(_ms);
    if (heard == _heard) return;
    _heard = heard;
    notifyListeners();
  }
}
