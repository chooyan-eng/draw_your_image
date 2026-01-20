import 'dart:ui';

/// A data class representing a stroke.
///
/// This consists of [points] and its metadata ([color], [width], [isErasing] flag).
///
/// These data can be treated as data independent of the UI,
/// and can be processed externally, such as resampling and smoothing.
class Stroke {
  /// The kind of pointer device used to create the stroke
  PointerDeviceKind deviceKind;

  /// Points that compose the stroke
  final List<Offset> points;

  /// Stroke color
  final Color color;

  /// Stroke width
  final double width;

  /// Whether this is an erasing stroke
  final bool isErasing;

  /// Creates a stroke
  Stroke({
    required this.deviceKind,
    required this.points,
    required this.color,
    required this.width,
    this.isErasing = false,
  });

  /// Creates a new Stroke with new points or metadata
  ///
  /// Used when performing processing such as resampling and smoothing.
  Stroke copyWith({
    List<Offset>? points,
    Color? color,
    double? width,
    bool? isErasing,
  }) => Stroke(
    deviceKind: deviceKind, // deviceKind can't be changed
    points: points ?? List.from(this.points),
    color: color ?? this.color,
    width: width ?? this.width,
    isErasing: isErasing ?? this.isErasing,
  );
}
