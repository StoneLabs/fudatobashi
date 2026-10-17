part of '../config.dart';

/// Sound pooling (`lib/ui/sound/sounds.dart`): concurrent, identically
/// loaded players kept per asset, so a sound that can retrigger faster than
/// one play of it lasts (a card flick during a swiping streak) overlaps
/// instead of cutting itself off.
abstract final class SoundTuning {
  static const int cardFlickPoolSize = 3;

  /// The XP counter ticks faster than one tick lasts.
  static const int xpTickPoolSize = 4;

  /// Fireworks, breakdown pops and the rating's heartbeat can land on top
  /// of each other.
  static const int burstPoolSize = 2;

  /// The rating's ratchet clicks faster than one click lasts.
  static const int ratingTickPoolSize = 4;

  /// 暗記練's takes and wrong taps can follow each other faster than one
  /// lasts.
  static const int ankirenTapPoolSize = 2;
}

/// Background music (`Music` in `lib/ui/sound/sounds.dart`): a single
/// looping track, playing only on menu screens (Home and its tabs, Settings,
/// onboarding, the tour) and faded out for a play/swipe screen and a run's
/// celebration.
abstract final class MusicTuning {
  static const String asset = 'sounds/bgm_fun_022824.m4a';

  /// How long a fade takes either way.
  static const Duration fadeIn = Duration(milliseconds: 900);
  static const Duration fadeOut = Duration(milliseconds: 600);

  /// Volume steps a fade is split into; smooth without waking up too often.
  static const int fadeSteps = 20;

  /// The volume slider is perceptual, the player's gain a linear amplitude:
  /// the gain is the slider's position to this power, so halfway sounds
  /// about half as loud (−12 dB) instead of hardly quieter than full (−6 dB).
  static const double volumeExponent = 2;
}

/// What a sound belongs to. Each category has its own Settings switch
/// (`AppSettings.plays`), and silent or vibrate mode mutes them all.
enum SoundCategory {
  /// Background music (see [Music]), switched by [AppSettings.music] and
  /// its volume slider ([AppSettings.musicVolume]).
  music,

  /// A card being swiped away: every card that leaves the deck during play,
  /// and the new-card page's flick.
  swipe,

  /// Every other sound: new cards and islands, XP, level-ups, the rating,
  /// rank-ups, graduation and Results.
  effects,
}

/// The app's sound effects (Kenney, CC0; provenance in
/// `assets/sounds/License.txt`): each one's assets under `assets/` and its
/// playback volume, 0–1. A sound with several assets plays a random one of
/// them each time. Celebration pages and Results play their cues on a
/// schedule; [cardFlick] also plays once for every card that leaves the
/// deck during play.
enum Sfx {
  cardAppears(['sounds/card_appears.wav'], 0.8),
  cardFlick(
    [
      'sounds/card_flick_0.wav',
      'sounds/card_flick_1.wav',
      'sounds/card_flick_2.wav',
      'sounds/card_flick_3.wav',
      'sounds/card_flick_4.wav',
    ],
    0.85,
    poolSize: SoundTuning.cardFlickPoolSize,
    category: SoundCategory.swipe,
  ),
  lookAlike(['sounds/look_alike.wav'], 0.7),
  island(['sounds/island.wav'], 0.8),
  stamp(['sounds/stamp.wav'], 0.9),
  rankUp(['sounds/rank_up.wav'], 0.8),
  goalUp(['sounds/goal_up.wav'], 0.8),
  best(['sounds/best.wav'], 0.8),
  results(['sounds/results.wav'], 0.5),
  xpTick(['sounds/xp_tick.wav'], 0.45, poolSize: SoundTuning.xpTickPoolSize),
  xpPop(['sounds/xp_pop.wav'], 0.6, poolSize: SoundTuning.burstPoolSize),
  xpDone(['sounds/xp_done.wav'], 0.8),
  levelUp(['sounds/level_up.wav'], 0.8),
  ratingTick(['sounds/rating_tick.wav'], 0.4, poolSize: SoundTuning.ratingTickPoolSize),
  ratingUp(['sounds/rating_up.wav'], 0.8),
  ratingStrain(['sounds/rating_strain.wav'], 0.9, poolSize: SoundTuning.burstPoolSize),
  ratingBreak(['sounds/rating_break.wav'], 0.9),
  graduation(['sounds/graduation.wav'], 0.85),

  /// 暗記練: the card asked for taken, another one tapped, the field turning
  /// face down, and the first card asked.
  ankirenTake(
    ['sounds/ankiren_take_0.wav', 'sounds/ankiren_take_1.wav', 'sounds/ankiren_take_2.wav'],
    0.8,
    poolSize: SoundTuning.ankirenTapPoolSize,
  ),
  ankirenWrong(['sounds/ankiren_wrong.wav'], 0.75, poolSize: SoundTuning.ankirenTapPoolSize),
  ankirenFlip(['sounds/ankiren_flip.wav'], 0.7),
  ankirenRecall(['sounds/ankiren_recall.wav'], 0.6),
  firework(
    ['sounds/firework_0.wav', 'sounds/firework_1.wav', 'sounds/firework_2.wav'],
    0.6,
    poolSize: SoundTuning.burstPoolSize,
  );

  const Sfx(this.assets, this.volume, {this.poolSize = 1, this.category = SoundCategory.effects});
  final List<String> assets;
  final double volume;

  /// Whose Settings switch it plays under.
  final SoundCategory category;

  /// Players preloaded per asset (see [SoundTuning]); 1 unless a sound needs
  /// to overlap itself.
  final int poolSize;
}

/// The pre-generated kimariji readouts (`scripts/kimariji_voice.py`), one
/// clip per poem, played on demand by the speaker button next to a card's
/// kimariji — never preloaded like [Sfx], since only one plays at a time and
/// it's never on the play loop's critical path.
abstract final class VoiceTuning {
  static String kimarijiAsset(int poemId) => 'voice/kimariji/${poemId.toString().padLeft(3, '0')}.m4a';
  static const double volume = 1;
}
