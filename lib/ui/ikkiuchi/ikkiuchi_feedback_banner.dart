import 'package:flutter/widgets.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import 'ikkiuchi_call_strip.dart';

/// How a read ended, [text] on the call's strip ([IkkiuchiStrip]) in the
/// call's [look], shrunk to fit the room it is given, [at] ms into its
/// showing: it slides in from the left fading in
/// ([IkkiuchiMatchTuning.feedbackIn]), stays ([IkkiuchiMatchTuning.feedbackHold]),
/// and slides on out to the right fading out
/// ([IkkiuchiMatchTuning.feedbackOut]).
class IkkiuchiFeedbackBanner extends StatelessWidget {
  const IkkiuchiFeedbackBanner({super.key, required this.text, required this.at, required this.look});

  final String text;
  final double at;
  final IkkiuchiCallLook look;

  static double _ms(Duration d) => d.inMicroseconds / Duration.microsecondsPerMillisecond;

  /// How far it has come in, from -1 (left, unseen) through 0 (in place) to
  /// 1 (right, unseen).
  double get _place {
    final inMs = _ms(IkkiuchiMatchTuning.feedbackIn), outFrom = inMs + _ms(IkkiuchiMatchTuning.feedbackHold);
    if (at < inMs) return IkkiuchiCallStyle.feedbackInCurve.transform(at / inMs) - 1;
    if (at < outFrom) return 0;
    final t = ((at - outFrom) / _ms(IkkiuchiMatchTuning.feedbackOut)).clamp(0.0, 1.0);
    return IkkiuchiCallStyle.feedbackOutCurve.transform(t);
  }

  @override
  Widget build(BuildContext context) {
    final place = _place;
    return Opacity(
      opacity: 1 - place.abs(),
      child: Transform.translate(
        offset: Offset(place * IkkiuchiCallStyle.feedbackSlide, 0),
        child: IkkiuchiStrip(
          look: look,
          child: Text(
            text,
            maxLines: 1,
            softWrap: false,
            style: TextStyle(fontFamily: Fonts.display, fontSize: IkkiuchiCallStyle.feedback, height: 1, color: look.ink),
          ),
        ),
      ),
    );
  }
}
