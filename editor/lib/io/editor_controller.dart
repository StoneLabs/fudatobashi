import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:path/path.dart' as p;
import 'package:watcher/watcher.dart';

import '../config.dart';
import '../model/shader_info.dart';
import '../model/skin.dart';
import '../model/skin_loader.dart';
import '../render/kana_texture.dart';
import '../render/light.dart';
import '../render/skin_scene.dart';
import '../render/thumbnail_cache.dart';
import 'image_check.dart';
import 'l10n_store.dart';
import 'project.dart';
import 'settings.dart';
import 'shader_library.dart';
import 'skin_textures.dart';
import 'texture_tabs.dart';

/// One row of the skin list.
class SkinEntry {
  SkinEntry(this.folder, this.name, this.key, this.tier, this.id, {this.shader = Cfg.standardShader, this.family = '', this.contentHash = 0});
  final String folder, name, key, tier, shader, family;
  final int id;

  /// Changes whenever the skin.json content does.
  final int contentHash;
}

/// A skin.json change on disk that is waiting for the user's decision.
class DiskChange {
  DiskChange(this.text, this.json);
  final String text;
  final Map<String, dynamic> json;
}

/// What "Apply to family" copies from the open skin to the others of its family.
class FamilyCopy {
  bool text = true, pattern = false, float = false, values = false;

  /// The skin.json keys to copy. A custom shader's numbers go only to skins on the same shader.
  List<String> keys({required bool sameShader}) => [
        if (text) 'text',
        if (pattern) patternKey,
        if (float) 'float',
        if (values && sameShader) ...['values', 'random', 'placements'],
      ];
}

/// One undo step: the skin.json and the two names.
class _Snapshot {
  _Snapshot(this.skin, this.en, this.ja);
  final String skin, en, ja;

  bool same(_Snapshot o) => skin == o.skin && en == o.en && ja == o.ja;
}

/// All state of the editor: folder, open skin, its images, preview and lighting.
class EditorController extends ChangeNotifier {
  EditorController(this.settings) {
    textures = SkinTextures(onMessage: setStatus)..addListener(notifyListeners);
    tabs.addListener(notifyListeners);
    l10n.addListener(_l10nChanged);
  }

  final Settings settings;
  late final SkinTextures textures;
  final TextureTabs tabs = TextureTabs();
  ShaderLibrary? _shaders;
  final L10nStore l10n = L10nStore();
  final ThumbnailCache thumbs = ThumbnailCache();

  ShaderLibrary get shaders => _shaders!;

  Directory? root;
  List<SkinEntry> skins = [];
  String? selected;
  Map<String, dynamic>? skin;
  bool dirty = false;

  /// The open skin's names as edited, and as they are in the l10n files.
  String nameEn = '', nameJa = '';
  String _savedEn = '', _savedJa = '';
  DiskChange? diskChange;

  int seed = Cfg.defaultSeed;
  late int poem = settings.previewPoem;

  /// The wear the preview shows, 0 new to 1 worn out, whatever the skin's float range.
  double wear = Cfg.defaultWear;
  Light light = lightPresets.first.light;
  String lightLabel = lightPresets.first.name;

  ui.Image? wearSheet;

  /// The kana layer and the badge layer of the open skin for the current poem; null until built.
  ui.Image? kana, badge;
  int? _kanaPoem;
  (int, ui.Offset)? _badgeFor;

  /// Seconds the view's animated shader has run; 0 while it is not animated.
  double time = 0;
  bool _animating = false;

  /// Card tilt of the main view, -1 to 1 on each axis. Preview only, never saved.
  ui.Offset tilt = ui.Offset.zero;

  String status = '';
  bool statusIsError = false;
  bool statusVisible = false;
  Timer? _statusTimer;

  /// Shown on the right of the status line: the shader's compile or annotation error.
  String? shaderStatus;

  Map<String, dynamic>? _saved;
  final List<_Snapshot> _undo = [], _redo = [];
  String? _lastEditKey;
  DateTime _lastEditAt = DateTime.fromMillisecondsSinceEpoch(0);

  /// While true the preview shows the last saved version of the skin.
  bool comparing = false;
  String? _diskText;
  StreamSubscription<WatchEvent>? _watch;
  Timer? _skinTimer, _rescanTimer;
  int _kanaToken = 0, _badgeToken = 0;
  bool _parseFailed = false;

