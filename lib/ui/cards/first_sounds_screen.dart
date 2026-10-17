import 'package:flutter/widgets.dart';

import '../../l10n/card_info_strings.dart';
import '../../l10n/strings.dart';
import '../manga/manga.dart';
import 'page_frame.dart';

/// How a card's first sounds shrink as other cards are read, opened from
/// the sound ladder on its About page. Only a slot until it is written.
class FirstSoundsScreen extends StatelessWidget {
  const FirstSoundsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return PageFrame(
      title: s.firstSoundsTitle,
      body: SingleChildScrollView(
        padding: PageFrame.padding,
        child: ComingSoonSlot(s.firstSoundsSoon),
      ),
    );
  }
}
