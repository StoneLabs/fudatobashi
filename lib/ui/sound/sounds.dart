import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../config/config.dart';
import '../../state/scope.dart';

/// The app's sound effects, every asset preloaded into low-latency players
/// by [load] at startup (round-robin pooled per asset; see [Sfx.poolSize]),
/// so playing one never touches the disk or the platform channel. Played
/// during play (the swipe footstep) as well as on celebration pages and
/// Results, each only while its [SoundCategory] is switched on (see
/// [playSound]).
class Sounds with WidgetsBindingObserver {
  final _players = <Sfx, List<_Pool>>{};
  final _random = Random();

  /// Whether the ringer is on silent or vibrate, cached at [load] and
  /// refreshed on resume so a swipe never blocks on the platform channel.
  bool _silenced = false;

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
      final pools = <_Pool>[];
      for (final asset in sfx.assets) {
        final players = <AudioPlayer>[];
        for (var i = 0; i < sfx.poolSize; i++) {
          final player = await _preload(asset, sfx.volume);
          if (player != null) players.add(player);
        }
        if (players.isNotEmpty) pools.add(_Pool(players));
      }
      if (pools.isNotEmpty) _players[sfx] = pools;
    }
    await _refreshSilenced();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_refreshSilenced());
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

  /// Plays [sfx] (a random one of its variants, from a fresh player in its
  /// pool) from the start unless the phone is on silent or vibrate.
  /// Fire-and-forget: never await this on a path where timing matters.
  Future<void> play(Sfx sfx) async {
    final pools = _players[sfx];
    if (pools == null || _silenced) return;
    final player = pools[_random.nextInt(pools.length)].take();
    await player.stop();
    await player.resume();
  }

  Future<void> _refreshSilenced() async {
    _silenced = await _querySilenced();
  }

  static Future<bool> _querySilenced() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return false;
    try {
      return await _ringer.invokeMethod<bool>('isSilenced') ?? false;
    } on PlatformException {
      return false;
    }
  }
}

/// A few interchangeable players preloaded with the same asset, handed out
/// round-robin so a retrigger while the last one is still sounding overlaps
/// it instead of cutting it off.
class _Pool {
  _Pool(this._players);
  final List<AudioPlayer> _players;
  int _next = 0;

  AudioPlayer take() {
    final player = _players[_next];
    _next = (_next + 1) % _players.length;
    return player;
  }
}

/// The app's sounds; tests swap in a recorder.
Sounds sounds = Sounds();

/// Plays [sfx] if the player has its [SoundCategory] switched on.
void playSound(BuildContext context, Sfx sfx) {
  if (ProgressScope.read(context).settings.plays(sfx.category)) sounds.play(sfx);
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
