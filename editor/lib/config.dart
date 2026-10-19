import 'dart:io';
import 'dart:ui';

/// Every tuning number of the editor lives here.
abstract final class Cfg {
  // Card geometry, in card units.
  static const double cardWidth = 374;
  static const double cardHeight = 525;

  /// Room around the card in the full-card view, in card units.
  static const double viewMargin = 70;

  /// Pixels per card unit in the kana texture.
  static const double kanaScale = 2;

  /// Blur of the kana halo, in card units.
  static const double haloBlur = 2.4;

  /// How much brighter the blurred halo is made so it reads as a glow.
  static const double haloGain = 2.8;

  /// How many wear sheets the card covers, drawn between these per seed.
  static const double wearWindowScaleMin = 1.6, wearWindowScaleMax = 1.8;

  static const int seedMax = 999;
  static const int defaultSeed = 17;
  static const int defaultPoem = 1;
  static const int poemCount = 100;

  /// The wear the preview starts with, 0 new to 1 worn out.
  static const double defaultWear = 0.12;

  /// The preview float counts as inside the skin's float range this close to its ends.
  static const double wearRangeSlack = 1e-6;

  // Timings the UI uses later.
  static const Duration textureReloadDebounce = Duration(milliseconds: 150);
  static const Duration shaderReloadDebounce = Duration(milliseconds: 300);

  /// Waits before each retry of a texture that would not decode yet.
  static const List<Duration> decodeRetryDelays = [
    Duration(milliseconds: 100),
    Duration(milliseconds: 200),
    Duration(milliseconds: 400),
    Duration(milliseconds: 800),
  ];

  /// A delete waits this long before the slot shows Missing, because some
  /// tools delete a file and write it again.
  static const Duration deleteGrace = Duration(seconds: 1);

  /// Wait after the last change of skin.json or the folder before reading it.
  static const Duration skinFileDebounce = Duration(milliseconds: 150);
  static const Duration folderRescanDebounce = Duration(milliseconds: 300);

  /// How often a file is re-checked while an editor is still writing it.
  static const int stableReadTries = 5;

  /// Files the watcher ignores: hidden files and editor leftovers.
  static const List<String> ignoredSuffixes = ['~', '.tmp', '.part', '.xcf', '.kra', '.ase', '.aseprite'];

  static const int jsonIndent = 2;

  // Shader reload.
  static const String shaderFolder = 'shaders';
  static const String projectFileName = 'pubspec.yaml';
  static const String flutterRootFallback = 'dev/flutter';
  static const String impellerPath = 'bin/cache/artifacts/engine/linux-x64/impellerc';
  static const String shaderLibFolder = 'shader_lib';
  static const String liveFolder = '__live__';
  static const String bundleAssets = 'data/flutter_assets';
  static const String cacheFolder = '.cache/fudatobashi-skin-editor';
  static const String shaderAsset = 'shaders/standard.frag';
  static const String standardShader = 'standard';

  /// The skin.json keys that belong to a custom shader; the standard card has none of them.
  static const List<String> customShaderKeys = ['shader', 'values', 'random', 'placements'];
  static const String shaderFileSuffix = '.frag';
  static const String includeSuffix = '.glsl';

  /// The include every shader reads; its form sections come last.
  static const String sharedInclude = 'common.glsl';
  static const int includeDepthMax = 8;

  /// Form section for a parameter its shader gave no group.
  static const String defaultGroup = 'Other';
  static const double defaultNumberStep = 0.01;

  // Command-line export.
  static const double exportScale = 2;
  static const int exportSeed = 1;

  // Card tilt preview.
  /// Tilt at full drag, in radians.
  static const double maxTilt = 0.5;

  /// How textures are sampled by the card shader.
  static const FilterQuality textureFilter = FilterQuality.medium;

  /// More samplers than any shader declares; the binder stops looking for samplers here.
  static const int samplerLimit = 64;

  // What a slot without a file gives the shader: one texel of this colour.
  static const Color blackTexel = Color(0xFF000000), whiteTexel = Color(0xFFFFFFFF), greyTexel = Color(0xFF808080);
  static const Color clearTexel = Color(0x00000000);
  static const Color flatNormal = Color(0xFF8080FF);

  /// Paper: no metal (R), low gloss (G).
  static const Color paperMaterial = Color(0xFF000A00);

  /// Bare card stock, under worn paint.
  static const Color cardStock = Color(0xFFF2EEE5);

  /// The colour.png a skin without one gets: Vanilla's card.
  static const String sharedColourFile = '_shared/colour.png';

  /// The wear.png a new skin starts with: edges and corners wear first.
  static const String sharedWearFile = '_shared/wear.png';

  // The pattern placement of a skin.json without a pattern block.
  static const List<double> patternX = [0, 1], patternY = [0, 1], patternRotation = [0, 360];
  static const double patternScale = 1;

