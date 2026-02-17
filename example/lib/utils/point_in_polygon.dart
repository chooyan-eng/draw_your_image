import 'dart:ui';

import 'package:draw_your_image/draw_your_image.dart';

/// IntersectionDetector that selects strokes inside the lasso polygon.
///
/// Uses the [testStroke] points as polygon vertices and returns strokes from
/// [strokes] that are inside the polygon (using [isStrokeInPolygon]).
List<Stroke> detectLassoIntersection(List<Stroke> strokes, Stroke testStroke) {
  if (testStroke.points.length < 3) return [];
  final polygon = testStroke.points.map((p) => p.position).toList();
  return strokes.where((stroke) {
    final positions = stroke.points.map((p) => p.position).toList();
    return isStrokeInPolygon(positions, polygon);
  }).toList();
}

/// Function to determine if a point is inside a polygon
///
/// Uses Ray Casting Algorithm.
/// Determines by counting how many times a ray extending rightward from the point
/// intersects with the polygon's edges.
/// If the intersection count is odd, it's inside; if even, it's outside.
///
/// [point]: The point to check
/// [polygon]: List of polygon vertices (does not need to be closed)
///
/// Returns: true if the point is inside the polygon, false if outside
bool isPointInPolygon(Offset point, List<Offset> polygon) {
  if (polygon.length < 3) {
    // At least 3 points are required to form a polygon
    return false;
  }

  int intersections = 0;
  final px = point.dx;
  final py = point.dy;

  // Perform intersection checks for each edge
  for (int i = 0; i < polygon.length; i++) {
    final p1 = polygon[i];
    final p2 =
        polygon[(i + 1) %
            polygon.length]; // Next point (last point connects to first)

    // Skip if the edge is below the horizontal line
    if (p1.dy > py != p2.dy > py) {
      // Calculate the X coordinate of the ray-edge intersection
      final intersectionX =
          (p2.dx - p1.dx) * (py - p1.dy) / (p2.dy - p1.dy) + p1.dx;

      // Count as intersection if the intersection is to the right of the point
      if (px < intersectionX) {
        intersections++;
      }
    }
  }

  // Inside if the intersection count is odd
  return intersections.isOdd;
}

/// Function to determine if all points of a stroke are inside a polygon
///
/// Used to determine if an entire stroke is contained within a lasso.
/// Returns true if at least the specified ratio of stroke points are inside the polygon.
///
/// [strokePoints]: List of stroke points
/// [polygon]: List of polygon vertices
/// [threshold]: Ratio of points that should be inside (0.0-1.0). Default is 0.5 (50% or more)
///
/// Returns: true if the specified ratio or more of points are inside the polygon
bool isStrokeInPolygon(
  List<Offset> strokePoints,
  List<Offset> polygon, {
  double threshold = 0.5,
}) {
  if (strokePoints.isEmpty) {
    return false;
  }

  int pointsInside = 0;
  for (final point in strokePoints) {
    if (isPointInPolygon(point, polygon)) {
      pointsInside++;
    }
  }

  final ratio = pointsInside / strokePoints.length;
  return ratio >= threshold;
}
