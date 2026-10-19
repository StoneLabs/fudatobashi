import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:watcher/watcher.dart';

import '../config.dart';
import '../model/shader_info.dart';
import 'project.dart';

/// One compiler error.
class ShaderError {
  const ShaderError(this.line, this.column, this.message);
  final int line;
  final int? column;
  final String message;
}

/// What the last compile of one shader did.
class ShaderResult {
  const ShaderResult(this.name, {required this.ok, required this.errors, required this.log, required this.time});
  final String name;
  final bool ok;
  final List<ShaderError> errors;

  /// The full compiler output.
  final String log;
  final DateTime time;

  /// One line for the status line.
  String get summary {
    if (ok) return 'Shader $name reloaded';
    final e = errors.firstOrNull;
    if (e != null) return 'Shader $name error (line ${e.line}): ${e.message}';
    final line = log.split('\n').where((l) => l.trim().isNotEmpty).firstOrNull;
    return 'Shader $name error: ${line ?? 'compile failed'}';
  }
}

/// The shaders of a project: the `<name>.frag` files in its shaders folder.
/// A shader compiles with impellerc when first asked for and again whenever
/// its file (or a `.glsl` include) changes. A failed compile keeps the last good program.
class ShaderLibrary extends ChangeNotifier {
  ShaderLibrary({required this.bundled, this.onReloaded});

  /// The program built into the app: used until a compile succeeds and when compiling is unavailable.
  final ui.FragmentProgram bundled;

  /// Called after a compile that a file change caused, successful or not.
  final void Function(ShaderResult result)? onReloaded;

  Directory? _dir;
  List<String> _names = [];
  final Map<String, ui.FragmentProgram> _programs = {};
  final Map<String, ShaderResult> _results = {};
  final Map<String, String> _compiledText = {};
  final Map<String, ShaderInfo> _infos = {};
  final Map<String, Timer> _timers = {};
  final Set<String> _ensuring = {};
  StreamSubscription<WatchEvent>? _watch;
  Future<void> _queue = Future.value();
  int _pending = 0, _counter = 0;

  /// Shader names, sorted. Without a library folder only the bundled standard shader.
  List<String> get names => _names.isEmpty ? const [Cfg.standardShader] : _names;

  /// Whether a library folder was found and impellerc is available.
  bool get canCompile => _dir != null && File(p.join(_impellerDir.path, 'impellerc')).existsSync();

  /// True while any compile runs or waits.
  bool get busy => _pending > 0;

  File? file(String name) => _dir == null ? null : File(p.join(_dir!.path, '$name${Cfg.shaderFileSuffix}'));

  ShaderResult? result(String name) => _results[name];

  /// The parameters [name] declares, read from its file and includes. Null when there is no such file.
  ShaderInfo? info(String name) {
    final cached = _infos[name];
    if (cached != null) return cached;
    final f = file(name);
    if (f == null || !f.existsSync()) return null;
    return _infos[name] = parseShader(f);
  }

  /// Whether [name] has a compiled program of its own.
  bool hasProgram(String name) => _programs.containsKey(name);

  /// The best program for [name]: its last good compile, else the bundled one.
  ui.FragmentProgram program(String name) => _programs[name] ?? bundled;

  static Directory get _liveDir =>
      Directory(p.join(p.dirname(Platform.resolvedExecutable), Cfg.bundleAssets, Cfg.liveFolder));

  static String get _home => Platform.environment['HOME'] ?? '.';

  static Directory get _impellerDir {
    final root = Platform.environment['FLUTTER_ROOT'] ?? p.join(_home, Cfg.flutterRootFallback);
    return Directory(p.dirname(p.join(root, Cfg.impellerPath)));
  }

  /// Empties the live folder left over from an earlier run.
  static void clearLive() {
    try {
      final dir = _liveDir;
      if (dir.existsSync()) dir.deleteSync(recursive: true);
    } catch (_) {
      // Leftover files only waste space.
    }
  }

  /// Finds the library next to the project that holds [skinsFolder] and starts watching it.
  Future<void> watch(Directory skinsFolder) async {
    await _watch?.cancel();
    _watch = null;
    for (final t in _timers.values) {
      t.cancel();
    }
    _timers.clear();
    _programs.clear();
    _results.clear();
    _compiledText.clear();
    _infos.clear();
    _dir = _findLibrary(skinsFolder);
    _scan();
    final dir = _dir;
    if (dir != null) _watch = DirectoryWatcher(dir.path).events.listen(_onEvent);
    notifyListeners();
  }

  Directory? _findLibrary(Directory start) {
    final root = findProjectRoot(start);
    if (root == null) return null;
    final lib = Directory(p.join(root.path, Cfg.shaderFolder));
    return lib.existsSync() ? lib : null;
  }

  void _scan() {
    final dir = _dir;
    _names = dir == null
        ? []
        : [
            for (final f in dir.listSync().whereType<File>())
              if (f.path.endsWith(Cfg.shaderFileSuffix)) p.basenameWithoutExtension(f.path),
          ]
      ..sort();
  }

