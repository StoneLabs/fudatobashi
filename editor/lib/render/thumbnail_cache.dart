import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../config.dart';
import 'skin_scene.dart';

/// Draws [scene] once into a small image of the whole card.
ui.Image renderThumbnail(SkinScene scene) =>
    renderScene(scene, const ui.Rect.fromLTWH(0, 0, Cfg.cardWidth, Cfg.cardHeight), Cfg.thumbRenderWidth, Cfg.thumbRenderHeight);

typedef ThumbnailJob = Future<ui.Image?> Function();

class _Item {
  ui.Image? image;
  String? signature;
  DateTime renderedAt = DateTime.fromMillisecondsSinceEpoch(0);
}

class _Request {
  _Request(this.signature, this.job);
  final String signature;
  final ThumbnailJob job;
}

/// Small rendered images by key. A request only renders when its signature
/// differs from the one drawn last. The jobs run one at a time, a short pause apart,
/// and one key is redrawn at most once per refresh interval.
class ThumbnailCache extends ChangeNotifier {
  final Map<String, _Item> _items = {};
  final Map<String, _Request> _pending = {};
  Timer? _timer;
  bool _running = false;

  ui.Image? image(String key) => _items[key]?.image;

  void request(String key, String signature, ThumbnailJob job) {
    if (_items[key]?.signature == signature || _pending[key]?.signature == signature) return;
    _pending[key] = _Request(signature, job);
    _schedule();
  }

  void _schedule() {
    if (_timer?.isActive ?? false) return;
    _timer = Timer(Cfg.thumbStep, _step);
  }

  Future<void> _step() async {
    if (_running) return;
    final now = DateTime.now();
    final key = _pending.keys.where((k) {
      final item = _items[k];
      return item?.image == null || now.difference(item!.renderedAt) >= Cfg.thumbRefreshInterval;
    }).firstOrNull;
    if (key != null) {
      final request = _pending.remove(key)!;
      _running = true;
      try {
        final image = await request.job();
        if (image != null) _store(key, request.signature, image);
      } catch (_) {
        // A skin that cannot be drawn keeps its old image.
      }
      _running = false;
    }
    if (_pending.isNotEmpty) _schedule();
  }

  void _store(String key, String signature, ui.Image image) {
    final item = _items.putIfAbsent(key, _Item.new);
    item
      ..image = image
      ..signature = signature
      ..renderedAt = DateTime.now();
    notifyListeners();
  }

  /// Draws [key] again at its next request, for example after one of its files changed.
  void forget(String key) => _items[key]?.signature = null;

  /// Forgets every image, for example when another folder is opened.
  void clear() {
    _pending.clear();
    _items.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

/// Paints a cached thumbnail, or an empty box until it exists.
class ThumbnailImage extends StatelessWidget {
  const ThumbnailImage({super.key, required this.cache, required this.cacheKey, required this.width});

  final ThumbnailCache cache;
  final String cacheKey;
  final double width;

  @override
  Widget build(BuildContext context) {
    final height = width * Cfg.cardHeight / Cfg.cardWidth;
    return SizedBox(
      width: width,
      height: height,
      child: ListenableBuilder(
        listenable: cache,
        builder: (context, _) {
          final image = cache.image(cacheKey);
          return image == null
              ? const ColoredBox(color: Cfg.windowColor)
              : RawImage(image: image, fit: BoxFit.fill, filterQuality: FilterQuality.medium);
        },
      ),
    );
  }
}
