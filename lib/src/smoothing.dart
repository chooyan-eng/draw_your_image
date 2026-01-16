part of draw_your_image;

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
    1 => path..addOval(Rect.fromCircle(center: points[0], radius: 0.5)),
    _ => _drawLinearPath(points, path),
  };
}

Path _drawLinearPath(List<Offset> points, Path path) {
  path.moveTo(points[0].dx, points[0].dy);
  for (int i = 1; i < points.length; i++) {
    path.lineTo(points[i].dx, points[i].dy);
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
    1 => path..addOval(Rect.fromCircle(center: points[0], radius: 0.5)),
    2 =>
      path
        ..moveTo(points[0].dx, points[0].dy)
        ..lineTo(points[1].dx, points[1].dy),
    _ => _drawCatmullRomPath(points, path, tension),
  };
}

Path _drawCatmullRomPath(List<Offset> points, Path path, double tension) {
  path.moveTo(points[0].dx, points[0].dy);
  for (int i = 0; i < points.length - 1; i++) {
    final p0 = i > 0 ? points[i - 1] : points[i];
    final p1 = points[i];
    final p2 = points[i + 1];
    final p3 = i < points.length - 2 ? points[i + 2] : p2;

    final cp1x = p1.dx + (p2.dx - p0.dx) / 6 * tension;
    final cp1y = p1.dy + (p2.dy - p0.dy) / 6 * tension;
    final cp2x = p2.dx - (p3.dx - p1.dx) / 6 * tension;
    final cp2y = p2.dy - (p3.dy - p1.dy) / 6 * tension;

    path.cubicTo(cp1x, cp1y, cp2x, cp2y, p2.dx, p2.dy);
  }
  return path;
}
