import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config.dart';
import '../io/editor_controller.dart';
import '../io/skin_textures.dart';
import '../io/texture_tabs.dart';
import '../model/skin.dart';
import 'texture_actions.dart';
import 'widgets.dart';

/// The pane left of the card: one tab per image slot of the skin. Each image is
/// shown as it is in its file.
class TexturePane extends StatefulWidget {
  const TexturePane({super.key, required this.controller});

  final EditorController controller;

  @override
  State<TexturePane> createState() => _TexturePaneState();
}

class _TexturePaneState extends State<TexturePane> {
  final _focus = FocusNode();

  EditorController get _c => widget.controller;

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  KeyEventResult _key(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.keyW && HardwareKeyboard.instance.isControlPressed) {
      _c.tabs.hide();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final names = [..._c.textures.states.keys];
    final active = names.contains(_c.tabs.active) ? _c.tabs.active! : names.first;
    return Focus(
      focusNode: _focus,
      onKeyEvent: _key,
      child: Listener(
        onPointerDown: (_) => _focus.requestFocus(),
        child: Container(
          color: Cfg.panelColor,
          child: Column(children: [
            _TabStrip(controller: _c, names: names, active: active),
            Expanded(
              child: _SlotTab(key: ValueKey('${_c.selected}/$active'), controller: _c, state: _c.textures.states[active]!),
            ),
          ]),
        ),
      ),
    );
  }
}

class _TabStrip extends StatelessWidget {
  const _TabStrip({required this.controller, required this.names, required this.active});

  final EditorController controller;
  final List<String> names;
  final String active;

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(
        child: Wrap(children: [
          for (final name in names)
            _Tab(
              title: controller.textures.states[name]!.slot.label,
              selected: name == active,
              onSelect: () => controller.tabs.activate(name),
            ),
        ]),
      ),
      IconButton(
        icon: const Icon(Icons.close, size: Cfg.toolIconSize),
        tooltip: 'Close the texture pane (Ctrl+W)',
        visualDensity: VisualDensity.compact,
        onPressed: controller.tabs.hide,
      ),
    ]);
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.title, required this.selected, required this.onSelect});

  final String title;
  final bool selected;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onSelect,
      child: Container(
        height: Cfg.tabHeight,
        constraints: const BoxConstraints(maxWidth: Cfg.tabMaxWidth),
        padding: const EdgeInsets.symmetric(horizontal: Cfg.tabPadding),
        decoration: BoxDecoration(
          color: selected ? Cfg.windowColor : null,
          border: Border(bottom: BorderSide(width: 2, color: selected ? Cfg.accentColor : Colors.transparent)),
        ),
        child: Center(
          widthFactor: 1,
          child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: Cfg.labelFontSize, fontWeight: FontWeight.bold, color: selected ? Cfg.labelColor : Cfg.mutedColor)),
        ),
      ),
    );
  }
}

/// What the slot is for, which file it reads, and the buttons to change it.
class _SlotTab extends StatefulWidget {
  const _SlotTab({super.key, required this.controller, required this.state});

  final EditorController controller;
  final SlotState state;

  @override
  State<_SlotTab> createState() => _SlotTabState();
}

class _SlotTabState extends State<_SlotTab> {
  final _path = TextEditingController();

  EditorController get _c => widget.controller;
  Slot get _slot => widget.state.slot;

  @override
  void dispose() {
    _path.dispose();
    super.dispose();
  }