  /// The shader the open skin is drawn with.
  String get shaderName => skin == null ? Cfg.standardShader : shaderOf(skin!);

  /// The parameters of the open skin's custom shader; null for the standard card.
  ShaderInfo? get customInfo => _customInfo(shaderName);

  ShaderInfo? _customInfo(String shader) => shader == Cfg.standardShader ? null : shaders.info(shader);

  /// The image slots of the open skin.
  List<Slot> get slots => slotsFor(customInfo);

  bool get hasPattern => textures.states[patternKey]?.source == SlotSource.own;

  SkinScene? get scene {
    final s = skin;
    if (s == null || _shaders == null) return null;
    return SkinScene(
      program: shaders.program(shaderName),
      custom: customInfo,
      skin: comparing && _saved != null ? _saved! : s,
      images: textures.images,
      kana: kana,
      badge: badge,
      wearSheet: wearSheet,
      seed: seed,
      wear: wear,
      light: light,
      tilt: tilt,
      time: time,
    );
  }

  Future<void> init(String? argFolder) async {
    ShaderLibrary.clearLive();
    final bundled = await ui.FragmentProgram.fromAsset(Cfg.shaderAsset);
    _shaders = ShaderLibrary(bundled: bundled, onReloaded: _shaderReloaded)..addListener(notifyListeners);
    final folder = argFolder ?? settings.folder;
    if (folder != null && Directory(folder).existsSync()) {
      await setFolder(folder);
    } else {
      setStatus('Choose a skins folder to begin');
    }
  }

  void _shaderReloaded(ShaderResult r) {
    if (r.ok) setStatus(r.summary);
    _showShaderProblem();
    // ignore: avoid_print
    print('[editor] ${r.summary}');
    notifyListeners();
  }

  /// Puts the open skin's shader error, or its first annotation problem, on the right of the status line.
  void _showShaderProblem() {
    final r = shaders.result(shaderName);
    final problem = customInfo?.errors.firstOrNull;
    shaderStatus = r != null && !r.ok ? r.summary : (problem == null ? null : '$problem');
  }

  /// Compiles the open skin's shader if that has not happened yet.
  void _useShader() {
    final name = shaderName;
    _showShaderProblem();
    unawaited(shaders.ensure(name).then((_) {
      if (name == shaderName) _showShaderProblem();
      _updateAnimation();
      notifyListeners();
    }));
    _updateAnimation();
  }

  /// Runs `uTime` while the shown shader is tagged @animated.
  void _updateAnimation() {
    final wanted = customInfo?.animated ?? false;
    if (!wanted) {
      time = 0;
      _animating = false;
      return;
    }
    if (_animating) return;
    _animating = true;
    Duration? start;
    void frame(Duration stamp) {
      if (!_animating) return;
      start ??= stamp;
      time = (stamp - start!).inMicroseconds / Duration.microsecondsPerSecond;
      notifyListeners();
      SchedulerBinding.instance.scheduleFrameCallback(frame);
    }

    SchedulerBinding.instance.scheduleFrameCallback(frame);
  }

  void setTilt(ui.Offset value) {
    tilt = ui.Offset(value.dx.clamp(-1.0, 1.0), value.dy.clamp(-1.0, 1.0));
    notifyListeners();
  }

  void resetTilt() => setTilt(ui.Offset.zero);

  void setStatus(String message, {bool error = false}) {
    status = message;
    statusIsError = error;
    statusVisible = true;
    _statusTimer?.cancel();
    if (!error) _statusTimer = Timer(Cfg.statusLifetime, _hideStatus);
    // ignore: avoid_print
    print('[editor] $message');
    notifyListeners();
  }

  void _hideStatus() {
    statusVisible = false;
    notifyListeners();
  }

  /// A click anywhere clears an error message.
  void dismissError() {
    if (statusVisible && statusIsError) _hideStatus();
  }

  // Folder

  Future<void> setFolder(String path) async {
    final dir = Directory(path);
    root = Directory(p.normalize(dir.absolute.path));
    settings.folder = root!.path;
    settings.save();
    await _watch?.cancel();
    _watch = DirectoryWatcher(root!.path).events.listen(_onEvent);
    skin = null;
    selected = null;
    dirty = false;
    diskChange = null;
    thumbs.clear();
    await shaders.watch(root!);
    await l10n.attach(root!);
    await _loadEngineImages();
    await _rescan();
    if (skins.isNotEmpty) {
      final last = settings.lastSkins[root!.path];
      await selectSkin(skins.any((s) => s.folder == last) ? last! : skins.first.folder);
    } else {
      setStatus('No skins in ${root!.path}');
    }
    notifyListeners();
  }

