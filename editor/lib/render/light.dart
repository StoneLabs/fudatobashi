import 'dart:math' as math;
import 'dart:ui';

import '../config.dart';

/// A single light on the card.
class Light {
  const Light({
    required this.azimuth,
    required this.elevation,
    required this.color,
    required this.intensity,
    required this.ambient,
  });

  /// Degrees. 0 is from the right, 90 from the top.
  final double azimuth;

  /// Degrees above the card.
  final double elevation;
  final Color color;
  final double intensity, ambient;

  Light copyWith({double? azimuth, double? elevation, Color? color, double? intensity, double? ambient}) => Light(
        azimuth: azimuth ?? this.azimuth,
        elevation: elevation ?? this.elevation,
        color: color ?? this.color,
        intensity: intensity ?? this.intensity,
        ambient: ambient ?? this.ambient,
      );

  /// Unit vector from the card towards the light: x right, y down the card,
  /// z towards the viewer (the shader's card space).
  (double, double, double) get direction {
    final az = azimuth * math.pi / 180, el = elevation * math.pi / 180;
    return (math.cos(el) * math.cos(az), -math.cos(el) * math.sin(az), math.sin(el));
  }

  @override
  bool operator ==(Object other) =>
      other is Light &&
      other.azimuth == azimuth &&
      other.elevation == elevation &&
      other.color == color &&
      other.intensity == intensity &&
      other.ambient == ambient;

  @override
  int get hashCode => Object.hash(azimuth, elevation, color, intensity, ambient);
}

class LightPreset {
  const LightPreset(this.name, this.light);
  final String name;
  final Light light;
}

final List<LightPreset> lightPresets = [
  for (final s in Cfg.lightSpecs)
    LightPreset(
      s.name,
      Light(azimuth: s.azimuth, elevation: s.elevation, color: s.color, intensity: s.intensity, ambient: s.ambient),
    ),
];
