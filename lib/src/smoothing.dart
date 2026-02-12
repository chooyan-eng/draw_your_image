import 'dart:ui';

import 'package:draw_your_image/src/stroke.dart';

typedef SmoothingFunc = Path Function(Stroke);

/// Smoothing modes for drawing strokes.
/// These options are pre-defined smoothing algorithms that can be applied to stroke points.
/// If you want to implement your own smoothing algorithm, you can provide a custom
/// path converter function to the [Draw] widget.
enum SmoothingMode {
  /// No smoothing, use linear interpolation
  none(generateLinearPath),

  /// Catmull-Rom spline interpolation
  catmullRom(generateCatmullRomPath);

  /// The smoothing function associated with this mode
  final SmoothingFunc converter;

  const SmoothingMode(this.converter);
}

/// Generate a Path using linear interpolation
///
/// This connects the points of the stroke in order with straight lines to create a Path.
Path generateLinearPath(Stroke stroke) {
  final path = Path();
  final points = stroke.points;

  return switch (points.length) {
    0 => path,
    1 =>
      path..addOval(Rect.fromCircle(center: points[0].position, radius: 0.5)),
    _ => _drawLinearPath(points, path),
  };
}

Path _drawLinearPath(List<StrokePoint> points, Path path) {
  path.moveTo(points[0].position.dx, points[0].position.dy);
  for (int i = 1; i < points.length; i++) {
    path.lineTo(points[i].position.dx, points[i].position.dy);
  }
  return path;
}

/// Draw path using Catmull-Rom spline interpolation
///
/// Connects the points of the stroke smoothly using Catmull-Rom spline curves.
/// The [tension] parameter controls the tightness of the curve (default: 0.8).
Path generateCatmullRomPath(Stroke stroke, {double tension = 0.8}) {
  final path = Path();
  final points = stroke.points;

  return switch (points.length) {
    0 => path,
    1 =>
      path..addOval(Rect.fromCircle(center: points[0].position, radius: 0.5)),
    2 =>
      path
        ..moveTo(points[0].position.dx, points[0].position.dy)
        ..lineTo(points[1].position.dx, points[1].position.dy),
    _ => _drawCatmullRomPath(points, path, tension),
  };
}

Path _drawCatmullRomPath(List<StrokePoint> points, Path path, double tension) {
  path.moveTo(points[0].position.dx, points[0].position.dy);
  for (int i = 0; i < points.length - 1; i++) {
    final p0 = i > 0 ? points[i - 1] : points[i];
    final p1 = points[i];
    final p2 = points[i + 1];
    final p3 = i < points.length - 2 ? points[i + 2] : p2;

    final cp1x =
        p1.position.dx + (p2.position.dx - p0.position.dx) / 6 * tension;
    final cp1y =
        p1.position.dy + (p2.position.dy - p0.position.dy) / 6 * tension;
    final cp2x =
        p2.position.dx - (p3.position.dx - p1.position.dx) / 6 * tension;
    final cp2y =
        p2.position.dy - (p3.position.dy - p1.position.dy) / 6 * tension;

    path.cubicTo(cp1x, cp1y, cp2x, cp2y, p2.position.dx, p2.position.dy);
  }
  return path;
}