  /// The seed's window on the pattern sheet, as corners in image pixels.
  List<Offset>? _outline(ui.Image image) {
    if (!_slot.placed) return null;
    final window = _c.scene?.draws.placements[patternKey];
    if (window == null) return null;
    final m = window.matrix, ratio = Cfg.cardHeight / Cfg.cardWidth;
    Offset corner(double u, double v) => Offset((m[0] * u + m[3] * v + m[6]) * image.width, (m[1] * u + m[4] * v + m[7]) * image.height);
    return [corner(0, 0), corner(1, 0), corner(1, ratio), corner(0, ratio)];
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final slot = _slot;
    const muted = TextStyle(fontSize: Cfg.labelFontSize, color: Cfg.mutedColor);
    final own = state.source == SlotSource.own;
    final using = switch (state.source) {
      SlotSource.own => 'Using ${state.ownFile.path}',
      SlotSource.shared => 'No ${slot.fileName} in the skin folder. Using ${slot.defaultNote}.',
      SlotSource.flat => 'No ${slot.fileName} in the skin folder. The shader gets ${slot.defaultNote}.',
    };
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(slot.fileName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: Cfg.labelFontSize)),
          const SizedBox(height: 2),
          Text(slot.help, style: muted),
          if (slot.placed) const Text('Read through the pattern placement. The outline shows where the card sits for this seed.', style: muted),
          Text(using, style: muted),
          if (state.error != null) Text('Could not read it: ${state.error}', style: muted.copyWith(color: Cfg.errorColor)),
          const SizedBox(height: 6),
          Wrap(spacing: 6, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
            FilledButton(onPressed: () => chooseTextureFile(context, _c, slot.name), child: const Text('Replace\u2026')),
            OutlinedButton(onPressed: own ? () => clearTextureFile(context, _c, slot.name) : null, child: const Text('Clear')),
          ]),
          const SizedBox(height: 6),
          SizedBox(
            height: Cfg.formRowHeight + 4,
            child: TextField(
              controller: _path,
              style: const TextStyle(fontSize: Cfg.labelFontSize),
              decoration: compactDecoration.copyWith(hintText: 'Or paste the full path of an image here'),
              onSubmitted: (v) => useTexturePath(context, _c, slot.name, v),
            ),
          ),
          const SizedBox(height: 4),
          OutlinedButton(onPressed: () => useTexturePath(context, _c, slot.name, _path.text), child: const Text('Use this path')),
        ]),
      ),
      Expanded(
        child: _Viewer(
          key: ValueKey('${_c.selected}/${slot.name}/view'),
          view: _c.tabs.view(slot.name),
          image: state.image,
          empty: state.loading ? 'Loading' : 'No file. The shader gets ${slot.defaultNote}.',
          outline: state.image == null ? null : _outline(state.image!),
        ),
      ),
    ]);
  }
}

/// Zoomable view of one texture with a channel switch and a pixel read-out.
class _Viewer extends StatefulWidget {
  const _Viewer({super.key, required this.view, required this.image, required this.empty, this.outline});

  final TabView view;
  final ui.Image? image;

  /// What to say when there is no image.
  final String empty;

  /// Four corners in image pixels to outline, or null.
  final List<Offset>? outline;

  @override
  State<_Viewer> createState() => _ViewerState();
}

class _ViewerState extends State<_Viewer> {
  Size _box = Size.zero;
  ui.Image? _bytesOf;
  ByteData? _bytes;
  Offset? _hover;

  TabView get _v => widget.view;
  ui.Image? get _image => widget.image;

  @override
  void initState() {
    super.initState();
    _readPixels();
  }

  @override
  void didUpdateWidget(_Viewer old) {
    super.didUpdateWidget(old);
    if (!identical(_image, _bytesOf)) _readPixels();
  }

