import 'dart:ui';

/// A point in a stroke with position and pressure information.
class StrokePoint {
  /// The position of the point
  final Offset position;

  /// The value is provided directly from the OS/device.
  /// Refer to [pressureMin] and [pressureMax] for the range of possible pressure values.
  ///
  /// See also [PointerEvent.pressure] for more details.
  final double pressure;

  /// The minimum value that [pressure] can return for this pointer.
  final double pressureMin;

  /// The maximum value that [pressure] can return for this pointer.
  final double pressureMax;

  /// The tilt angle of the detected object, in radians.
  ///
  /// See also [PointerEvent.tilt] for more details.
  final double tilt;

  /// The orientation angle of the detected object, in radians.
  ///
  /// See also [PointerEvent.orientation] for more details.
  final double orientation;

  const StrokePoint({
    required this.position,
    required this.pressure,
    required this.pressureMin,
    required this.pressureMax,
    required this.tilt,
    required this.orientation,
  });

  /// Returns the pressure normalized to a 0.0 to 1.0 range based on [pressureMin] and [pressureMax].
  ///
  /// If [pressureMin] equals [pressureMax] (no pressure variation possible),
  /// returns 0.5 if [pressureMin] is almost equals to [pressureMax].
  double get normalizedPressure {
    final range = pressureMax - pressureMin;
    if (range < 0.0001) {
      return 0.5;
    }
    return ((pressure - pressureMin) / range).clamp(0.0, 1.0);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StrokePoint &&
          runtimeType == other.runtimeType &&
          position == other.position &&
          pressure == other.pressure &&
          pressureMin == other.pressureMin &&
          pressureMax == other.pressureMax &&
          tilt == other.tilt &&
          orientation == other.orientation;

  @override
  int get hashCode =>
      position.hashCode ^
      pressure.hashCode ^
      pressureMin.hashCode ^
      pressureMax.hashCode ^
      tilt.hashCode ^
      orientation.hashCode;
}

typedef _Extra = Map<Object, dynamic>;

/// A data class representing a stroke.
///
/// This consists of [points] and its metadata ([color], [width], [erasingBehavior]).
///
/// These data can be treated as data independent of the UI,
/// and can be processed externally, such as resampling and smoothing.
class Stroke {
  /// The kind of pointer device used to create the stroke
  PointerDeviceKind deviceKind;

  /// Points that compose the stroke with pressure information
  final List<StrokePoint> points;

  /// Stroke color
  final Color color;

  /// Stroke width (base width, can be modified by pressure)
  final double width;

  /// User-defined additional data.
  final _Extra? data;

  /// Creates a stroke
  Stroke({
    required this.deviceKind,
    required this.points,
    required this.color,
    required this.width,
    this.data,
  });

  /// Creates a new Stroke with new points or metadata
  ///
  /// Used when performing processing such as resampling and smoothing.
  Stroke copyWith({
    List<StrokePoint>? points,
    Color? color,
    double? width,
    _Extra? data,
  }) => Stroke(
    deviceKind: deviceKind, // deviceKind can't be changed
    points: points ?? List.from(this.points),
    color: color ?? this.color,
    width: width ?? this.width,
    data: data ?? this.data,
  );
}