  Future<void> _loadEngineImages() async {
    final r = root;
    if (r == null) return;
    wearSheet = await loadEngineImage(r, Cfg.wearSheetFile);
    notifyListeners();
  }

  Future<void> _rescan() async {
    final r = root;
    if (r == null) return;
    final previous = skins;
    final found = await scanSkins(r);
    skins = [
      for (final s in found)
        SkinEntry(
          p.basename(s.dir.path),
          l10n.name('en', p.basename(s.dir.path)) ?? p.basename(s.dir.path),
          (readPath(s.json, 'key') as String?) ?? p.basename(s.dir.path),
          (readPath(s.json, 'tier') as String?) ?? '',
          (readPath(s.json, 'id') as num?)?.toInt() ?? 0,
          shader: shaderOf(s.json),
          family: (readPath(s.json, 'family') as String?) ?? '',
          contentHash: jsonEncode(s.json).hashCode,
        ),
    ];
    final open = selected;
    if (open != null && !skins.any((s) => s.folder == open)) {
      if (skinFile!.existsSync()) {
        // The open skin.json is mid-edit and does not parse: keep it open.
        final old = previous.where((s) => s.folder == open);
        skins = [...skins, ...old]..sort((a, b) => a.folder.compareTo(b.folder));
        notifyListeners();
        return;
      }
      selected = null;
      skin = null;
      if (skins.isNotEmpty) await selectSkin(skins.first.folder);
    }
    notifyListeners();
  }

  Directory? get skinDir => root == null || selected == null ? null : Directory(p.join(root!.path, selected!));
  File? get skinFile => skinDir == null ? null : File(p.join(skinDir!.path, Cfg.skinFileName));

  Future<void> selectSkin(String folder) async {
    final r = root;
    if (r == null) return;
    final file = File(p.join(r.path, folder, Cfg.skinFileName));
    try {
      final text = await file.readAsString();
      final json = jsonDecode(text) as Map<String, dynamic>;
      final problem = formatProblem(json);
      if (problem != null) {
        setStatus('$folder/${Cfg.skinFileName}: $problem', error: true);
        return;
      }
      selected = folder;
      if (settings.lastSkins[r.path] != folder) {
        settings.lastSkins[r.path] = folder;
        settings.save();
      }
      skin = json;
      _saved = _copy(json);
      _diskText = text;
      _loadNames();
      _clearHistory();
      dirty = false;
      diskChange = null;
      _useShader();
      textures.open(r, file.parent, slots);
      notifyListeners();
    } on FormatException catch (e) {
      setStatus('$folder/${Cfg.skinFileName}: ${_describe(e, await file.readAsString())}', error: true);
    } catch (e) {
      setStatus('$folder/${Cfg.skinFileName} could not be opened: $e', error: true);
    }
  }

  // Watching

  void _onEvent(WatchEvent e) {
    final r = root;
    if (r == null) return;
    final rel = p.relative(e.path, from: r.path);
    final parts = p.split(rel);
    if (parts.any((s) => s.startsWith('.'))) return;
    if (Cfg.ignoredSuffixes.any(parts.last.endsWith)) return;
    if (parts.length == 2 && parts[1] == Cfg.skinFileName) {
      _rescanTimer?.cancel();
      _rescanTimer = Timer(Cfg.folderRescanDebounce, _rescan);
      if (parts[0] == selected) {
        _skinTimer?.cancel();
        _skinTimer = Timer(Cfg.skinFileDebounce, _skinFileChanged);
      }
    } else if (parts.length == 1) {
      _rescanTimer?.cancel();
      _rescanTimer = Timer(Cfg.folderRescanDebounce, _rescan);
    } else if (parts.length == 2 && parts[1].endsWith(Cfg.imageSuffix)) {
      thumbs.forget('skin:${parts[0]}');
      notifyListeners();
    }
    textures.fileEvent(e.path, removed: e.type == ChangeType.REMOVE);
  }