  // Text colours of a new skin.
  static const String defaultInk = '#262626', defaultBadge = '#8A8A8A', defaultNumeral = '#9E9E9E';

  /// A drag across this share of the viewport's size tilts fully.
  static const double tiltDragShare = 0.5;
  static const double resetButtonInset = 6;

  // Centre column panes: texture pane and card.
  static const double paneSplitterWidth = 8;
  static const double cardMinWidth = 340;
  static const double tabsWidthDefault = 420;
  static const double tabsWidthMin = 240;

  // Texture tabs.
  static const double tabHeight = 32;
  static const double tabMaxWidth = 210;
  static const double tabPadding = 10;
  static const double texPixelBarHeight = 44;
  static const double texZoomMin = 0.05;
  static const double texZoomMax = 64;
  static const double texWheelSensitivity = 0.003;
  static const double texNearestFrom = 1;

  /// The outline of the seed's window on a placed texture.
  static const Color windowOutlineColor = Color(0xFFFFD84A), windowOutlineShadow = Color(0xAA000000);
  static const double windowOutlineWidth = 2;

  static const String settingsFolder = '.config/fudatobashi-skin-editor';
  static const String settingsFile = 'settings.json';

  static String get settingsPath {
    final home = Platform.environment['HOME'] ?? '.';
    return '$home/$settingsFolder/$settingsFile';
  }

  static const String wearSheetFile = '_shared/wear_sheet.png';
  static const String skinFileName = 'skin.json';
  static const String imageSuffix = '.png';

  // Skin names live in the project's l10n files, one flat key per skin.
  static const String l10nFolder = 'assets/l10n';
  static const List<String> l10nLanguages = ['en', 'ja'];
  static const String skinNamePrefix = 'skinName_';
  static final RegExp skinKeyPattern = RegExp(r'^[a-z][a-z0-9_]*$');
  static const String trashCommand = 'gio';
  static const List<String> trashArguments = ['trash'];
  static const Duration l10nReloadDebounce = Duration(milliseconds: 250);

  // Window.
  static const Color windowColor = Color(0xFF1B1C20);
  static const Color panelColor = Color(0xFF24262B);
  static const Color labelColor = Color(0xFFD7D9DE);
  static const double panelGap = 12;
  static const double leftColumnWidth = 310;
  static const double rightColumnWidth = 400;
  static const double scrollbarGutter = 12;
  static const double cornersHeight = 300;
  static const double skinsListMaxHeight = 330;
  static const double familyIndent = 14;
  static const double dialogWidth = 420;
  static const double dialogLabelWidth = 80;
  static const String newSkinTier = 'blue';
  static const double shortcutKeysWidth = 170;
  static const double shortcutsSheetWidth = 520;
  static const double toolIconSize = 18;
  static const double statusLineHeight = 28;
  static const double viewBarHeight = 48;
  static const double sliderMaxRange = 1000;
  static const double numberBoxWidth = 76;
  static const double hexBoxWidth = 96;
  static const double tierDotSize = 10;
  static const double tierStripWidth = 4;
  static const Color accentColor = Color(0xFF7AA2F7);
  static const Color errorColor = Color(0xFFE5736B);
  static const Color okColor = Color(0xFF7FD18B);
  static const Color mutedColor = Color(0xFF8D909A);
  static const Color unsavedColor = Color(0xFFF0B45A);

  static const Color cornerLabelBackground = Color(0xB3000000);

  static const Map<String, Color> tierColors = {
    'blue': Color(0xFF4F8DE8),
    'purple': Color(0xFF9B6BE0),
    'pink': Color(0xFFE87FB5),
    'red': Color(0xFFE5534B),
    'gold': Color(0xFFE6B94A),
  };
  static const double labelFontSize = 12;
  static const double statusFontSize = 13;
  static const double panelHeaderHeight = 28;
  static const double panelTitleFontSize = 14;
  static const Color panelBorderColor = Color(0xFF34373E);
  static const Color chipSelectedColor = Color(0xFF33405E);

  // Thumbnails of skins and shaders, drawn off screen.
  static const int thumbRenderWidth = 112;
  static const int thumbRenderHeight = 157;
  static const double skinThumbWidth = 34;
  static const double skinRowExtent = 54;
  static const double familyHeaderHeight = 28;
  static const Duration thumbStep = Duration(milliseconds: 60);
  static const Duration thumbRefreshInterval = Duration(milliseconds: 800);
  static const int thumbSeed = 17;
  static const double thumbWear = 0.12;

  /// Thumbnails of skins that are not open read their images at most this wide.
  static const int thumbTextureWidth = 512;