  void _onEvent(WatchEvent e) {
    final base = p.basename(e.path);
    if (base.startsWith('.')) return;
    if (base.endsWith(Cfg.includeSuffix) || base.endsWith(Cfg.shaderFileSuffix)) _infos.clear();
    if (base.endsWith(Cfg.includeSuffix)) {
      _timers['*']?.cancel();
      _timers['*'] = Timer(Cfg.shaderReloadDebounce, () {
        for (final name in _programs.keys.toList()) {
          unawaited(compile(name, announce: true, force: true));
        }
      });
    } else if (base.endsWith(Cfg.shaderFileSuffix)) {
      final name = p.basenameWithoutExtension(base);
      _timers[name]?.cancel();
      _timers[name] = Timer(Cfg.shaderReloadDebounce, () {
        final before = _names.length;
        _scan();
        if (_names.length != before) notifyListeners();
        if (e.type == ChangeType.REMOVE) return;
        if (_programs.containsKey(name) || _results.containsKey(name)) unawaited(compile(name, announce: true, force: false));
      });
    }
  }

  /// Compiles [name] unless it already has a program.
  Future<void> ensure(String name) async {
    if (_programs.containsKey(name) || _results.containsKey(name) || !canCompile || file(name)?.existsSync() != true) return;
    if (!_ensuring.add(name)) return;
    try {
      await compile(name);
    } finally {
      _ensuring.remove(name);
    }
  }

  /// Compiles [name]. Unless [force], does nothing when the file is unchanged since the last compile.
  /// [announce] reports the result to [onReloaded].
  Future<ShaderResult?> compile(String name, {bool announce = false, bool force = true}) {
    _pending++;
    notifyListeners();
    final done = _queue.then((_) => _compile(name, announce, force));
    _queue = done.then((_) {}, onError: (_) {});
    return done.whenComplete(() {
      _pending--;
      notifyListeners();
    });
  }

  Future<ShaderResult?> _compile(String name, bool announce, bool force) async {
    final source = file(name);
    if (source == null || !source.existsSync()) return null;
    final text = await source.readAsString();
    if (!force && _compiledText[name] == text) return null;
    _compiledText[name] = text;
    final result = await _run(name, source);
    _results[name] = result.$1;
    final program = result.$2;
    if (program != null) _programs[name] = program;
    notifyListeners();
    if (announce || !result.$1.ok) onReloaded?.call(result.$1);
    return result.$1;
  }

  Future<(ShaderResult, ui.FragmentProgram?)> _run(String name, File source) async {
    ShaderResult fail(String log) => ShaderResult(name, ok: false, errors: _parseErrors(log), log: log, time: DateTime.now());
    if (!canCompile) return (fail('impellerc not found in ${_impellerDir.path}'), null);
    final cache = Directory(p.join(_home, Cfg.cacheFolder))..createSync(recursive: true);
    final live = _liveDir..createSync(recursive: true);
    final key = '${Cfg.liveFolder}/${name}_${++_counter}.frag';
    final out = File(p.join(live.parent.path, key));
    final impeller = _impellerDir;

    List<String> args({required bool sksl}) => [
          if (sksl) '--sksl',
          '--runtime-stage-gles', '--runtime-stage-gles3', '--runtime-stage-vulkan',
          '--iplr', '--sl=${out.path}', '--spirv=${p.join(cache.path, 'skin.spirv')}',
          '--input=${source.path}', '--input-type=frag',
          '--include=${source.parent.path}', '--include=${p.join(impeller.path, Cfg.shaderLibFolder)}',
          '--depfile=${p.join(cache.path, 'skin.d')}',
          '--reflection-json=${p.join(cache.path, 'skin.json')}',
          '--verbose',
        ];

    Future<(int, String)> run(bool sksl) async {
      final r = await Process.run(p.join(impeller.path, 'impellerc'), args(sksl: sksl), environment: {'TMPDIR': cache.path});
      return (r.exitCode, '${r.stdout}${r.stderr}'.trim());
    }

    var (code, log) = await run(true);
    if (code != 0) {
      final first = log;
      (code, log) = await run(false);
      if (code != 0) log = first;
    }
    if (code != 0 || !out.existsSync()) return (fail(log), null);
    try {
      final program = await ui.FragmentProgram.fromAsset(key);
      return (ShaderResult(name, ok: true, errors: const [], log: log, time: DateTime.now()), program);
    } catch (e) {
      return (fail('$log\n$e'.trim()), null);
    } finally {
      try {
        out.deleteSync();
      } catch (_) {
        // The folder is cleared at the next start.
      }
    }
  }

  static List<ShaderError> _parseErrors(String log) => [
        for (final m in RegExp(r'^.*?:(\d+)(?::(\d+))?: error: (.*)$', multiLine: true).allMatches(log))
          ShaderError(int.parse(m[1]!), m[2] == null ? null : int.parse(m[2]!), m[3]!.trim()),
      ];

  @override
  void dispose() {
    _watch?.cancel();
    for (final t in _timers.values) {
      t.cancel();
    }
    super.dispose();
  }
}
