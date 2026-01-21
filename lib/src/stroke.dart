import 'dart:ui';

/// Defines the erasing behavior for a stroke.
enum ErasingBehavior {
  /// Normal drawing mode (not erasing)
  none,

  /// Pixel-level erasing using BlendMode.clear.
  /// Only erases the overlapping pixels where the eraser stroke passes.
  /// The stroke itself remains in the stroke list.
  pixel,

  /// Stroke-level erasing using intersection detection.
  /// Removes entire strokes that intersect with the eraser stroke.
  /// Uses the intersection detector to determine which strokes to remove.
  stroke,
}

/// A data class representing a stroke.
///
/// This consists of [points] and its metadata ([color], [width], [erasingBehavior]).
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

  /// Erasing behavior for this stroke
  final ErasingBehavior erasingBehavior;

  /// Whether this is an erasing stroke (deprecated, use erasingBehavior instead)
  bool get isErasing => erasingBehavior != ErasingBehavior.none;

  /// Whether this stroke should be painted on [_FreehandPainter]
  bool get shouldPaint => erasingBehavior != ErasingBehavior.stroke;

  /// Creates a stroke
  Stroke({
    required this.deviceKind,
    required this.points,
    required this.color,
    required this.width,
    this.erasingBehavior = ErasingBehavior.none,
  });

  /// Creates a new Stroke with new points or metadata
  ///
  /// Used when performing processing such as resampling and smoothing.
  Stroke copyWith({
    List<Offset>? points,
    Color? color,
    double? width,
    ErasingBehavior? erasingBehavior,
  }) => Stroke(
    deviceKind: deviceKind, // deviceKind can't be changed
    points: points ?? List.from(this.points),
    color: color ?? this.color,
    width: width ?? this.width,
    erasingBehavior: erasingBehavior ?? this.erasingBehavior,
  );
}