  /// Shortcuts the help sheet lists: keys, then what they do.
  static const List<(String, String)> shortcuts = [
    ('Ctrl+S', 'Save the open skin'),
    ('Ctrl+Z', 'Undo'),
    ('Ctrl+Shift+Z, Ctrl+Y', 'Redo'),
    ('Hold \\', 'Show the saved version of the skin'),
    ('Drag on the card', 'Tilt the card'),
    ('Double-click the card', 'Reset the tilt'),
    ('Ctrl+W', 'Close the open texture tab'),
    ('Right-click a skin', 'Open its menu: new, duplicate, rename, delete'),
    ('F1', 'Show this list'),
  ];

  // Texture slots.
  static const double thumbSize = 36;
  static const double checkerSquare = 6;
  static const Color checkerLight = Color(0xFF5A5D66), checkerDark = Color(0xFF42454D);
  static const List<String> imageExtensions = ['png', 'jpg', 'jpeg', 'webp'];

  // Light dial.
  static const double lightDialSize = 96;
  static const double lightDotRadius = 6;
  static const double lightDialPad = 8;
  static const double chipHeight = 26;
  static const double chipGap = 6;

  // Corners.
  static const List<int> cornerZooms = [2, 4, 8];
  static const int cornerZoomDefault = 4;
  static const double zoomChipWidth = 40;

  /// Screen pixels shown outside the card edge in each corner cell.
  static const double cornerMargin = 14;

  // Preview bar.
  static const double wearTrackHeight = 8;
  static const double wearSliderHeight = 30;
  static const double wearSliderWidth = 340;
  static const double wearThumbRadius = 7;
  static const double wearReadoutWidth = 200;
  static const double wearOutsideDim = 0.28;
  static const List<WearBand> wearBands = [
    WearBand('Mint', 0.07, Color(0xFF8ED462)),
    WearBand('Fine', 0.15, Color(0xFFBCE08A)),
    WearBand('Played', 0.38, Color(0xFFFFD83A)),
    WearBand('Worn', 0.45, Color(0xFFFF9A2E)),
    WearBand('Well-loved', 1.0, Color(0xFFE0604A)),
  ];

  // Status bar.
  static const Duration statusLifetime = Duration(seconds: 4);
  static const Duration statusFade = Duration(milliseconds: 400);

  // Properties panel.
  static const double formLabelWidth = 128;
  static const double formRowHeight = 28;
  static const double formRowGap = 1;
  static const double formNumberWidth = 58;
  static const double formNumberWidthSuffix = 84;
  static const double numberCharWidth = 8, numberBoxPadding = 20, numberSuffixWidth = 26;
  static const double formSwatchSize = 22;
  static const double formSliderTrack = 2;
  static const double formSliderThumb = 6;
  static const double sectionHeaderHeight = 30;
  static const double smallFontSize = 11;
  static const double wheelStep = 84;
  static const double wheelNotchThreshold = 10;
  static const Duration undoMergeWindow = Duration(milliseconds: 900);
  static const int undoLimit = 200;
  static const Color warningColor = Color(0xFFF0B45A);

  /// Light presets, in the order the UI lists them. Azimuth is in degrees,
  /// 0 from the right and 90 from the top; elevation is degrees above the card.
  static const List<LightSpec> lightSpecs = [
    LightSpec('Studio', 135, 55, Color(0xFFFFFFFF), 1.0, 0.25),
    LightSpec('Daylight', 100, 70, Color(0xFFE6EEFF), 1.2, 0.40),
    LightSpec('Warm lamp', 20, 35, Color(0xFFFFA957), 0.9, 0.12),
    LightSpec('Dark room', 90, 60, Color(0xFFFFFFFF), 0.15, 0.03),
    LightSpec('Grazing', 180, 8, Color(0xFFFFFFFF), 1.0, 0.05),
  ];
}

class WearBand {
  const WearBand(this.name, this.upTo, this.color);

  /// The band covers wear values below [upTo] (and at or above the previous band's).
  final String name;
  final double upTo;
  final Color color;
}

class LightSpec {
  const LightSpec(this.name, this.azimuth, this.elevation, this.color, this.intensity, this.ambient);
  final String name;
  final double azimuth, elevation, intensity, ambient;
  final Color color;
}

/// The torifuda card, ported from the app's TorifudaSpec (card units).
abstract final class Torifuda {
  static const double fontSize = 78.0;

  /// Centre of each column's first cell, right to left.
  static const List<Offset> columnTop = [Offset(289.53, 81.64), Offset(188.64, 81.88), Offset(91.23, 81.73)];
  static const double rowPitch = 89.63;

  /// A column with more than five kana (only #21 has six) is spread evenly
  /// between these row centres.
  static const double longColumnFirstRowCenterY = 75.03;
  static const double longColumnLastRowCenterY = 440.08;

