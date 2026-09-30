import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../config/config.dart';
import '../../state/scope.dart';
import '../../state/settings.dart';

/// The app's sound effects, every asset preloaded into low-latency players
/// by [load] at startup (round-robin pooled per asset; see [Sfx.poolSize]),
/// so playing one never touches the disk. Played during play (the swipe
/// footstep) as well as on celebration pages and Results, each only while
/// its [SoundCategory] is switched on (see [playSound]). Background music is
/// a separate concern; see [Music].
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
    final player = _newPlayer();
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

/// A player that never reports its position. audioplayers otherwise asks
/// the platform for it on every frame for as long as the player plays, and
/// a low-latency one plays forever as far as it knows (SoundPool reports no
/// end), so every effect ever played would keep asking until the main
/// thread is flooded and new sounds queue behind it for seconds.
AudioPlayer _newPlayer() => AudioPlayer()..positionUpdater = null;

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

/// The app's background music: a single looping player, entirely separate
/// from the effect pools above so a swipe never waits on it. Playing only on
/// menu screens (see [enterMenu]/[leaveMenu]), it fades out for a play/swipe
/// screen and a run's celebration, and back in once a menu screen is on top
/// again. [applySettings] applies the Music switch and its volume slider,
/// live. Until [load] (and in tests, which never load) every call here stays
/// silent, like an unloaded [Sounds].
class Music with WidgetsBindingObserver {
  AudioPlayer? _player;
  Timer? _fadeTimer;

  bool _enabled = DefaultSettings.music;
  double _volume = DefaultSettings.musicVolume;

  /// False only while a play/swipe screen or a run's celebration is on top.
  bool _wantsMenu = true;
  bool _backgrounded = false;
  bool _silenced = false;

  /// The player's own gain (linear amplitude, touching no system or effect
  /// volume) for a volume slider position; see [MusicTuning.volumeExponent].
  static double gainFor(double volume) => pow(volume, MusicTuning.volumeExponent).toDouble();

  /// Preloads the track, looped, at zero volume, then brings it up if the
  /// app is already showing a menu screen. A track that fails to load stays
  /// silent for good.
  Future<void> load() async {
    final player = _newPlayer();
    try {
      await player.setAudioContext(Sounds._context);
      await player.setReleaseMode(ReleaseMode.loop);
      await player.setVolume(0);
      await player.setSource(AssetSource(MusicTuning.asset));
    } catch (e) {
      debugPrint('Music: not loaded ($e)');
      await player.dispose();
      return;
    }
    _player = player;
    _silenced = await Sounds._querySilenced();
    WidgetsBinding.instance.addObserver(this);
    _sync();
  }

  /// Applies the Music switch and its volume slider (Settings › Sound),
  /// ignoring every other setting: the switch fades music in or out, and the
  /// slider sets the volume of music already playing at once, so it follows
  /// the finger.
  void applySettings(AppSettings settings) {
    if (settings.music == _enabled && settings.musicVolume == _volume) return;
    final switched = settings.music != _enabled;
    _enabled = settings.music;
    _volume = settings.musicVolume;
    _sync(fade: switched);
  }

  /// A play/swipe screen, or a run's celebration, has taken over: music
  /// fades out and pauses once silent.
  void leaveMenu() {
    _wantsMenu = false;
    _sync();
  }

  /// Back on a menu screen (Home, Settings, onboarding, the tour, or the
  /// Results overview once its celebration is done): music fades back in.
  void enterMenu() {
    _wantsMenu = true;
    _sync();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      _backgrounded = true;
      _fadeTimer?.cancel();
      unawaited(_player?.pause());
      return;
    }
    _backgrounded = false;
    unawaited(() async {
      _silenced = await Sounds._querySilenced();
      _sync();
    }());
  }

  /// Brings the player to where [_enabled], [_wantsMenu], [_silenced] and
  /// [_backgrounded] say it should be: playing at the slider's gain, or
  /// paused at silence. It fades there, taking over from any fade under way,
  /// unless [fade] is false.
  void _sync({bool fade = true}) {
    final player = _player;
    if (player == null || _backgrounded) return;
    final target = _enabled && _wantsMenu && !_silenced ? gainFor(_volume) : 0.0;
    _fadeTimer?.cancel();
    if (!fade) {
      unawaited(player.setVolume(target));
      _settle(player, target);
      return;
    }
    final start = player.volume;
    if (start == target) {
      _settle(player, target);
      return;
    }
    if (target > 0) unawaited(player.resume());
    const steps = MusicTuning.fadeSteps;
    final stepDuration = (target > start ? MusicTuning.fadeIn : MusicTuning.fadeOut) ~/ steps;
    var step = 0;
    _fadeTimer = Timer.periodic(stepDuration, (timer) {
      step++;
      unawaited(player.setVolume(step < steps ? start + (target - start) * step / steps : target));
      if (step == steps) {
        timer.cancel();
        _settle(player, target);
      }
    });
  }

  /// Keeps [player] going at an audible [gain], or pauses it at silence.
  static void _settle(AudioPlayer player, double gain) => unawaited(gain > 0 ? player.resume() : player.pause());
}

/// The app's background music; tests never [Music.load] it, so it stays
/// silent.
Music music = Music();

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