  Future<void> _readPixels() async {
    final image = _image;
    _bytesOf = image;
    if (image == null) {
      _bytes = null;
      return;
    }
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.rawStraightRgba);
      if (mounted && identical(_bytesOf, image)) setState(() => _bytes = data);
    } catch (_) {
      // The image was replaced and disposed while it was read; the next one is read instead.
    }
  }

  ({double scale, Offset offset}) _transform(ui.Image image) {
    if (!_v.fitted) return (scale: _v.scale, offset: _v.offset);
    final scale = math.min(_box.width / image.width, _box.height / image.height);
    return (scale: scale, offset: Offset((_box.width - image.width * scale) / 2, (_box.height - image.height * scale) / 2));
  }

  void _set(double scale, Offset offset) => setState(() {
        _v.fitted = false;
        _v.scale = scale.clamp(Cfg.texZoomMin, Cfg.texZoomMax);
        _v.offset = offset;
      });

  void _oneToOne(ui.Image image) => _set(1, Offset((_box.width - image.width) / 2, (_box.height - image.height) / 2));

  void _wheel(PointerScrollEvent e, ui.Image image) {
    final t = _transform(image);
    final next = (t.scale * math.exp(-e.scrollDelta.dy * Cfg.texWheelSensitivity)).clamp(Cfg.texZoomMin, Cfg.texZoomMax);
    final at = e.localPosition;
    _set(next, at - (at - t.offset) * (next / t.scale));
  }

  @override
  Widget build(BuildContext context) {
    final image = _image;
    return Column(children: [
      _toolbar(image),
      Expanded(
        child: image == null
            ? Center(child: Padding(padding: const EdgeInsets.all(12), child: Text(widget.empty, textAlign: TextAlign.center, style: const TextStyle(color: Cfg.mutedColor))))
            : ClipRect(
                child: LayoutBuilder(builder: (context, box) {
                  _box = box.biggest;
                  final t = _transform(image);
                  return MouseRegion(
                    cursor: SystemMouseCursors.grab,
                    onHover: (e) => setState(() => _hover = e.localPosition),
                    onExit: (_) => setState(() => _hover = null),
                    child: Listener(
                      onPointerSignal: (e) {
                        if (e is PointerScrollEvent) _wheel(e, image);
                      },
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onPanUpdate: (d) => _set(t.scale, t.offset + d.delta),
                        child: CustomPaint(
                          size: box.biggest,
                          painter: _ImagePainter(image, t.scale, t.offset, _v.channel, widget.outline),
                        ),
                      ),
                    ),
                  );
                }),
              ),
      ),
      _pixelBar(image),
    ]);
  }

  Widget _toolbar(ui.Image? image) {
    const label = TextStyle(fontSize: Cfg.labelFontSize);
    final zoom = image == null ? null : _transform(image).scale;
    final button = TextButton.styleFrom(minimumSize: const Size(36, 28), padding: const EdgeInsets.symmetric(horizontal: 6));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 2,
        runSpacing: 2,
        children: [
          for (final c in TexChannel.values)
            ChoiceChip(
              label: Text(c == TexChannel.rgb ? 'RGB' : c.name.toUpperCase(), style: label),
              selected: _v.channel == c,
              showCheckmark: false,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              labelPadding: const EdgeInsets.symmetric(horizontal: 4),
              onSelected: (_) => setState(() => _v.channel = c),
            ),
          const SizedBox(width: 10),
          TextButton(style: button, onPressed: image == null ? null : () => setState(() => _v.fitted = true), child: const Text('Fit')),
          TextButton(style: button, onPressed: image == null ? null : () => _oneToOne(image), child: const Text('1:1')),
          if (image != null) ...[
            const SizedBox(width: 6),
            Text('${image.width}\u00d7${image.height}   ${(zoom! * 100).round()}%', style: label.copyWith(color: Cfg.mutedColor)),
          ],
        ],
      ),
    );
  }

  Widget _pixelBar(ui.Image? image) {
    var text = '';
    final bytes = _bytes, hover = _hover;
    if (image != null && bytes != null && hover != null) {
      final t = _transform(image);
      final x = ((hover.dx - t.offset.dx) / t.scale).floor(), y = ((hover.dy - t.offset.dy) / t.scale).floor();
      if (x >= 0 && y >= 0 && x < image.width && y < image.height && bytes.lengthInBytes >= (y * image.width + x) * 4 + 4) {
        final i = (y * image.width + x) * 4;
        final px = [for (var k = 0; k < 4; k++) bytes.getUint8(i + k)];
        final hex = px.map((v) => v.toRadixString(16).padLeft(2, '0')).join().toUpperCase();
        text = 'x $x  y $y\nR ${px[0]}  G ${px[1]}  B ${px[2]}  A ${px[3]}   #$hex';
      }
    }
    return Container(
      height: Cfg.texPixelBarHeight,
      width: double.infinity,
      color: Cfg.windowColor,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.centerLeft,
      child: Text(text.isEmpty ? 'Move over the image to read a pixel' : text,
          maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: Cfg.labelFontSize, fontFamily: 'monospace', color: text.isEmpty ? Cfg.mutedColor : Cfg.labelColor)),
    );
  }
}

class _ImagePainter extends CustomPainter {
  _ImagePainter(this.image, this.scale, this.offset, this.channel, this.outline);

  final List<Offset>? outline;
  final ui.Image image;
  final double scale;
  final Offset offset;
  final TexChannel channel;

  static ColorFilter? _filter(TexChannel c) {
    List<double> grey(int row) => [
          for (var r = 0; r < 3; r++) ...[for (var k = 0; k < 4; k++) k == row ? 1 : 0, 0],
          0, 0, 0, 0, 255,
        ];
    return switch (c) {
      TexChannel.rgb => null,
      TexChannel.r => ColorFilter.matrix(grey(0)),
      TexChannel.g => ColorFilter.matrix(grey(1)),
      TexChannel.b => ColorFilter.matrix(grey(2)),
      TexChannel.a => ColorFilter.matrix(grey(3)),
    };
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Cfg.windowColor);
    final dst = offset & Size(image.width * scale, image.height * scale);
    canvas.save();
    canvas.clipRect(dst.intersect(Offset.zero & size));
    canvas.translate(dst.left, dst.top);
    const CheckerPainter().paint(canvas, dst.size);
    canvas.translate(-dst.left, -dst.top);
    canvas.restore();
    final paint = Paint()
      ..filterQuality = scale >= Cfg.texNearestFrom ? FilterQuality.none : FilterQuality.medium
      ..colorFilter = _filter(channel);
    canvas.drawImageRect(image, Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()), dst, paint);
    final corners = outline;
    if (corners != null) {
      final path = Path()..addPolygon([for (final c in corners) offset + c * scale], true);
      canvas.drawPath(path, Paint()..color = Cfg.windowOutlineShadow..style = PaintingStyle.stroke..strokeWidth = Cfg.windowOutlineWidth + 2);
      canvas.drawPath(path, Paint()..color = Cfg.windowOutlineColor..style = PaintingStyle.stroke..strokeWidth = Cfg.windowOutlineWidth);
    }
  }

  @override
  bool shouldRepaint(_ImagePainter old) => true;
}
