// The screens widget tests lay out on, and renders of what a test shows.
//
// With RENDER_SCREENS=1, captureScreen writes PNGs to build/screens/, named
// <screen>_<lang>[_<variant>].<W>x<H>.png, where <W>x<H> is the PNG's size in
// pixels and a text scale other than 1 ends the variant (t13 for 1.3):
//
//   RENDER_SCREENS=1 flutter test                     on each test's phone
//   RENDER_SCREENS=1 SCREEN_SIZES=ipad flutter test   on the 13" iPad, portrait and landscape
//
// For the iPad, a test still runs on its phone, and at each render its screen
// is laid out again at the iPad's size, as an iPad does when it turns, then
// turned back. Layout errors on the iPad are printed, not failed.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// A device's screen: its size and system bars in dp, and its pixels per dp.
/// Its [name] tells screens apart in test names.
class Screen {
  const Screen(this.name, this.size, this.dpr, {this.bars = _phoneBars});

  final String name;
  final Size size;
  final double dpr;
  final EdgeInsets bars;
}

/// A 28 dp status bar and a 48 dp navigation bar.
const _phoneBars = EdgeInsets.only(top: 28, bottom: 48);

/// The iPad's status bar and home indicator.
const _ipadBars = EdgeInsets.only(top: 24, bottom: 20);

/// The user's phone, 1080 × 2340 px.
const usersPhone = Screen('384', Size(384, 832), 2.8125);

/// The user's phone turned sideways, its bars at the sides.
const usersPhoneLandscape = Screen('384 landscape', Size(832, 384), 2.8125, bars: EdgeInsets.only(left: 28, right: 48));

/// As many pixels as the user's phone at a higher density, so fewer dp.
const narrowPhone = Screen('360', Size(360, 780), 3);

/// As many pixels as the user's phone at a lower density, so more dp.
const widePhone = Screen('412', Size(1080 / 2.625, 2340 / 2.625), 2.625);

/// As narrow as [narrowPhone] and as tall as the user's.
const narrowTallPhone = Screen('360', Size(360, 832), 2.8125);

/// As narrow as [narrowPhone] and shorter.
const shortNarrowPhone = Screen('360', Size(360, 740), 2.8125);

/// The 13" iPad, portrait and landscape, at Apple's screenshot size of
/// 2064 × 2752 px.
const ipadPortrait = Screen('iPad 13"', Size(1032, 1376), 2, bars: _ipadBars);
const ipadLandscape = Screen('iPad 13" landscape', Size(1376, 1032), 2, bars: _ipadBars);

/// The key of the [RepaintBoundary] around what a test shows.
const screenKey = ValueKey('screen');

/// Whether tests write renders.
final renderScreens = Platform.environment['RENDER_SCREENS'] == '1';

final _sizes = Platform.environment['SCREEN_SIZES'] ?? 'phone';

/// The system's monospaced faces that renders of the developer pages use for
/// their `monospace` text, regular then bold, the first found.
const _monoFaces = [
  ['/usr/share/fonts/TTF/DejaVuSansMono.ttf', '/usr/share/fonts/TTF/DejaVuSansMono-Bold.ttf'],
  ['/usr/share/fonts/liberation/LiberationMono-Regular.ttf', '/usr/share/fonts/liberation/LiberationMono-Bold.ttf'],
];

/// Loads a monospaced system face as `monospace` for renders, which the
/// app gets from the phone. Without renders, or with none of [_monoFaces]
/// installed, the test font stays.
Future<void> loadRenderMonoFont() async {
  if (!renderScreens) return;
  final faces = _monoFaces.where((f) => f.every((path) => File(path).existsSync())).firstOrNull;
  if (faces == null) return;
  final loader = FontLoader('monospace');
  for (final path in faces) {
    loader.addFont(Future.value(ByteData.sublistView(File(path).readAsBytesSync())));
  }
  await loader.load();
}

/// Each iPad render written so far, so a test looping over phones renders
/// each iPad screen once.
final _ipadRenders = <String>{};

