import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../config/config.dart';
import '../../state/scope.dart';

/// The celebration sounds, every asset preloaded into its own low-latency
/// player by [load] at startup, so playing one never touches the disk.
/// Nothing here runs during play: celebration pages and Results are the
/// only callers.
class Sounds {
  final _players = <Sfx, List<AudioPlayer>>{};
  final _random = Random();

  /// Asks the Android host whether the ringer is on silent or vibrate
  /// (`MainActivity.kt`).
  static const _ringer = MethodChannel('fudatobashi/ringer');

  /// Played through the game stream without taking audio focus, so music
  /// the player is listening to keeps going. On iOS the ambient category
  /// mixes in and is muted by the silent switch.
  static final _context = AudioContext(
    android: const AudioContextAndroid(
      contentType: AndroidContentType.sonification,
      usageType: AndroidUsageType.game,
      audioFocus: AndroidAudioFocus.none,
    ),
    iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient),
  );

  /// Preloads every sound. Until then (and in tests, which never load)
  /// [play] stays silent; a sound that fails to load stays silent too.
  Future<void> load() async {
    try {
      await AudioPlayer.global.setAudioContext(_context);
    } catch (e) {
      debugPrint('Sounds: no audio context ($e)');
    }
    for (final sfx in Sfx.values) {
      for (final asset in sfx.assets) {
        final player = await _preload(asset, sfx.volume);
        if (player != null) (_players[sfx] ??= []).add(player);
      }
    }
  }

  static Future<AudioPlayer?> _preload(String asset, double volume) async {
    final player = AudioPlayer();
    try {
      await player.setAudioContext(_context);
      await player.setPlayerMode(PlayerMode.lowLatency);
      // Stopping keeps the sound loaded (the default releases it).
      await player.setReleaseMode(ReleaseMode.stop);
      await player.setVolume(volume);
      await player.setSource(AssetSource(asset));
      return player;
    } catch (e) {
      debugPrint('Sounds: $asset not loaded ($e)');
      await player.dispose();
      return null;
    }
  }

  /// Plays [sfx] (a random one of its variants) from the start unless the
  /// phone is on silent or vibrate.
  Future<void> play(Sfx sfx) async {
    final variants = _players[sfx];
    if (variants == null || await _silenced()) return;
    final player = variants[_random.nextInt(variants.length)];
    await player.stop();
    await player.resume();
  }

  static Future<bool> _silenced() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return false;
    try {
      return await _ringer.invokeMethod<bool>('isSilenced') ?? false;
    } on PlatformException {
      return false;
    }
  }
}

/// The app's sounds; tests swap in a recorder.
Sounds sounds = Sounds();

/// Plays [sfx] if the player has sounds on.
void playSound(BuildContext context, Sfx sfx) {
  if (ProgressScope.read(context).settings.sounds) sounds.play(sfx);
}

/// Plays each of [cues] at its time after [child] appears (a celebration
/// page's sounds, in step with its entrance). Leaving early drops the rest,
/// including as soon as another screen (the next run) takes over.
class SoundCues extends StatefulWidget {
  const SoundCues({super.key, required this.cues, required this.child});

  final List<(Sfx, Duration)> cues;
  final Widget child;

  @override
  State<SoundCues> createState() => _SoundCuesState();
}

class _SoundCuesState extends State<SoundCues> {
  final _timers = <Timer>[];

  @override
  void initState() {
    super.initState();
    for (final (sfx, at) in widget.cues) {
      _timers.add(Timer(at, () {
        if (mounted && (ModalRoute.isCurrentOf(context) ?? true)) playSound(context, sfx);
      }));
    }
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
