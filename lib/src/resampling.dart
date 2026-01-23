import 'dart:ui';
import 'dart:math' as math;

import 'stroke.dart';

/// Extension methods for resampling a list of [Offset] points.
extension Resampling on List<Offset> {
  /// Resample the given list of points at regular intervals specified by [spacing].
  /// This function returns a new list of points that are evenly spaced along the original path.
  List<Offset> resampled({required double spacing}) {
    if (length < 2) {
      return List.from(this);
    }

    final resampled = [first];
    double accumulatedDistance = 0;

    for (int i = 1; i < length; i++) {
      final from = this[i - 1];
      final to = this[i];
      final distance = (to - from).distance;
      accumulatedDistance += distance;

      while (accumulatedDistance >= spacing) {
        final ratio = (accumulatedDistance - spacing) / distance;
        final interpolated = Offset.lerp(to, from, ratio)!;
        resampled.add(interpolated);
        accumulatedDistance -= spacing;
      }
    }

    // Add the last point
    if ((resampled.last - last).distance > spacing / 2) {
      resampled.add(last);
    }

    return resampled;
  }

  /// Reduce the number of points using the Ramer-Douglas-Peucker algorithm.
  ///
  /// This algorithm removes points that are less significant for maintaining
  /// the overall shape of the path, based on the [epsilon] tolerance value.
  ///
  /// A larger [epsilon] value results in more aggressive reduction (fewer points),
  /// while a smaller value preserves more detail.
  ///
  /// Recommended values:
  /// - 1.0: High quality (20-40% reduction)
  /// - 2.0: Balanced (40-60% reduction)
  /// - 5.0: High compression (60-80% reduction)
  List<Offset> reduced({required double epsilon}) {
    if (length < 3) {
      return List.from(this);
    }

    return _rdpRecursive(this, epsilon, 0, length - 1);
  }
}

/// Helper function to calculate perpendicular distance from a point to a line segment
double _perpendicularDistance(Offset point, Offset lineStart, Offset lineEnd) {
  final dx = lineEnd.dx - lineStart.dx;
  final dy = lineEnd.dy - lineStart.dy;

  // If the line segment is actually a point, return the distance to that point
  final lineLength = math.sqrt(dx * dx + dy * dy);
  if (lineLength == 0) {
    return (point - lineStart).distance;
  }

  // Calculate perpendicular distance using the cross product formula
  final numerator = ((point.dx - lineStart.dx) * dy - (point.dy - lineStart.dy) * dx).abs();
  return numerator / lineLength;
}

/// Recursive implementation of the Ramer-Douglas-Peucker algorithm
List<Offset> _rdpRecursive(List<Offset> points, double epsilon, int start, int end) {
  // Find the point with the maximum distance from the line segment
  double maxDistance = 0;
  int maxIndex = start;

  for (int i = start + 1; i < end; i++) {
    final distance = _perpendicularDistance(
      points[i],
      points[start],
      points[end],
    );

    if (distance > maxDistance) {
      maxDistance = distance;
      maxIndex = i;
    }
  }

  // If the maximum distance is greater than epsilon, recursively simplify
  if (maxDistance > epsilon) {
    // Recursive call for the two segments
    final leftSegment = _rdpRecursive(points, epsilon, start, maxIndex);
    final rightSegment = _rdpRecursive(points, epsilon, maxIndex, end);

    // Combine results (remove duplicate point at maxIndex)
    return [...leftSegment.sublist(0, leftSegment.length - 1), ...rightSegment];
  } else {
    // If all points are within epsilon, just return the endpoints
    return [points[start], points[end]];
  }
}

/// Reduces the number of points in a list of strokes using the Ramer-Douglas-Peucker algorithm.
///
/// This function processes each stroke in the list and returns a new list of strokes
/// with reduced points, helping to decrease data usage while maintaining visual quality.
///
/// The [epsilon] parameter controls the tolerance for point reduction. Larger values
/// result in more aggressive reduction.
///
/// Example:
/// ```dart
/// final optimizedStrokes = reduceStrokePoints(
///   originalStrokes,
///   epsilon: 2.0,
/// );
/// ```
List<Stroke> reduceStrokePoints(
  List<Stroke> strokes, {
  required double epsilon,
}) {
  return strokes.map((stroke) {
    final reducedPoints = stroke.points.reduced(epsilon: epsilon);
    return stroke.copyWith(points: reducedPoints);
  }).toList();
}
