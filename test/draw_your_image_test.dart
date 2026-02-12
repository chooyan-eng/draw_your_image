import 'package:draw_your_image/draw_your_image.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:ui';

void main() {
  group('StrokePoint', () {
    test('normalizedPressure should return 0.0 to 1.0 range', () {
      final point = StrokePoint(
        position: const Offset(10, 10),
        pressure: 0.6,
        pressureMin: 0.2,
        pressureMax: 1.0,
        tilt: 0.0,
        orientation: 0.0,
      );

      final normalized = point.normalizedPressure;
      expect(normalized, closeTo(0.5, 0.01)); // (0.6 - 0.2) / (1.0 - 0.2) = 0.5
      expect(normalized, greaterThanOrEqualTo(0.0));
      expect(normalized, lessThanOrEqualTo(1.0));
    });

    test('normalizedPressure should handle min edge case', () {
      final point = StrokePoint(
        position: const Offset(10, 10),
        pressure: 0.2,
        pressureMin: 0.2,
        pressureMax: 1.0,
        tilt: 0.0,
        orientation: 0.0,
      );

      expect(point.normalizedPressure, closeTo(0.0, 0.01));
    });

    test('normalizedPressure should handle max edge case', () {
      final point = StrokePoint(
        position: const Offset(10, 10),
        pressure: 1.0,
        pressureMin: 0.2,
        pressureMax: 1.0,
        tilt: 0.0,
        orientation: 0.0,
      );

      expect(point.normalizedPressure, closeTo(1.0, 0.01));
    });

    test('normalizedPressure should return 0.5 when min equals max', () {
      final point = StrokePoint(
        position: const Offset(10, 10),
        pressure: 1.0,
        pressureMin: 1.0,
        pressureMax: 1.0,
        tilt: 0.0,
        orientation: 0.0,
      );

      expect(point.normalizedPressure, 0.5);
    });

    test('normalizedPressure should clamp values outside range', () {
      final point = StrokePoint(
        position: const Offset(10, 10),
        pressure: 1.5, // Outside max
        pressureMin: 0.2,
        pressureMax: 1.0,
        tilt: 0.0,
        orientation: 0.0,
      );

      expect(point.normalizedPressure, 1.0);
    });
  });
}
