import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

enum TexChannel { rgb, r, g, b, a }

/// How one texture is shown.
class TabView {
  TexChannel channel = TexChannel.rgb;

  /// While true the image is fitted to the pane and [scale] and [offset] are ignored.
  bool fitted = true;
  double scale = 1;
  Offset offset = Offset.zero;
}

/// The texture pane: whether it is shown, and which texture it shows. It has one tab for every texture
/// the shader declares. Notifies only when this changes; zoom and pan live in [TabView].
class TextureTabs extends ChangeNotifier {
  final Map<String, TabView> _views = {};
  bool visible = false;
  String? active;

  TabView view(String slot) => _views.putIfAbsent(slot, TabView.new);

  void open(String slot) {
    visible = true;
    active = slot;
    notifyListeners();
  }

  void activate(String slot) {
    if (active == slot) return;
    active = slot;
    notifyListeners();
  }

  void hide() {
    if (!visible) return;
    visible = false;
    notifyListeners();
  }
}
