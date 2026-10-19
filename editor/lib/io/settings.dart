import 'dart:convert';
import 'dart:io';

import '../config.dart';

/// The few things the editor remembers between runs.
class Settings {
  Settings(this.folder, {this.tabsWidth = Cfg.tabsWidthDefault, this.cornerZoom = Cfg.cornerZoomDefault, this.previewPoem = Cfg.defaultPoem, Set<String>? closedSections, Map<String, String>? lastSkins}) : closedSections = closedSections ?? {}, lastSkins = lastSkins ?? {};

  String? folder;
  double tabsWidth;

  /// Screen pixels per card unit in the corner views.
  int cornerZoom;

  /// The poem shown on the card in the preview.
  int previewPoem;

  /// Properties sections the user has collapsed.
  final Set<String> closedSections;

  /// The skin that was open in each skins folder.
  final Map<String, String> lastSkins;

  static Settings load() {
    try {
      final data = jsonDecode(File(Cfg.settingsPath).readAsStringSync());
      if (data is! Map) return Settings(null);
      final t = data['tabsWidth'];
      return Settings(
        data['folder'] as String?,
        tabsWidth: t is num ? t.toDouble() : Cfg.tabsWidthDefault,
        cornerZoom: Cfg.cornerZooms.contains(data['cornerZoom']) ? data['cornerZoom'] as int : Cfg.cornerZoomDefault,
        previewPoem: data['previewPoem'] is int ? (data['previewPoem'] as int).clamp(1, Cfg.poemCount) : Cfg.defaultPoem,
        closedSections: {...?(data['closedSections'] as List?)?.whereType<String>()},
        lastSkins: {for (final e in ((data['lastSkins'] as Map?) ?? {}).entries) if (e.value is String) '${e.key}': e.value as String},
      );
    } catch (_) {
      return Settings(null);
    }
  }

  void save() {
    try {
      final file = File(Cfg.settingsPath);
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(jsonEncode({'folder': folder, 'tabsWidth': tabsWidth, 'cornerZoom': cornerZoom, 'previewPoem': previewPoem, 'closedSections': closedSections.toList(), 'lastSkins': lastSkins}));
    } catch (_) {
      // A settings file that cannot be written only loses the remembered settings.
    }
  }
}