/// Lays the test out on [screen] at [fontScale] until it ends.
void useScreen(WidgetTester tester, Screen screen, {double fontScale = 1}) {
  _setView(tester, screen);
  tester.platformDispatcher.textScaleFactorTestValue = fontScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

void _setView(WidgetTester tester, Screen screen) {
  final bars = screen.bars * screen.dpr;
  final padding = FakeViewPadding(left: bars.left, top: bars.top, right: bars.right, bottom: bars.bottom);
  tester.view
    ..devicePixelRatio = screen.dpr
    ..physicalSize = screen.size * screen.dpr
    ..padding = padding
    ..viewPadding = padding;
}

/// Renders what is under [screenKey] as [screen] in [lang]: on the test's
/// own screen at 2 px per dp, or with SCREEN_SIZES=ipad on the iPad.
/// [screen] may start with a folder, as in `cards/browser`.
Future<void> captureScreen(WidgetTester tester, String screen, {String lang = 'en', String? variant}) async {
  if (!renderScreens) return;
  if (!const {'phone', 'ipad'}.contains(_sizes)) fail('SCREEN_SIZES is phone or ipad, not $_sizes');
  final scale = tester.platformDispatcher.textScaleFactor;
  final name = [screen, lang, ?variant, if (scale != 1) 't${'$scale'.replaceAll('.', '')}'].join('_');
  if (_sizes == 'phone') return _write(tester, name, 2);
  for (final ipad in [ipadPortrait, ipadLandscape]) {
    if (_ipadRenders.add('$name ${ipad.name}')) await _onIpad(tester, ipad, name);
  }
}

Future<void> _write(WidgetTester tester, String name, double pixelRatio) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(screenKey));
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    File('build/screens/$name.${image.width}x${image.height}.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(png!.buffer.asUint8List());
  });
}

/// Writes [name] laid out on [ipad], then lays the test's screen out again
/// as it was, scrolled where it was. A lazy list laid out again partway down
/// keeps wrong offsets for the items above, so each vertical list goes back
/// to its top before the phone returns, then down to where it was.
Future<void> _onIpad(WidgetTester tester, Screen ipad, String name) async {
  final view = tester.view;
  final (dpr, size, padding, viewPadding) = (view.devicePixelRatio, view.physicalSize, view.padding, view.viewPadding);
  final surface = tester.binding.renderViews.first.size;
  final scrolled = {
    for (final s in tester.stateList<ScrollableState>(find.byType(Scrollable, skipOffstage: false)))
      if (s.position case final p when p.hasPixels && p.hasContentDimensions) s: p.pixels
  };
  final resting = [for (final s in scrolled.keys) if (!s.position.isScrollingNotifier.value) s];
  addTearDown(view.reset);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final errors = <FlutterErrorDetails>[];
  final onError = FlutterError.onError;
  FlutterError.onError = errors.add;
  try {
    _setView(tester, ipad);
    await tester.binding.setSurfaceSize(ipad.size);
    await tester.pump();
    await _settleScrolls(tester, resting);
    await _write(tester, name, ipad.dpr);
    for (final s in scrolled.keys) {
      if (s.mounted && s.position.axis == Axis.vertical && s.position.pixels != 0) s.position.jumpTo(0);
    }
    await tester.pump();

    view
      ..devicePixelRatio = dpr
      ..physicalSize = size
      ..padding = padding
      ..viewPadding = viewPadding;
    await tester.binding.setSurfaceSize(surface);
    await tester.pump();
    for (final MapEntry(key: s, value: pixels) in scrolled.entries) {
      if (s.mounted && s.position.pixels != pixels) s.position.jumpTo(pixels);
    }
    await tester.pump();
  } finally {
    FlutterError.onError = onError;
  }
  for (final e in errors) {
    debugPrint('${ipad.name} layout error in $name: ${e.exceptionAsString().split('\n').first}');
  }
}

/// Plays out the scroll moves that a new size starts in [resting], such as
/// Home's map panning to the boat.
Future<void> _settleScrolls(WidgetTester tester, Iterable<ScrollableState> resting) async {
  bool moving() => resting.any((s) => s.mounted && s.position.isScrollingNotifier.value);
  await tester.pump();
  for (var i = 0; i < 100 && moving(); i++) {
    await tester.pump(const Duration(milliseconds: 20));
  }
}
