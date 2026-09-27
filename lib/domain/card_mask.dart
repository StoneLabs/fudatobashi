/// How hidden kana are drawn in 隠し字 mode.
enum MaskStyle {
  /// The kana's own glyph cut into 3×3 tiles, shuffled and rotated:
  /// identical ink and brush texture, unreadable.
  scramble,

  /// A procedural brush shape whose stroke width matches the kana's ink.
  shape,

  /// Nothing drawn.
  blank,
}

/// Which kana of a torifuda are hidden. Indices refer to positions in
/// `Poem.torifuda` (reading order: right column top→bottom, then middle, left).
class CardMask {
  const CardMask({required this.hidden, this.style = MaskStyle.scramble, this.seed = 0});

  static const none = CardMask(hidden: {});

  final Set<int> hidden;
  final MaskStyle style;
  final int seed;

  bool get isNone => hidden.isEmpty;

  String get key {
    if (hidden.isEmpty) return '-';
    final idx = hidden.toList()..sort();
    return '${style.index}:$seed:${idx.join(',')}';
  }
}