  Future<void> _skinFileChanged() async {
    final file = skinFile;
    if (file == null || !file.existsSync()) return;
    final label = '$selected/${Cfg.skinFileName}';
    final String text;
    try {
      text = await file.readAsString();
    } catch (_) {
      return;
    }
    if (text == _diskText) {
      if (_parseFailed) {
        _parseFailed = false;
        setStatus('$label is valid again');
      }
      return;
    }
    final Map<String, dynamic> json;
    try {
      json = jsonDecode(text) as Map<String, dynamic>;
    } on FormatException catch (e) {
      _parseFailed = true;
      setStatus('$label: ${_describe(e, text)}', error: true);
      return;
    } catch (_) {
      _parseFailed = true;
      setStatus('$label is not a JSON object', error: true);
      return;
    }
    _diskText = text;
    _parseFailed = false;
    if (dirty) {
      diskChange = DiskChange(text, json);
      notifyListeners();
    } else {
      _applyDisk(json);
      setStatus('$label reloaded (changed on disk)');
    }
  }

  void loadFromDisk() {
    final c = diskChange;
    if (c == null) return;
    _applyDisk(c.json);
    setStatus('$selected/${Cfg.skinFileName} reloaded (changed on disk)');
  }

  void keepMine() {
    diskChange = null;
    notifyListeners();
  }

  void _applyDisk(Map<String, dynamic> json) {
    final oldShader = shaderName;
    skin = json;
    _saved = _copy(json);
    _loadNames();
    _clearHistory();
    dirty = false;
    diskChange = null;
    _afterSkinChange(oldShader);
    notifyListeners();
  }

  /// Follows the skin to another shader: compiles it and points the slots at its images.
  void _afterSkinChange(String oldShader) {
    if (shaderName == oldShader) return;
    _useShader();
    textures.open(root!, skinDir!, slots);
  }

  String _describe(FormatException e, String text) {
    final at = e.offset;
    if (at == null) return e.message;
    final before = text.substring(0, at.clamp(0, text.length));
    final line = '\n'.allMatches(before).length + 1;
    final column = at - (before.lastIndexOf('\n') + 1) + 1;
    return '${e.message} (line $line, column $column)';
  }

  // Editing

  Object? valueOf(SkinField f) => readPath(skin!, f.path) ?? f.defaultValue;

  void setField(SkinField f, Object? value) {
    final s = skin;
    if (s == null) return;
    final oldShader = shaderName;
    final changed = _edit(f.path, () {
      if (f.kind == FieldKind.shader) {
        _setShader(s, '$value');
      } else if (f.emptyIsNull && value is String && value.trim().isEmpty) {
        writePath(s, f.path, null);
      } else {
        writePath(s, f.path, _normalize(f, value, readPath(s, f.path)));
      }
    });
    if (!changed) return;
    _afterSkinChange(oldShader);
    notifyListeners();
  }

  /// The standard card keeps no shader entries; a custom shader gets its numbers at their defaults.
  void _setShader(Map<String, dynamic> json, String shader) {
    for (final k in Cfg.customShaderKeys) {
      json.remove(k);
    }
    if (shader == Cfg.standardShader) return;
    json['shader'] = shader;
    final info = shaders.info(shader);
    if (info != null) fillCustomDefaults(json, info);
  }

  _Snapshot _snapshot() => _Snapshot(jsonEncode(skin), nameEn, nameJa);

  /// Runs [mutate] and records an undo step unless the edit repeats [key] within the merge window.
  bool _edit(String key, void Function() mutate) {
    final before = _snapshot();
    mutate();
    if (before.same(_snapshot())) return false;
    final now = DateTime.now();
    final merge = key == _lastEditKey && now.difference(_lastEditAt) < Cfg.undoMergeWindow;
    _lastEditKey = key;
    _lastEditAt = now;
    if (!merge) {
      _undo.add(before);
      if (_undo.length > Cfg.undoLimit) _undo.removeAt(0);
      _redo.clear();
    }
    dirty = _isDirty();
    return true;
  }

  void _clearHistory() {
    _undo.clear();
    _redo.clear();
    _lastEditKey = null;
  }

  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;

  void undo() {
    if (_undo.isEmpty) return;
    _redo.add(_snapshot());
    _restore(_undo.removeLast());
  }

  void redo() {
    if (_redo.isEmpty) return;
    _undo.add(_snapshot());
    _restore(_redo.removeLast());
  }

  void _restore(_Snapshot snap) {
    final oldShader = shaderName;
    _lastEditKey = null;
    skin = jsonDecode(snap.skin) as Map<String, dynamic>;
    nameEn = snap.en;
    nameJa = snap.ja;
    dirty = _isDirty();
    _afterSkinChange(oldShader);
    notifyListeners();
  }