/// Generate a Path with variable width based on pressure using Catmull-Rom spline interpolation
///
/// This creates a filled path where the width varies according to the pressure at each point.
/// The path is smoothed using Catmull-Rom splines for both position and width.
///
/// Parameters:
/// - [stroke]: The stroke to convert to a path
/// - [tension]: Controls the tightness of the curve (default: 0.8)
/// - [segments]: Number of interpolated segments between each pair of points (default: 20)
Path generatePressureSensitivePath(
  Stroke stroke, {
  double tension = 0.8,
  int segments = 20,
}) {
  final points = stroke.points;
  final baseWidth = stroke.width;

  if (points.isEmpty) return Path();

  if (points.length == 1) {
    final radius = baseWidth * points[0].normalizedPressure / 2;
    return Path()
      ..addOval(Rect.fromCircle(center: points[0].position, radius: radius));
  }

  // Generate interpolated points with pressure
  final interpolatedPoints = <StrokePoint>[];

  for (int i = 0; i < points.length - 1; i++) {
    final p0 = i > 0 ? points[i - 1] : points[i];
    final p1 = points[i];
    final p2 = points[i + 1];
    final p3 = i < points.length - 2 ? points[i + 2] : p2;

    for (int j = 0; j < segments; j++) {
      final t = j / segments;

      // Catmull-Rom interpolation for position
      final position = _catmullRomInterpolate(
        p0.position,
        p1.position,
        p2.position,
        p3.position,
        t,
        tension,
      );

      // Linear interpolation for normalized pressure (0.0 to 1.0)
      final normalizedPressure =
          p1.normalizedPressure +
          (p2.normalizedPressure - p1.normalizedPressure) * t;

      // Linear interpolation for tilt and orientation
      final tilt = p1.tilt + (p2.tilt - p1.tilt) * t;
      final orientation =
          p1.orientation + (p2.orientation - p1.orientation) * t;

      interpolatedPoints.add(
        StrokePoint(
          position: position,
          pressure: normalizedPressure,
          pressureMin: 0.0,
          pressureMax: 1.0,
          tilt: tilt,
          orientation: orientation,
        ),
      );
    }
  }

  // Add the last point
  interpolatedPoints.add(points.last);

  // Build the outline path
  return _buildVariableWidthPath(interpolatedPoints, baseWidth);
}

/// Interpolate a point using Catmull-Rom spline
Offset _catmullRomInterpolate(
  Offset p0,
  Offset p1,
  Offset p2,
  Offset p3,
  double t,
  double tension,
) {
  final t2 = t * t;
  final t3 = t2 * t;

  final v0 = (p2.dx - p0.dx) * tension;
  final v1 = (p3.dx - p1.dx) * tension;
  final x =
      (2 * p1.dx - 2 * p2.dx + v0 + v1) * t3 +
      (-3 * p1.dx + 3 * p2.dx - 2 * v0 - v1) * t2 +
      v0 * t +
      p1.dx;

  final w0 = (p2.dy - p0.dy) * tension;
  final w1 = (p3.dy - p1.dy) * tension;
  final y =
      (2 * p1.dy - 2 * p2.dy + w0 + w1) * t3 +
      (-3 * p1.dy + 3 * p2.dy - 2 * w0 - w1) * t2 +
      w0 * t +
      p1.dy;

  return Offset(x, y);
}

/// Build a filled path with variable width
Path _buildVariableWidthPath(List<StrokePoint> points, double baseWidth) {
  if (points.length < 2) return Path();

  final leftPoints = <Offset>[];
  final rightPoints = <Offset>[];

  for (int i = 0; i < points.length; i++) {
    final point = points[i];
    final width = baseWidth * point.normalizedPressure;

    // Calculate the perpendicular direction
    Offset direction;
    if (i == 0 && points.length > 1) {
      direction = (points[i + 1].position - point.position);
    } else if (i == points.length - 1 && i > 0) {
      direction = (point.position - points[i - 1].position);
    } else if (i > 0 && i < points.length - 1) {
      direction = (points[i + 1].position - points[i - 1].position);
    } else {
      // Fallback for edge cases
      direction = const Offset(1, 0);
    }

    // Use a small epsilon to handle near-zero distances
    if (direction.distance < 0.001) {
      direction = const Offset(1, 0);
    }

    final perpendicular =
        Offset(-direction.dy, direction.dx) / direction.distance;
    final offset = perpendicular * (width / 2);

    leftPoints.add(point.position + offset);
    rightPoints.add(point.position - offset);
  }

  // Check if we have valid points
  if (leftPoints.isEmpty || rightPoints.isEmpty) {
    return Path();
  }

  // Build the path
  final path = Path();

  // Draw left side
  path.moveTo(leftPoints[0].dx, leftPoints[0].dy);
  for (int i = 1; i < leftPoints.length; i++) {
    path.lineTo(leftPoints[i].dx, leftPoints[i].dy);
  }

  // Draw right side in reverse
  for (int i = rightPoints.length - 1; i >= 0; i--) {
    path.lineTo(rightPoints[i].dx, rightPoints[i].dy);
  }

  path.close();

  return path;
}
