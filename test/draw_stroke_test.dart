import 'package:draw_your_image/draw_your_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Draw widget - Basic stroke tests', () {
    testWidgets('should create a stroke with a single point when tapping',
        (tester) async {
      Stroke? capturedStroke;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Draw(
              strokes: const [],
              onStrokeDrawn: (stroke) => capturedStroke = stroke,
            ),
          ),
        ),
      );

      // Tap at a single position
      final gesture = await tester.startGesture(const Offset(100, 100));
      await gesture.up();
      await tester.pump();

      expect(capturedStroke, isNotNull);
      expect(capturedStroke!.points.length, 1);
      expect(capturedStroke!.points.first, const Offset(100, 100));
    });

    testWidgets('should create a stroke with multiple points when drawing',
        (tester) async {
      Stroke? capturedStroke;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Draw(
              strokes: const [],
              onStrokeDrawn: (stroke) => capturedStroke = stroke,
            ),
          ),
        ),
      );

      // Draw a line
      final gesture = await tester.startGesture(const Offset(100, 100));
      await gesture.moveTo(const Offset(150, 150));
      await gesture.moveTo(const Offset(200, 200));
      await gesture.up();
      await tester.pump();

      expect(capturedStroke, isNotNull);
      expect(capturedStroke!.points.length, 3);
      expect(capturedStroke!.points[0], const Offset(100, 100));
      expect(capturedStroke!.points[1], const Offset(150, 150));
      expect(capturedStroke!.points[2], const Offset(200, 200));
    });

    testWidgets('should use default stroke properties', (tester) async {
      Stroke? capturedStroke;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Draw(
              strokes: const [],
              strokeColor: Colors.red,
              strokeWidth: 10.0,
              onStrokeDrawn: (stroke) => capturedStroke = stroke,
            ),
          ),
        ),
      );

      final gesture = await tester.startGesture(const Offset(100, 100));
      await gesture.up();
      await tester.pump();

      expect(capturedStroke!.color, Colors.red);
      expect(capturedStroke!.width, 10.0);
      expect(capturedStroke!.erasingBehavior, ErasingBehavior.none);
    });
  });

  group('Draw widget - Device type tests', () {
    testWidgets('should record stylus device kind correctly', (tester) async {
      Stroke? capturedStroke;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Draw(
              strokes: const [],
              onStrokeDrawn: (stroke) => capturedStroke = stroke,
            ),
          ),
        ),
      );

      final gesture = await tester.startGesture(
        const Offset(100, 100),
        kind: PointerDeviceKind.stylus,
      );
      await gesture.moveTo(const Offset(200, 200));
      await gesture.up();
      await tester.pump();

      expect(capturedStroke, isNotNull);
      expect(capturedStroke!.deviceKind, PointerDeviceKind.stylus);
    });

    testWidgets('should record touch device kind correctly', (tester) async {
      Stroke? capturedStroke;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Draw(
              strokes: const [],
              onStrokeDrawn: (stroke) => capturedStroke = stroke,
            ),
          ),
        ),
      );

      final gesture = await tester.startGesture(
        const Offset(100, 100),
        kind: PointerDeviceKind.touch,
      );
      await gesture.moveTo(const Offset(200, 200));
      await gesture.up();
      await tester.pump();

      expect(capturedStroke, isNotNull);
      expect(capturedStroke!.deviceKind, PointerDeviceKind.touch);
    });

    testWidgets('should record mouse device kind correctly', (tester) async {
      Stroke? capturedStroke;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Draw(
              strokes: const [],
              onStrokeDrawn: (stroke) => capturedStroke = stroke,
            ),
          ),
        ),
      );

      final gesture = await tester.startGesture(
        const Offset(100, 100),
        kind: PointerDeviceKind.mouse,
      );
      await gesture.moveTo(const Offset(200, 200));
      await gesture.up();
      await tester.pump();

      expect(capturedStroke, isNotNull);
      expect(capturedStroke!.deviceKind, PointerDeviceKind.mouse);
    });

    testWidgets('should record inverted stylus device kind correctly',
        (tester) async {
      Stroke? capturedStroke;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Draw(
              strokes: const [],
              onStrokeDrawn: (stroke) => capturedStroke = stroke,
            ),
          ),
        ),
      );

      final gesture = await tester.startGesture(
        const Offset(100, 100),
        kind: PointerDeviceKind.invertedStylus,
      );
      await gesture.moveTo(const Offset(200, 200));
      await gesture.up();
      await tester.pump();

      expect(capturedStroke, isNotNull);
      expect(capturedStroke!.deviceKind, PointerDeviceKind.invertedStylus);
    });
  });

  group('Draw widget - onStrokeStarted callback tests', () {
    testWidgets('should cancel stroke when onStrokeStarted returns null',
        (tester) async {
      Stroke? capturedStroke;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Draw(
              strokes: const [],
              onStrokeDrawn: (stroke) => capturedStroke = stroke,
              onStrokeStarted: (newStroke, currentStroke) => null,
            ),
          ),
        ),
      );

      final gesture = await tester.startGesture(const Offset(100, 100));
      await gesture.moveTo(const Offset(200, 200));
      await gesture.up();
      await tester.pump();

      expect(capturedStroke, isNull);
    });

    testWidgets(
        'should modify stroke properties when onStrokeStarted returns modified stroke',
        (tester) async {
      Stroke? capturedStroke;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Draw(
              strokes: const [],
              strokeColor: Colors.black,
              strokeWidth: 4.0,
              onStrokeDrawn: (stroke) => capturedStroke = stroke,
              onStrokeStarted: (newStroke, currentStroke) {
                if (currentStroke != null) {
                  return currentStroke;
                }
                return newStroke.copyWith(
                  color: Colors.blue,
                  width: 10.0,
                );
              },
            ),
          ),
        ),
      );

      final gesture = await tester.startGesture(const Offset(100, 100));
      await gesture.up();
      await tester.pump();

      expect(capturedStroke, isNotNull);
      expect(capturedStroke!.color, Colors.blue);
      expect(capturedStroke!.width, 10.0);
    });

    testWidgets(
        'should filter strokes by device type using onStrokeStarted',
        (tester) async {
      Stroke? capturedStroke;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Draw(
              strokes: const [],
              onStrokeDrawn: (stroke) => capturedStroke = stroke,
              onStrokeStarted: (newStroke, currentStroke) {
                if (currentStroke != null) {
                  return currentStroke;
                }
                // Only accept stylus input
                return newStroke.deviceKind == PointerDeviceKind.stylus
                    ? newStroke
                    : null;
              },
            ),
          ),
        ),
      );

      // Try with touch - should be rejected
      final touchGesture = await tester.startGesture(
        const Offset(100, 100),
        kind: PointerDeviceKind.touch,
      );
      await touchGesture.up();
      await tester.pump();
      expect(capturedStroke, isNull);

      // Try with stylus - should be accepted
      final stylusGesture = await tester.startGesture(
        const Offset(200, 200),
        kind: PointerDeviceKind.stylus,
      );
      await stylusGesture.up();
      await tester.pump();
      expect(capturedStroke, isNotNull);
      expect(capturedStroke!.deviceKind, PointerDeviceKind.stylus);
    });

    testWidgets(
        'should set different properties based on device type',
        (tester) async {
      Stroke? capturedStroke;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Draw(
              strokes: const [],
              onStrokeDrawn: (stroke) => capturedStroke = stroke,
              onStrokeStarted: (newStroke, currentStroke) {
                if (currentStroke != null) {
                  return currentStroke;
                }
                // Stylus: black and thin, Touch: red and thick
                if (newStroke.deviceKind == PointerDeviceKind.stylus) {
                  return newStroke.copyWith(
                    color: Colors.black,
                    width: 2.0,
                  );
                } else {
                  return newStroke.copyWith(
                    color: Colors.red,
                    width: 8.0,
                  );
                }
              },
            ),
          ),
        ),
      );

      // Test with stylus
      final stylusGesture = await tester.startGesture(
        const Offset(100, 100),
        kind: PointerDeviceKind.stylus,
      );
      await stylusGesture.up();
      await tester.pump();
      expect(capturedStroke!.color, Colors.black);
      expect(capturedStroke!.width, 2.0);

      // Test with touch
      capturedStroke = null;
      final touchGesture = await tester.startGesture(
        const Offset(200, 200),
        kind: PointerDeviceKind.touch,
      );
      await touchGesture.up();
      await tester.pump();
      expect(capturedStroke!.color, Colors.red);
      expect(capturedStroke!.width, 8.0);
    });
  });

  group('Draw widget - onStrokeUpdated callback tests', () {
    testWidgets('should call onStrokeUpdated for each pointer move',
        (tester) async {
      int updateCallCount = 0;
      Stroke? capturedStroke;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Draw(
              strokes: const [],
              onStrokeDrawn: (stroke) => capturedStroke = stroke,
              onStrokeUpdated: (currentStroke) {
                updateCallCount++;
                return currentStroke;
              },
            ),
          ),
        ),
      );

      final gesture = await tester.startGesture(const Offset(100, 100));
      await gesture.moveTo(const Offset(150, 150));
      await gesture.moveTo(const Offset(200, 200));
      await gesture.up();
      await tester.pump();

      // Should be called twice (for two moveTo calls)
      expect(updateCallCount, 2);
      expect(capturedStroke, isNotNull);
    });

    testWidgets('should cancel stroke when onStrokeUpdated returns null',
        (tester) async {
      Stroke? capturedStroke;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Draw(
              strokes: const [],
              onStrokeDrawn: (stroke) => capturedStroke = stroke,
              onStrokeUpdated: (currentStroke) {
                // Cancel after first point addition
                return currentStroke.points.length > 2 ? null : currentStroke;
              },
            ),
          ),
        ),
      );

      final gesture = await tester.startGesture(const Offset(100, 100));
      await gesture.moveTo(const Offset(150, 150));
      await gesture.moveTo(const Offset(200, 200)); // This should cancel
      await gesture.up();
      await tester.pump();

      expect(capturedStroke, isNull);
    });

    testWidgets('should modify points in onStrokeUpdated (trailing effect)',
        (tester) async {
      Stroke? capturedStroke;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Draw(
              strokes: const [],
              onStrokeDrawn: (stroke) => capturedStroke = stroke,
              onStrokeUpdated: (currentStroke) {
                // Keep only last 2 points
                if (currentStroke.points.length > 2) {
                  return currentStroke.copyWith(
                    points: currentStroke.points
                        .sublist(currentStroke.points.length - 2),
                  );
                }
                return currentStroke;
              },
            ),
          ),
        ),
      );

      final gesture = await tester.startGesture(const Offset(100, 100));
      await gesture.moveTo(const Offset(150, 150));
      await gesture.moveTo(const Offset(200, 200));
      await gesture.moveTo(const Offset(250, 250));
      await gesture.up();
      await tester.pump();

      expect(capturedStroke, isNotNull);
      expect(capturedStroke!.points.length, 2);
      expect(capturedStroke!.points[0], const Offset(200, 200));
      expect(capturedStroke!.points[1], const Offset(250, 250));
    });

    testWidgets('should change color dynamically in onStrokeUpdated',
        (tester) async {
      Stroke? capturedStroke;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Draw(
              strokes: const [],
              strokeColor: Colors.black,
              onStrokeDrawn: (stroke) => capturedStroke = stroke,
              onStrokeUpdated: (currentStroke) {
                // Change to red after 2 points
                if (currentStroke.points.length > 2) {
                  return currentStroke.copyWith(color: Colors.red);
                }
                return currentStroke;
              },
            ),
          ),
        ),
      );

      final gesture = await tester.startGesture(const Offset(100, 100));
      await gesture.moveTo(const Offset(150, 150));
      await gesture.moveTo(const Offset(200, 200));
      await gesture.up();
      await tester.pump();

      expect(capturedStroke, isNotNull);
      expect(capturedStroke!.color, Colors.red);
    });
  });

  group('Draw widget - Multiple touch control tests', () {
    testWidgets('should ignore second touch when first is active',
        (tester) async {
      final capturedStrokes = <Stroke>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Draw(
              strokes: const [],
              onStrokeDrawn: (stroke) => capturedStrokes.add(stroke),
            ),
          ),
        ),
      );

      // Start first gesture
      final gesture1 = await tester.startGesture(const Offset(100, 100));
      await tester.pump();

      // Try to start second gesture while first is active
      final gesture2 = await tester.startGesture(const Offset(200, 200));
      await gesture2.up();
      await tester.pump();

      // Complete first gesture
      await gesture1.up();
      await tester.pump();

      // Only first gesture should create a stroke
      expect(capturedStrokes.length, 1);
      expect(capturedStrokes[0].points.first, const Offset(100, 100));
    });

    testWidgets('should accept new touch after previous is completed',
        (tester) async {
      final capturedStrokes = <Stroke>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Draw(
              strokes: const [],
              onStrokeDrawn: (stroke) => capturedStrokes.add(stroke),
            ),
          ),
        ),
      );

      // First gesture
      final gesture1 = await tester.startGesture(const Offset(100, 100));
      await gesture1.up();
      await tester.pump();

      // Second gesture after first completes
      final gesture2 = await tester.startGesture(const Offset(200, 200));
      await gesture2.up();
      await tester.pump();

      // Both gestures should create strokes
      expect(capturedStrokes.length, 2);
      expect(capturedStrokes[0].points.first, const Offset(100, 100));
      expect(capturedStrokes[1].points.first, const Offset(200, 200));
    });

    testWidgets('should support palm rejection with onStrokeStarted',
        (tester) async {
      final capturedStrokes = <Stroke>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Draw(
              strokes: const [],
              onStrokeDrawn: (stroke) => capturedStrokes.add(stroke),
              onStrokeStarted: (newStroke, currentStroke) {
                // Palm rejection: continue stylus, ignore touch
                if (currentStroke?.deviceKind == PointerDeviceKind.stylus) {
                  return currentStroke;
                }
                if (currentStroke?.deviceKind == PointerDeviceKind.touch &&
                    newStroke.deviceKind == PointerDeviceKind.stylus) {
                  return newStroke;
                }
                return currentStroke ?? newStroke;
              },
            ),
          ),
        ),
      );

      // Start with stylus
      final stylusGesture = await tester.startGesture(
        const Offset(100, 100),
        kind: PointerDeviceKind.stylus,
      );
      await stylusGesture.moveTo(const Offset(150, 150));
      await tester.pump();

      // Touch screen while stylus is active (palm)
      final touchGesture = await tester.startGesture(
        const Offset(200, 200),
        kind: PointerDeviceKind.touch,
      );
      await touchGesture.up();
      await tester.pump();

      // Complete stylus gesture
      await stylusGesture.up();
      await tester.pump();

      // Should only have one stroke (stylus)
      expect(capturedStrokes.length, 1);
      expect(capturedStrokes[0].deviceKind, PointerDeviceKind.stylus);
      expect(capturedStrokes[0].points.length, 2);
    });
  });

  group('Draw widget - Erasing behavior tests', () {
    testWidgets('should remove intersecting strokes with stroke erasing',
        (tester) async {
      final strokes = <Stroke>[];
      final removedStrokes = <Stroke>[];

      // Helper to rebuild widget with current strokes
      Future<void> buildWidget() async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Draw(
                strokes: strokes,
                erasingBehavior: ErasingBehavior.stroke,
                onStrokeDrawn: (stroke) => strokes.add(stroke),
                onStrokesRemoved: (removed) => removedStrokes.addAll(removed),
              ),
            ),
          ),
        );
      }

      await buildWidget();

      // Draw a horizontal stroke (normal)
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Draw(
              strokes: strokes,
              erasingBehavior: ErasingBehavior.none, // Normal drawing
              onStrokeDrawn: (stroke) => strokes.add(stroke),
            ),
          ),
        ),
      );

      final normalGesture = await tester.startGesture(const Offset(100, 150));
      await normalGesture.moveTo(const Offset(200, 150));
      await normalGesture.up();
      await tester.pump();

      expect(strokes.length, 1);

      // Draw an erasing stroke that intersects
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Draw(
              strokes: strokes,
              erasingBehavior: ErasingBehavior.stroke, // Erasing mode
              onStrokeDrawn: (stroke) => strokes.add(stroke),
              onStrokesRemoved: (removed) => removedStrokes.addAll(removed),
            ),
          ),
        ),
      );

      final eraseGesture = await tester.startGesture(const Offset(150, 100));
      await eraseGesture.moveTo(const Offset(150, 200));
      await eraseGesture.up();
      await tester.pump();

      // Should have detected intersection
      expect(removedStrokes.isNotEmpty, true);
    });

    testWidgets('should set erasingBehavior from widget property',
        (tester) async {
      Stroke? capturedStroke;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Draw(
              strokes: const [],
              erasingBehavior: ErasingBehavior.pixel,
              onStrokeDrawn: (stroke) => capturedStroke = stroke,
            ),
          ),
        ),
      );

      final gesture = await tester.startGesture(const Offset(100, 100));
      await gesture.up();
      await tester.pump();

      expect(capturedStroke, isNotNull);
      expect(capturedStroke!.erasingBehavior, ErasingBehavior.pixel);
    });

    testWidgets('should change erasingBehavior in onStrokeStarted',
        (tester) async {
      Stroke? capturedStroke;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Draw(
              strokes: const [],
              erasingBehavior: ErasingBehavior.none,
              onStrokeDrawn: (stroke) => capturedStroke = stroke,
              onStrokeStarted: (newStroke, currentStroke) {
                if (currentStroke != null) {
                  return currentStroke;
                }
                // Change to erasing for touch input
                if (newStroke.deviceKind == PointerDeviceKind.touch) {
                  return newStroke.copyWith(
                    erasingBehavior: ErasingBehavior.stroke,
                  );
                }
                return newStroke;
              },
            ),
          ),
        ),
      );

      final gesture = await tester.startGesture(
        const Offset(100, 100),
        kind: PointerDeviceKind.touch,
      );
      await gesture.up();
      await tester.pump();

      expect(capturedStroke, isNotNull);
      expect(capturedStroke!.erasingBehavior, ErasingBehavior.stroke);
    });
  });

  group('Draw widget - PointerCancel tests', () {
    testWidgets('should complete stroke on pointer cancel', (tester) async {
      Stroke? capturedStroke;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Draw(
              strokes: const [],
              onStrokeDrawn: (stroke) => capturedStroke = stroke,
            ),
          ),
        ),
      );

      final gesture = await tester.startGesture(const Offset(100, 100));
      await gesture.moveTo(const Offset(150, 150));

      // Simulate pointer cancel
      await gesture.cancel();
      await tester.pump();

      expect(capturedStroke, isNotNull);
      expect(capturedStroke!.points.length, 2);
    });

    testWidgets(
        'should ignore pointer cancel from inactive pointer',
        (tester) async {
      Stroke? capturedStroke;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Draw(
              strokes: const [],
              onStrokeDrawn: (stroke) => capturedStroke = stroke,
            ),
          ),
        ),
      );

      // Start first gesture
      final gesture1 = await tester.startGesture(const Offset(100, 100));
      await tester.pump();

      // Start and cancel second gesture (should be ignored)
      final gesture2 = await tester.startGesture(const Offset(200, 200));
      await gesture2.cancel();
      await tester.pump();

      expect(capturedStroke, isNull); // No stroke completed yet

      // Complete first gesture
      await gesture1.up();
      await tester.pump();

      expect(capturedStroke, isNotNull);
      expect(capturedStroke!.points.first, const Offset(100, 100));
    });
  });

  group('Draw widget - Edge cases', () {
    testWidgets('should handle rapid successive strokes', (tester) async {
      final capturedStrokes = <Stroke>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Draw(
              strokes: const [],
              onStrokeDrawn: (stroke) => capturedStrokes.add(stroke),
            ),
          ),
        ),
      );

      // Draw three quick strokes
      for (int i = 0; i < 3; i++) {
        final gesture = await tester.startGesture(Offset(100.0 + i * 50, 100));
        await gesture.moveTo(Offset(150.0 + i * 50, 150));
        await gesture.up();
        await tester.pump();
      }

      expect(capturedStrokes.length, 3);
    });

    testWidgets('should not call onStrokeUpdated when callback is null',
        (tester) async {
      Stroke? capturedStroke;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Draw(
              strokes: const [],
              onStrokeDrawn: (stroke) => capturedStroke = stroke,
              // onStrokeUpdated not provided
            ),
          ),
        ),
      );

      final gesture = await tester.startGesture(const Offset(100, 100));
      await gesture.moveTo(const Offset(150, 150));
      await gesture.moveTo(const Offset(200, 200));
      await gesture.up();
      await tester.pump();

      // Should still complete normally
      expect(capturedStroke, isNotNull);
      expect(capturedStroke!.points.length, 3);
    });

    testWidgets('should preserve stroke metadata through drawing',
        (tester) async {
      Stroke? capturedStroke;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Draw(
              strokes: const [],
              strokeColor: Colors.purple,
              strokeWidth: 15.0,
              erasingBehavior: ErasingBehavior.pixel,
              onStrokeDrawn: (stroke) => capturedStroke = stroke,
            ),
          ),
        ),
      );

      final gesture = await tester.startGesture(const Offset(100, 100));
      await gesture.moveTo(const Offset(150, 150));
      await gesture.moveTo(const Offset(200, 200));
      await gesture.up();
      await tester.pump();

      expect(capturedStroke, isNotNull);
      expect(capturedStroke!.color, Colors.purple);
      expect(capturedStroke!.width, 15.0);
      expect(capturedStroke!.erasingBehavior, ErasingBehavior.pixel);
      expect(capturedStroke!.points.length, 3);
    });
  });
}