  /// Goes back to the saved file. Undo brings the edits back.
  void revert() {
    final saved = _saved;
    if (skin == null || saved == null) return;
    final oldShader = shaderName;
    final changed = _edit('revert', () {
      skin = _copy(saved);
      nameEn = _savedEn;
      nameJa = _savedJa;
    });
    _lastEditKey = null;
    if (!changed) return;
    _afterSkinChange(oldShader);
    notifyListeners();
  }

  void setComparing(bool value) {
    if (comparing == value) return;
    comparing = value;
    notifyListeners();
  }

  bool _isDirty() => jsonEncode(skin) != jsonEncode(_saved) || nameEn != _savedEn || nameJa != _savedJa;

  void setName(String lang, String value) {
    if (selected == null) return;
    final changed = _edit('name.$lang', () {
      if (lang == 'en') {
        nameEn = value;
      } else {
        nameJa = value;
      }
    });
    if (changed) notifyListeners();
  }

  void _loadNames() {
    final key = selected;
    nameEn = _savedEn = key == null ? '' : l10n.name('en', key) ?? '';
    nameJa = _savedJa = key == null ? '' : l10n.name('ja', key) ?? '';
  }

  Future<void> _l10nChanged() async {
    if (root == null) return;
    await _rescan();
    if (selected != null && nameEn == _savedEn && nameJa == _savedJa) {
      _loadNames();
      notifyListeners();
    }
  }

  Object? _normalize(SkinField f, Object? v, Object? previous) {
    if (v is List && (f.kind == FieldKind.range || f.kind == FieldKind.numbers)) {
      final prev = previous is List ? previous : const [];
      return [for (var i = 0; i < v.length; i++) _number(f, v[i] as num, i < prev.length ? prev[i] : null)];
    }
    if (v is num) return _number(f, v, previous);
    return v;
  }

  Object _number(SkinField f, num v, Object? previous) {
    var d = v.toDouble();
    if (f.min != null && d < f.min!) d = f.min!;
    if (f.max != null && d > f.max!) d = f.max!;
    final step = f.step ?? (f.kind == FieldKind.integer ? 1.0 : null);
    if (step != null) {
      d = (d / step).round() * step;
      final text = step.toString();
      final dot = text.indexOf('.');
      final decimals = text.endsWith('.0') || dot < 0 ? 0 : text.length - dot - 1;
      d = double.parse(d.toStringAsFixed(decimals));
    }
    if (f.kind == FieldKind.integer || (d == d.truncateToDouble() && previous is int)) return d.round();
    return d;
  }

  String _encode(Map<String, dynamic> json) => '${JsonEncoder.withIndent(' ' * Cfg.jsonIndent).convert(json)}\n';

  Future<void> save() async {
    final s = skin, file = skinFile, key = selected;
    if (s == null || file == null || key == null) return;
    final text = _encode(s);
    try {
      await writeAtomic(file, text);
    } catch (e) {
      setStatus('Could not save ${Cfg.skinFileName}: $e', error: true);
      return;
    }
    _diskText = text;
    _saved = _copy(s);
    try {
      if (l10n.available) {
        if (nameEn != _savedEn) await _writeName('en', key, nameEn);
        if (nameJa != _savedJa) await _writeName('ja', key, nameJa);
        _savedEn = nameEn;
        _savedJa = nameJa;
      }
    } catch (e) {
      dirty = _isDirty();
      setStatus('Saved ${Cfg.skinFileName}, but the names could not be saved: $e', error: true);
      return;
    }
    dirty = _isDirty();
    diskChange = null;
    setStatus('$selected/${Cfg.skinFileName} saved');
  }

  /// An empty name is only written when the file already has the key.
  Future<void> _writeName(String lang, String key, String value) async {
    if (value.isEmpty && l10n.name(lang, key) == null) return;
    await l10n.setName(lang, key, value);
  }

  Future<void> createL10nFiles() async {
    try {
      await l10n.create();
      setStatus('Created ${Cfg.l10nFolder}');
    } catch (e) {
      setStatus('Could not create ${Cfg.l10nFolder}: $e', error: true);
    }
  }