  static Offset cellCenter(int column, int row, int columnLength) => Offset(
        columnTop[column].dx,
        columnLength <= 5
            ? columnTop[column].dy + row * rowPitch
            : longColumnFirstRowCenterY +
                row * (longColumnLastRowCenterY - longColumnFirstRowCenterY) / (columnLength - 1),
      );

  /// Where the poem-number badge sits unless skin.json has `badge`.
  static const Offset defaultBadgeCenter = Offset(44.3, 480.26);
  static const double badgeRadius = 16.54;
  static const double badgeStroke = 1.08;
  static const String badgeFontFamily = 'TorifudaNumber';
  static const double badgeFontSize = 20.6;
  static const double badgeFontSizeThreeDigits = 15.7;

  /// Numeral baseline below the badge centre, as a fraction of the font size.
  static const double badgeBaselineDy = 0.34;

  /// Per-kana correction: shift of the glyph's em box from the cell centre
  /// (in em) and a scale.
  static const Map<String, ({double dx, double dy, double scale})> glyphFit = {
    'あ': (dx: 0.0045, dy: 0.0093, scale: 1.0026), 'い': (dx: -0.0047, dy: 0.0165, scale: 1.0069),
    'う': (dx: 0.0091, dy: -0.0079, scale: 0.9732), 'え': (dx: -0.0005, dy: 0.0054, scale: 1.0038),
    'お': (dx: -0.0032, dy: 0.0021, scale: 0.9983), 'か': (dx: -0.0134, dy: -0.0033, scale: 1.0040),
    'き': (dx: -0.0086, dy: 0.0055, scale: 0.9961), 'く': (dx: 0.0071, dy: -0.0002, scale: 0.9660),
    'け': (dx: 0.0031, dy: 0.0127, scale: 0.9801), 'こ': (dx: 0.0039, dy: 0.0025, scale: 0.9996),
    'さ': (dx: -0.0002, dy: 0.0022, scale: 1.0034), 'し': (dx: 0.0188, dy: -0.0010, scale: 1.0064),
    'す': (dx: 0.0189, dy: 0.0065, scale: 1.0026), 'せ': (dx: -0.0041, dy: -0.0059, scale: 1.0014),
    'そ': (dx: -0.0171, dy: 0.0012, scale: 1.0115), 'た': (dx: -0.0032, dy: 0.0001, scale: 0.9979),
    'ち': (dx: 0.0168, dy: -0.0014, scale: 1.0077), 'つ': (dx: 0.0023, dy: -0.0056, scale: 0.9964),
    'て': (dx: -0.0091, dy: 0.0064, scale: 1.0378), 'と': (dx: 0.0072, dy: 0.0029, scale: 1.0056),
    'な': (dx: 0.0115, dy: -0.0014, scale: 0.9899), 'に': (dx: 0.0122, dy: -0.0105, scale: 1.0014),
    'ぬ': (dx: -0.0026, dy: -0.0101, scale: 0.9998), 'ね': (dx: -0.0054, dy: 0.0002, scale: 1.0025),
    'の': (dx: -0.0072, dy: 0.0043, scale: 1.0036), 'は': (dx: 0.0062, dy: 0.0048, scale: 0.9805),
    'ひ': (dx: -0.0141, dy: -0.0102, scale: 1.0006), 'ふ': (dx: -0.0068, dy: -0.0111, scale: 0.9966),
    'へ': (dx: -0.0033, dy: 0.0053, scale: 1.0129), 'ほ': (dx: 0.0018, dy: 0.0052, scale: 0.9826),
    'ま': (dx: -0.0057, dy: 0.0004, scale: 0.9928), 'み': (dx: 0.0081, dy: -0.0155, scale: 0.9925),
    'む': (dx: 0.0137, dy: -0.0058, scale: 1.0012), 'め': (dx: 0.0040, dy: 0.0204, scale: 1.0052),
    'も': (dx: 0.0073, dy: -0.0015, scale: 0.9974), 'や': (dx: -0.0072, dy: 0.0059, scale: 1.0035),
    'ゆ': (dx: -0.0006, dy: -0.0041, scale: 0.9987), 'よ': (dx: 0.0030, dy: -0.0067, scale: 1.0007),
    'ら': (dx: -0.0178, dy: 0.0066, scale: 0.9887), 'り': (dx: -0.0024, dy: 0.0030, scale: 0.9964),
    'る': (dx: -0.0147, dy: 0.0061, scale: 1.0011), 'れ': (dx: -0.0159, dy: -0.0049, scale: 1.0098),
    'ろ': (dx: -0.0068, dy: -0.0040, scale: 0.9996), 'わ': (dx: 0.0022, dy: -0.0185, scale: 1.0043),
    'ゐ': (dx: -0.0037, dy: -0.0112, scale: 0.9991), 'ゑ': (dx: -0.0146, dy: -0.0019, scale: 1.0068),
    'を': (dx: 0.0105, dy: 0.0010, scale: 1.0002),
  };
}
