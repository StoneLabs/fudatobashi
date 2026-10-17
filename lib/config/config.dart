/// The app's tuning constants and defaults, grouped by the system they drive.
/// This is the one place to look for (and change) a magic number.
library;

import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';

import '../domain/ankiren_field.dart';
import '../domain/ankiren_level.dart';
import '../domain/card_mask.dart';
import '../domain/learning_pace.dart';
import '../domain/xp.dart';
import '../state/play_config.dart';
import '../state/settings.dart';
import 'design.dart';

part 'tuning/play.dart';
part 'tuning/onboarding.dart';
part 'tuning/training.dart';
part 'tuning/side_trips.dart';
part 'tuning/settings.dart';
part 'tuning/stats.dart';
part 'tuning/ranked.dart';
part 'tuning/history.dart';
part 'tuning/exam.dart';
part 'tuning/xp.dart';
part 'tuning/debug.dart';
part 'tuning/data.dart';
part 'tuning/simulation.dart';
part 'tuning/sound.dart';
part 'tuning/ankiren.dart';
part 'tuning/about_card.dart';