  /// Runs [mutate] on the open skin as one undoable edit. Returns whether anything changed.
  bool editSkin(String key, void Function(Map<String, dynamic> skin) mutate) {
    final s = skin;
    if (s == null) return false;
    final changed = _edit(key, () => mutate(s));
    if (changed) notifyListeners();
    return changed;
  }


  // Image files

  /// Makes [source] the skin's `<slot>.png`. Another format is converted to PNG. A file that was
  /// there goes to the trash.
  Future<void> setSlotFile(String slot, File source) async {
    final dir = skinDir;
    if (dir == null) return;
    final target = File(p.join(dir.path, '$slot${Cfg.imageSuffix}'));
    if (p.equals(p.normalize(source.absolute.path), p.normalize(target.absolute.path))) {
      await textures.reload(slot);
      return;
    }
    try {
      var bytes = await source.readAsBytes();
      if (!isPng(bytes)) bytes = await _toPng(bytes);
      if (target.existsSync()) await moveToTrash(target);
      await writeAtomicBytes(target, bytes);
    } catch (e) {
      setStatus('Could not use ${p.basename(source.path)} for $slot: $e', error: true);
      return;
    }
    await textures.reload(slot);
    thumbs.forget('skin:$selected');
    setStatus('${target.path} now holds ${p.basename(source.path)}');
  }

  Future<Uint8List> _toPng(Uint8List bytes) async {
    final image = await decodeImage(bytes);
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (png == null) throw 'it could not be turned into a PNG';
    return png.buffer.asUint8List();
  }

  /// Moves the skin's `<slot>.png` to the trash, so the slot shows its default.
  Future<void> clearSlotFile(String slot) async {
    final dir = skinDir;
    if (dir == null) return;
    final file = File(p.join(dir.path, '$slot${Cfg.imageSuffix}'));
    if (!file.existsSync()) return;
    final trashed = await moveToTrash(file);
    await textures.reload(slot);
    thumbs.forget('skin:$selected');
    setStatus(trashed ? 'Moved ${p.basename(file.path)} to the trash' : 'Deleted ${p.basename(file.path)}');
  }

  // Family

  /// The folders of the other skins in the open skin's family.
  List<String> get familyMates {
    final family = skin == null ? '' : (readPath(skin!, 'family') as String? ?? '');
    if (family.isEmpty) return const [];
    return [for (final e in skins) if (e.family == family && e.folder != selected) e.folder];
  }

  Map<String, String>? _familyBefore;

  /// How many skins the last "Apply to family" changed and can still undo.
  int get familyUndoCount => _familyBefore?.length ?? 0;

  /// Copies the chosen parts of the open skin into the other skins of its family and saves them.
  Future<void> applyToFamily(FamilyCopy what) async {
    final s = skin;
    if (s == null) return;
    final before = <String, String>{};
    for (final folder in familyMates) {
      final file = File(p.join(root!.path, folder, Cfg.skinFileName));
      try {
        final text = await file.readAsString();
        final json = jsonDecode(text) as Map<String, dynamic>;
        for (final k in what.keys(sameShader: shaderOf(json) == shaderName)) {
          if (s.containsKey(k)) {
            json[k] = _copy({k: s[k]})[k];
          } else {
            json.remove(k);
          }
        }
        final out = _encode(json);
        if (out == text) continue;
        await writeAtomic(file, out);
        before[folder] = text;
      } catch (e) {
        setStatus('Could not update $folder: $e', error: true);
      }
    }
    _familyBefore = before.isEmpty ? null : before;
    setStatus(before.isEmpty ? 'The family already matches' : 'Updated ${before.length} skins');
    notifyListeners();
  }

  /// Puts the family skins back as they were before the last "Apply to family".
  Future<void> undoFamilyApply() async {
    final before = _familyBefore;
    if (before == null) return;
    for (final e in before.entries) {
      try {
        await writeAtomic(File(p.join(root!.path, e.key, Cfg.skinFileName)), e.value);
      } catch (err) {
        setStatus('Could not restore ${e.key}: $err', error: true);
      }
    }
    _familyBefore = null;
    setStatus('Restored ${before.length} skins');
    notifyListeners();
  }

  // Managing skins

  /// Why [key] cannot be a new skin folder, or null.
  String? validateKey(String key) {
    if (!Cfg.skinKeyPattern.hasMatch(key)) return 'Use lowercase letters, digits and _, starting with a letter';
    if (root != null && FileSystemEntity.typeSync(p.join(root!.path, key)) != FileSystemEntityType.notFound) {
      return 'A file or folder named $key already exists';
    }
    return null;
  }

