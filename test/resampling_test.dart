import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:draw_your_image/draw_your_image.dart';

// Test helper to create StrokePoint with default values for new fields
StrokePoint testPoint(Offset position, double pressure) => StrokePoint(
  position: position,
  pressure: pressure,
  pressureMin: 1.0,
  pressureMax: 1.0,
  tilt: 0.0,
  orientation: 0.0,
);

void main() {
  group('Point Reduction (RDP Algorithm)', () {
    test('should preserve endpoints', () {
      final points = [
        testPoint(const Offset(0, 0), 1.0),
        testPoint(const Offset(50, 1), 1.0),
        testPoint(const Offset(100, 0), 1.0),
      ];

      final reduced = points.reduced(epsilon: 2.0);

      expect(reduced.first, points.first);
      expect(reduced.last, points.last);
    });

    test('should remove points close to a straight line', () {
      // Create a nearly straight line
      final points = [
        testPoint(const Offset(0, 0), 1.0),
        testPoint(const Offset(25, 0.5), 1.0),
        testPoint(const Offset(50, 1.0), 1.0),
        testPoint(const Offset(75, 0.5), 1.0),
        testPoint(const Offset(100, 0), 1.0),
      ];

      final reduced = points.reduced(epsilon: 2.0);

      // Should reduce to just start and end points
      expect(reduced.length, lessThan(points.length));
      expect(reduced.first, points.first);
      expect(reduced.last, points.last);
    });

    test('should preserve important points on a curved path', () {
      // Create an L-shape: horizontal then vertical
      final points = [
        testPoint(const Offset(0, 0), 1.0),
        testPoint(const Offset(25, 0), 1.0),
        testPoint(const Offset(50, 0), 1.0),
        testPoint(const Offset(50, 25), 1.0),
        testPoint(const Offset(50, 50), 1.0),
      ];

      final reduced = points.reduced(epsilon: 2.0);

      // Should keep the corner point at (50, 0)
      expect(reduced.length, greaterThanOrEqualTo(3));
      expect(reduced.first.position, const Offset(0, 0));
      expect(reduced.last.position, const Offset(50, 50));
    });

    test('should preserve pressure values', () {
      final points = [
        testPoint(const Offset(0, 0), 0.5),
        testPoint(const Offset(25, 0.5), 0.7),
        testPoint(const Offset(50, 1.0), 0.8),
        testPoint(const Offset(75, 0.5), 0.9),
        testPoint(const Offset(100, 0), 1.0),
      ];

      final reduced = points.reduced(epsilon: 2.0);

      expect(reduced.first.pressure, 0.5);
      expect(reduced.last.pressure, 1.0);
    });

    test('should return a copy for lists with less than 3 points', () {
      final singlePoint = [testPoint(const Offset(10, 10), 1.0)];
      final reducedSingle = singlePoint.reduced(epsilon: 2.0);
      expect(reducedSingle.length, 1);
      expect(reducedSingle.first, singlePoint.first);

      final twoPoints = [
        testPoint(const Offset(0, 0), 1.0),
        testPoint(const Offset(10, 10), 1.0),
      ];
      final reducedTwo = twoPoints.reduced(epsilon: 2.0);
      expect(reducedTwo.length, 2);
      expect(reducedTwo, twoPoints);
    });

    test('should reduce more aggressively with larger epsilon', () {
      final points = List.generate(
        20,
        (i) => testPoint(Offset(i * 5.0, (i % 2) * 2.0), 1.0),
      );

      final reducedSmall = points.reduced(epsilon: 1.0);
      final reducedLarge = points.reduced(epsilon: 5.0);

      expect(reducedLarge.length, lessThanOrEqualTo(reducedSmall.length));
    });

    test('should handle empty list', () {
      final points = <StrokePoint>[];
      final reduced = points.reduced(epsilon: 2.0);
      expect(reduced.length, 0);
    });
  });

  group('Point Resampling', () {
    test('should generate evenly spaced points', () {
      final points = [
        testPoint(const Offset(0, 0), 1.0),
        testPoint(const Offset(100, 0), 1.0),
      ];

      final resampled = points.resampled(spacing: 25.0);

      // Should have approximately 5 points (0, 25, 50, 75, 100)
      expect(resampled.length, greaterThanOrEqualTo(4));
      expect(resampled.first.position, const Offset(0, 0));
    });

    test('should interpolate pressure values', () {
      final points = [
        testPoint(const Offset(0, 0), 0.0),
        testPoint(const Offset(100, 0), 1.0),
      ];

      final resampled = points.resampled(spacing: 50.0);

      // Middle point should have interpolated pressure around 0.5
      if (resampled.length >= 3) {
        expect(resampled[1].pressure, closeTo(0.5, 0.2));
      }
    });
  });

  group('reduceStrokePoints', () {
    test('should reduce points in all strokes', () {
      final strokes = [
        Stroke(
          deviceKind: PointerDeviceKind.touch,
          points: [
            testPoint(const Offset(0, 0), 1.0),
            testPoint(const Offset(25, 0.5), 1.0),
            testPoint(const Offset(50, 1.0), 1.0),
            testPoint(const Offset(75, 0.5), 1.0),
            testPoint(const Offset(100, 0), 1.0),
          ],
          color: const Color(0xFF000000),
          width: 5.0,
        ),
        Stroke(
          deviceKind: PointerDeviceKind.touch,
          points: [
            testPoint(const Offset(0, 0), 1.0),
            testPoint(const Offset(10, 10), 1.0),
            testPoint(const Offset(20, 20), 1.0),
          ],
          color: const Color(0xFF000000),
          width: 5.0,
        ),
      ];

      final reduced = reduceStrokePoints(strokes, epsilon: 2.0);

      expect(reduced.length, strokes.length);
      for (int i = 0; i < reduced.length; i++) {
        expect(
          reduced[i].points.length,
          lessThanOrEqualTo(strokes[i].points.length),
        );
      }
    });

    test('should preserve stroke metadata', () {
      final original = Stroke(
        deviceKind: PointerDeviceKind.mouse,
        points: [
          testPoint(const Offset(0, 0), 1.0),
          testPoint(const Offset(25, 0.5), 1.0),
          testPoint(const Offset(50, 0), 1.0),
        ],
        color: const Color(0xFFFF0000),
        width: 3.0,
        data: {#erasing: true},
      );

      final reduced = reduceStrokePoints([original], epsilon: 2.0);

      expect(reduced.length, 1);
      expect(reduced.first.color, original.color);
      expect(reduced.first.width, original.width);
      expect(reduced.first.data, original.data);
      expect(reduced.first.deviceKind, original.deviceKind);
    });

    test('should handle empty stroke list', () {
      final reduced = reduceStrokePoints([], epsilon: 2.0);
      expect(reduced.length, 0);
    });
  });
}
