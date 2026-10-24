import 'dart:convert';

import 'package:flutter/services.dart';

/// Where a card sits on its island (a tree, flag or speed dot).
class IslandSite {
  const IslandSite(this.poemId, this.at);
  final int poemId;
  final Offset at;
}

/// One kana island: the coastline of an initial-kana group, in map units.
class IslandShape {
  const IslandShape({
    required this.index,
    required this.name,
    required this.pathData,
    required this.center,
    required this.bounds,
    required this.label,
    required this.dotRadius,
    required this.sites,
    this.scale = 1,
    this.shift = Offset.zero,
  });

  final int index;

  /// The initial-kana group, as in `initialGroups`.
  final String name;

  /// SVG path data of the coastline.
  final String pathData;
  final Offset center;
  final Rect bounds;

  /// Centre of the name plate.
  final Offset label;

  /// Radius of a card dot on this island.
  final double dotRadius;
  final List<IslandSite> sites;

  /// How [pathData] lies on the chart: [scale] times its size, then moved
  /// by [shift]. The other geometry is in chart units already.
  final double scale;
  final Offset shift;

  /// This island's coast [scale] times its size, centred on [at], as island
  /// [index] of another chart (a class of the rank ladder), with its plate
  /// at [label].
  IslandShape placed(int index, Offset at, double scale, {required Offset label}) {
    Offset map(Offset p) => at + (p - center) * scale;
    return IslandShape(
      index: index,
      name: name,
      pathData: pathData,
      center: at,
      bounds: Rect.fromPoints(map(bounds.topLeft), map(bounds.bottomRight)),
      label: label,
      dotRadius: dotRadius * scale,
      sites: [for (final s in sites) IslandSite(s.poemId, map(s.at))],
      scale: this.scale * scale,
      shift: map(shift),
    );
  }

  factory IslandShape.fromJson(int index, Map<String, dynamic> j) {
    Offset pt(List v) => Offset((v[0] as num).toDouble(), (v[1] as num).toDouble());
    final b = (j['bounds'] as List).cast<num>();
    return IslandShape(
      index: index,
      name: j['name'] as String,
      pathData: j['path'] as String,
      center: pt(j['center'] as List),
      bounds: Rect.fromLTRB(b[0].toDouble(), b[1].toDouble(), b[2].toDouble(), b[3].toDouble()),
      label: pt(j['label'] as List),
      dotRadius: (j['dotRadius'] as num).toDouble(),
      sites: [
        for (final c in j['cards'] as List) IslandSite(c['id'] as int, pt(c['site'] as List)),
      ],
    );
  }
}

/// The eleven kana islands (かな諸島), in learning order. Geometry comes from
/// the design spec via `assets/data/islands.json`.
class Archipelago {
  Archipelago(this.size, this.islands);

  final Size size;
  final List<IslandShape> islands;

  static Archipelago fromJsonString(String s) {
    final j = jsonDecode(s) as Map<String, dynamic>;
    return Archipelago(
      Size((j['width'] as num).toDouble(), (j['height'] as num).toDouble()),
      [for (final (i, e) in (j['islands'] as List).indexed) IslandShape.fromJson(i, e as Map<String, dynamic>)],
    );
  }

  static Future<Archipelago> load() async =>
      fromJsonString(await rootBundle.loadString('assets/data/islands.json'));
}

/// Loaded once at startup in `main`.
late final Archipelago archipelago;