  int get nextId => skins.fold(0, (m, s) => s.id > m ? s.id : m) + 1;

  Future<void> _writeNames(String key, String en, String ja) async {
    if (!l10n.available) return;
    if (en.isNotEmpty) await l10n.setName('en', key, en);
    if (ja.isNotEmpty) await l10n.setName('ja', key, ja);
  }

  /// Creates an empty skin folder drawn with [shader]. Returns an error message, or null.
  Future<String?> createSkin(String key, String en, String ja, String tier, String shader) async {
    final error = validateKey(key);
    if (error != null) return error;
    try {
      final dir = Directory(p.join(root!.path, key))..createSync();
      final json = newSkin(id: nextId, key: key, tier: tier, shader: shader, info: _customInfo(shader));
      await writeAtomic(File(p.join(dir.path, Cfg.skinFileName)), _encode(json));
      final sharedWear = File(p.join(root!.path, Cfg.sharedWearFile));
      if (sharedWear.existsSync()) await sharedWear.copy(p.join(dir.path, 'wear.png'));
      await _writeNames(key, en, ja);
    } catch (e) {
      return 'Could not create $key: $e';
    }
    await _rescan();
    await selectSkin(key);
    setStatus('Created $key. Put its images in ${p.join(root!.path, key)}');
    return null;
  }

  /// Copies the skin folder of [from] with a new key and id. Returns an error message, or null.
  Future<String?> duplicateSkin(String from, String key, String en, String ja) async {
    final error = validateKey(key);
    if (error != null) return error;
    try {
      final dir = Directory(p.join(root!.path, key));
      await _copyDir(Directory(p.join(root!.path, from)), dir);
      final file = File(p.join(dir.path, Cfg.skinFileName));
      final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>
        ..['key'] = key
        ..['id'] = nextId;
      await writeAtomic(file, _encode(json));
      await _writeNames(key, en, ja);
    } catch (e) {
      return 'Could not duplicate $from: $e';
    }
    await _rescan();
    await selectSkin(key);
    setStatus('Created $key from $from');
    return null;
  }

  Future<void> _copyDir(Directory from, Directory to) async {
    to.createSync();
    await for (final e in from.list(followLinks: false)) {
      final target = p.join(to.path, p.basename(e.path));
      if (e is Directory) {
        await _copyDir(e, Directory(target));
      } else if (e is File) {
        await e.copy(target);
      }
    }
  }

  /// Renames the folder, the key in skin.json and the l10n keys. Returns an error message, or null.
  Future<String?> renameSkin(String from, String to) async {
    final error = validateKey(to);
    if (error != null) return error;
    try {
      final dir = await Directory(p.join(root!.path, from)).rename(p.join(root!.path, to));
      final file = File(p.join(dir.path, Cfg.skinFileName));
      final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>..['key'] = to;
      await writeAtomic(file, _encode(json));
      await l10n.renameKey(from, to);
    } catch (e) {
      return 'Could not rename $from: $e';
    }
    final wasOpen = selected == from;
    if (wasOpen) {
      selected = null;
      skin = null;
      dirty = false;
    }
    await _rescan();
    if (wasOpen) await selectSkin(to);
    setStatus('Renamed $from to $to');
    return null;
  }

  /// Moves the skin folder to the trash when `gio` can, else deletes it, and removes its l10n keys.
  Future<void> deleteSkin(String folder) async {
    final dir = Directory(p.join(root!.path, folder));
    var trashed = false;
    try {
      trashed = await moveToTrash(dir);
      if (l10n.available) await l10n.remove(folder);
    } catch (e) {
      setStatus('Could not delete $folder: $e', error: true);
      return;
    }
    if (selected == folder) {
      selected = null;
      skin = null;
      dirty = false;
      diskChange = null;
    }
    await _rescan();
    if (selected == null && skins.isNotEmpty) await selectSkin(skins.first.folder);
    setStatus(trashed ? 'Moved $folder to trash' : 'Deleted $folder');
  }

  // Thumbnails

  Future<SkinScene> _thumbScene(String shader, Map<String, dynamic> json, Map<String, ui.Image> images) async {
    return SkinScene(
        program: shaders.program(shader),
        custom: _customInfo(shader),
        skin: json,
        images: images,
        kana: kana ?? await buildKanaTexture(poem),
        badge: await buildBadgeTexture(poem, badgeCenter(json)),
        wearSheet: wearSheet,
        seed: Cfg.thumbSeed,
        wear: Cfg.thumbWear,
        light: lightPresets.first.light,
      );
  }

