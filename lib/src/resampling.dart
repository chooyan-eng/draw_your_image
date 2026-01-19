import 'dart:ui';

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
}
