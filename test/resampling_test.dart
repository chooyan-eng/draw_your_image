import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:draw_your_image/draw_your_image.dart';

void main() {
  group('Point Reduction (RDP Algorithm)', () {
    test('should preserve endpoints', () {
      final points = [
        const Offset(0, 0),
        const Offset(50, 1),
        const Offset(100, 0),
      ];

      final reduced = points.reduced(epsilon: 2.0);

      expect(reduced.first, points.first);
      expect(reduced.last, points.last);
    });

    test('should remove points close to a straight line', () {
      // Create a nearly straight line
      final points = [
        const Offset(0, 0),
        const Offset(25, 0.5),
        const Offset(50, 1.0),
        const Offset(75, 0.5),
        const Offset(100, 0),
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
        const Offset(0, 0),
        const Offset(25, 0),
        const Offset(50, 0),
        const Offset(50, 25),
        const Offset(50, 50),
      ];

      final reduced = points.reduced(epsilon: 2.0);

      // Should keep the corner point at (50, 0)
      expect(reduced.length, greaterThanOrEqualTo(3));
      expect(reduced.first, const Offset(0, 0));
      expect(reduced.last, const Offset(50, 50));
    });

    test('should return a copy for lists with less than 3 points', () {
      final singlePoint = [const Offset(10, 10)];
      final reducedSingle = singlePoint.reduced(epsilon: 2.0);
      expect(reducedSingle.length, 1);
      expect(reducedSingle.first, singlePoint.first);

      final twoPoints = [const Offset(0, 0), const Offset(10, 10)];
      final reducedTwo = twoPoints.reduced(epsilon: 2.0);
      expect(reducedTwo.length, 2);
      expect(reducedTwo, twoPoints);
    });

    test('should reduce more aggressively with larger epsilon', () {
      final points = List.generate(
        20,
        (i) => Offset(i * 5.0, (i % 2) * 2.0),
      );

      final reducedSmall = points.reduced(epsilon: 1.0);
      final reducedLarge = points.reduced(epsilon: 5.0);

      expect(reducedLarge.length, lessThanOrEqualTo(reducedSmall.length));
    });

    test('should handle empty list', () {
      final points = <Offset>[];
      final reduced = points.reduced(epsilon: 2.0);
      expect(reduced.length, 0);
    });
  });

  group('reduceStrokePoints', () {
    test('should reduce points in all strokes', () {
      final strokes = [
        Stroke(
          deviceKind: PointerDeviceKind.touch,
          points: [
            const Offset(0, 0),
            const Offset(25, 0.5),
            const Offset(50, 1.0),
            const Offset(75, 0.5),
            const Offset(100, 0),
          ],
          color: const Color(0xFF000000),
          width: 5.0,
        ),
        Stroke(
          deviceKind: PointerDeviceKind.touch,
          points: [
            const Offset(0, 0),
            const Offset(10, 10),
            const Offset(20, 20),
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
          const Offset(0, 0),
          const Offset(25, 0.5),
          const Offset(50, 0),
        ],
        color: const Color(0xFFFF0000),
        width: 3.0,
        erasingBehavior: ErasingBehavior.pixel,
      );

      final reduced = reduceStrokePoints([original], epsilon: 2.0);

      expect(reduced.length, 1);
      expect(reduced.first.color, original.color);
      expect(reduced.first.width, original.width);
      expect(reduced.first.erasingBehavior, original.erasingBehavior);
      expect(reduced.first.deviceKind, original.deviceKind);
    });

    test('should handle empty stroke list', () {
      final reduced = reduceStrokePoints([], epsilon: 2.0);
      expect(reduced.length, 0);
    });
  });
}