  String _shaderStamp(String name) => '${shaders.hasProgram(name)}${shaders.result(name)?.time.microsecondsSinceEpoch}';

  /// Asks for a fresh thumbnail of [e] and returns its cache key.
  String skinThumbKey(SkinEntry e) {
    final key = 'skin:${e.folder}';
    final r = root;
    if (r == null || _shaders == null) return key;
    unawaited(shaders.ensure(e.shader));
    if (e.folder == selected && skin != null) {
      final stamp = '${jsonEncode(skin)}|${kana != null}|${textures.images.values.fold(0, (a, i) => a ^ identityHashCode(i))}';
      thumbs.request(key, '$stamp|${_shaderStamp(shaderName)}', () async {
        final json = skin;
        if (selected != e.folder || json == null) return null;
        return renderThumbnail(await _thumbScene(shaderName, json, textures.images));
      });
    } else {
      thumbs.request(key, '${e.contentHash}|${kana != null}|${_shaderStamp(e.shader)}', () async {
        final dir = Directory(p.join(r.path, e.folder));
        final json = jsonDecode(await File(p.join(dir.path, Cfg.skinFileName)).readAsString()) as Map<String, dynamic>;
        if (formatProblem(json) != null) return null;
        final shader = shaderOf(json);
        final images = await loadSkinImages(r, dir, slotsFor(_customInfo(shader)), maxWidth: Cfg.thumbTextureWidth);
        return renderThumbnail(await _thumbScene(shader, json, images));
      });
    }
    return key;
  }

  Map<String, dynamic> _copy(Map<String, dynamic> m) => jsonDecode(jsonEncode(m)) as Map<String, dynamic>;

  // Preview

  void randomSeed() => setSeed(math.Random().nextInt(Cfg.seedMax + 1));

  /// The preview poem is an editor setting, remembered between runs. It never marks a skin as unsaved.
  void setPreviewPoem(int v) {
    setPoem(v);
    settings.previewPoem = poem;
    settings.save();
  }

  void setSeed(int v) {
    seed = v.clamp(0, Cfg.seedMax);
    notifyListeners();
  }

  void setWear(double v) {
    wear = v.clamp(0.0, 1.0);
    notifyListeners();
  }

  void setPoem(int v) {
    final n = v.clamp(1, Cfg.poemCount);
    if (n == poem) return;
    poem = n;
    notifyListeners();
  }

  /// Builds the kana and badge layers again when the poem or the badge position has changed.
  void _syncText() {
    final s = skin;
    if (s == null) return;
    final center = badgeCenter(s);
    if (_kanaPoem != poem) {
      final p = _kanaPoem = poem;
      final token = ++_kanaToken;
      buildKanaTexture(p).then((image) {
        if (token != _kanaToken) return;
        kana = image;
        super.notifyListeners();
      });
    }
    if (_badgeFor != (poem, center)) {
      final key = _badgeFor = (poem, center);
      final token = ++_badgeToken;
      buildBadgeTexture(poem, center).then((image) {
        if (token != _badgeToken) return;
        badge = image;
        _badgeFor = key;
        super.notifyListeners();
      });
    }
  }

  @override
  void notifyListeners() {
    _syncText();
    super.notifyListeners();
  }

  /// Sets the texture pane's width while its splitter is dragged; [remember] saves it at the end of the drag.
  void setTabsWidth(double? width, {bool remember = false}) {
    if (width != null) settings.tabsWidth = width;
    if (remember) settings.save();
    notifyListeners();
  }

  void setCornerZoom(int zoom) {
    settings.cornerZoom = zoom;
    settings.save();
    notifyListeners();
  }

  void usePreset(LightPreset preset) {
    light = preset.light;
    lightLabel = preset.name;
    notifyListeners();
  }

  void setLight(Light value) {
    light = value;
    lightLabel = 'Custom';
    notifyListeners();
  }

  @override
  void dispose() {
    l10n.dispose();
    _watch?.cancel();
    _skinTimer?.cancel();
    _rescanTimer?.cancel();
    _statusTimer?.cancel();
    textures.dispose();
    thumbs.dispose();
    tabs.dispose();
    _shaders?.dispose();
    super.dispose();
  }
}
