import 'dart:ui';
import 'package:draw_your_image/src/stroke.dart';

/// Function type for detecting intersecting strokes.
///
/// Given a list of [strokes] and a [testStroke], returns a list of strokes
/// that intersect with the test stroke according to the detection algorithm.
typedef IntersectionDetector =
    List<Stroke> Function(List<Stroke> strokes, Stroke testStroke);

/// Intersection detection modes for stroke overlap detection.
///
/// These options are pre-defined algorithms that can be used to detect
/// when strokes intersect or overlap. This is useful for implementing
/// features like erasing, selecting, or collision detection.
///
/// If you want to implement your own detection algorithm, you can provide
/// a custom detector function to the [Draw] widget.
enum IntersectionMode {
  /// Segment-to-segment distance based detection.
  ///
  /// This algorithm calculates the minimum distance between line segments
  /// of the strokes and considers them intersecting if the distance is
  /// less than the sum of their half-widths.
  segmentDistance(detectIntersectionBySegmentDistance);

  /// The detection function associated with this mode
  final IntersectionDetector detector;

  const IntersectionMode(this.detector);
}

/// Detect intersecting strokes using segment-to-segment distance calculation.
///
/// This function checks each stroke in [strokes] against [testStroke] by
/// calculating the minimum distance between their line segments. If the
/// distance is less than or equal to the sum of their half-widths, the
/// stroke is considered intersecting.
///
/// This is the default detection algorithm used for erasing functionality.
List<Stroke> detectIntersectionBySegmentDistance(
  List<Stroke> strokes,
  Stroke testStroke,
) {
  final testRadius = testStroke.width / 2;
  final intersectingStrokes = <Stroke>[];

  for (final stroke in strokes) {
    // Skip erasing strokes - only check normal drawing strokes

    if (testStroke.points.length < 2) continue; // Need at least 2 points

    final threshold = testRadius + stroke.width / 2;
    bool intersects = false;

    // Check each stroke segment against each test stroke segment
    for (int i = 0; i < stroke.points.length - 1; i++) {
      final p1 = stroke.points[i].position;
      final p2 = stroke.points[i + 1].position;

      for (int j = 0; j < testStroke.points.length - 1; j++) {
        final q1 = testStroke.points[j].position;
        final q2 = testStroke.points[j + 1].position;

        final distance = _distanceSegmentToSegment(p1, p2, q1, q2);
        if (distance <= threshold) {
          intersects = true;
          break;
        }
      }

      if (intersects) break;
    }

    if (intersects) {
      intersectingStrokes.add(stroke);
    }
  }

  return intersectingStrokes;
}

/// Calculate the minimum distance between two line segments.
///
/// Returns the shortest distance between the line segment [p1]-[p2]
/// and the line segment [q1]-[q2].
double _distanceSegmentToSegment(Offset p1, Offset p2, Offset q1, Offset q2) {
  // Helper function to calculate distance from point to segment
  double pointToSegmentDistance(Offset point, Offset segStart, Offset segEnd) {
    final dx = segEnd.dx - segStart.dx;
    final dy = segEnd.dy - segStart.dy;
    final lengthSquared = dx * dx + dy * dy;

    if (lengthSquared == 0) {
      // Segment is actually a point
      return (point - segStart).distance;
    }

    // Calculate projection parameter
    final t =
        ((point.dx - segStart.dx) * dx + (point.dy - segStart.dy) * dy) /
        lengthSquared;

    if (t < 0) {
      return (point - segStart).distance;
    } else if (t > 1) {
      return (point - segEnd).distance;
    } else {
      final projection = Offset(segStart.dx + t * dx, segStart.dy + t * dy);
      return (point - projection).distance;
    }
  }

  // Calculate minimum distance between two segments
  // Check endpoints of first segment to second segment
  final d1 = pointToSegmentDistance(p1, q1, q2);
  final d2 = pointToSegmentDistance(p2, q1, q2);

  // Check endpoints of second segment to first segment
  final d3 = pointToSegmentDistance(q1, p1, p2);
  final d4 = pointToSegmentDistance(q2, p1, p2);

  return [d1, d2, d3, d4].reduce((a, b) => a < b ? a : b);
}
