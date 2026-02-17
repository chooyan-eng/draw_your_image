import 'package:draw_your_image/src/intersection_detection.dart';
import 'package:draw_your_image/src/path_builder.dart';
import 'package:draw_your_image/src/stroke.dart';
import 'package:draw_your_image/src/stroke_painter.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// A widget representing a canvas for drawing.
class Draw extends StatefulWidget {
  /// List of strokes to be drawn on the canvas.
  final List<Stroke> strokes;

  /// Callback called when one stroke is completed.
  final ValueChanged<Stroke> onStrokeDrawn;

  /// Callback called when strokes are selected.
  /// This callback is called only when [intersectionDetector] is provided.
  final ValueChanged<List<Stroke>>? onStrokesSelected;

  /// Callback called when a new stroke is started.
  /// If null, drawing always starts with a default configuration.
  /// If provided, [Draw] will start a new stroke with the returned [Stroke] configuration.
  /// If returned value is null, the new stroke will be canceled.
  ///
  /// If another stroke is already ongoing, the stroke is given as [currentStroke]
  /// Because [Draw] only supports single touch drawing, you have to choose
  /// which stroke to continue by returning either [newStroke] or [currentStroke],
  /// or none of them, meaning to cancel both.
  final Stroke? Function(Stroke newStroke, Stroke? currentStroke)?
  onStrokeStarted;

  /// Callback called when the current stroke is updated (typically, when a point is added).
  /// The current stroke is passed as an argument.
  /// The return value will overwrite the currently drawing stroke.
  /// If null is returned, the stroke will be canceled at that point.
  final Stroke? Function(Stroke currentStroke)? onStrokeUpdated;

  /// [Color] for background of canvas.
  final Color backgroundColor;

  /// [Color] of strokes as an initial configuration.
  final Color strokeColor;

  /// Width of strokes
  final double strokeWidth;

  /// Function to build [Path] from stroke points.
  /// This function is typically for applying smoothing algorithms or pressure-sensitive effects.
  /// Defaults to Catmull-Rom spline interpolation.
  final PathBuilder? pathBuilder;

  /// Custom painter function for [Path] built by [pathBuilder].
  /// If provided, this function will be used to paint each stroke
  /// instead of the default painting logic.
  /// You can return multiple [Paint] objects for the given [Stroke],
  /// which enables more complex painting effects.
  final StrokePainter? strokePainter;

  /// Function to detect intersecting strokes.
  /// Defaults to segment distance based detection.
  /// This is used when [onStrokesSelected] is provided.
  final IntersectionDetector? intersectionDetector;

  /// Function to determine whether to absorb pan/zoom pointer events.
  /// This is useful when using [Draw] inside an [InteractiveViewer] and
  /// you want to disable pan/zoom while drawing and enable it otherwise.
  ///
  /// When the function returns true for a pointer down event,
  /// the pointer event will be absorbed by [Draw], preventing
  /// it from being passed to parent widgets like [InteractiveViewer].
  final bool Function(PointerDownEvent event)? shouldAbsorb;

  const Draw({
    super.key,
    required this.strokes,
    required this.onStrokeDrawn,
    this.onStrokesSelected,
    this.onStrokeStarted,
    this.onStrokeUpdated,
    this.backgroundColor = Colors.white,
    this.strokeColor = Colors.black,
    this.strokeWidth = 4,
    this.pathBuilder,
    this.strokePainter,
    this.intersectionDetector,
    this.shouldAbsorb,
  });

  @override
  _DrawState createState() => _DrawState();
}

class _DrawState extends State<Draw> {
  /// currently drawing stroke
  Stroke? _currentStroke;

  /// pointer id being used for drawing
  /// [Draw] only supports single touch drawing
  int? _activePointerId;

  /// start drawing
  void _start(PointerDownEvent event) {
    final newStroke = Stroke(
      deviceKind: event.kind,
      points: [
        StrokePoint(
          position: event.localPosition,
          pressure: event.pressure,
          pressureMin: event.pressureMin,
          pressureMax: event.pressureMax,
          tilt: event.tilt,
          orientation: event.orientation,
        ),
      ],
      color: widget.strokeColor,
      width: widget.strokeWidth,
    );

    final effectiveStroke = switch (widget.onStrokeStarted) {
      // if onStrokeStarted null, _currentStroke has priority
      null => _currentStroke ?? newStroke,
      // if provided, respect the result of the callback
      final callback => callback(newStroke, _currentStroke),
    };

    if (_currentStroke != effectiveStroke) {
      _activePointerId = event.pointer;
    }

    setState(() => _currentStroke = effectiveStroke);
  }

  /// add point when drawing is ongoing
  void _add(PointerMoveEvent event) {
    if (_currentStroke != null) {
      setState(() {
        _currentStroke!.points.add(
          StrokePoint(
            position: event.localPosition,
            pressure: event.pressure,
            pressureMin: event.pressureMin,
            pressureMax: event.pressureMax,
            tilt: event.tilt,
            orientation: event.orientation,
          ),
        );

        // Call onStrokeUpdated only if it is set
        if (widget.onStrokeUpdated != null) {
          _currentStroke = widget.onStrokeUpdated!(_currentStroke!);
        }
      });
    }
  }

  /// complete drawing
  void _complete() {
    if (_currentStroke != null) {
      widget.onStrokeDrawn(_currentStroke!);

      setState(() => _currentStroke = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final converter =
        widget.pathBuilder ?? PathBuilderMode.catmullRom.converter;
    final strokePainter = widget.strokePainter ?? defaultStrokePainter;

    /// strokes to paint (including currently drawing stroke)
    final strokesToPaint = [...widget.strokes, ?_currentStroke];

    return SizedBox.expand(
      child: RawGestureDetector(
        gestures: widget.shouldAbsorb != null
            ? {
                _AbsorbableScaleGestureRecognizer:
                    GestureRecognizerFactoryWithHandlers<
                      _AbsorbableScaleGestureRecognizer
                    >(
                      () => _AbsorbableScaleGestureRecognizer(
                        shouldAbsorb: widget.shouldAbsorb!,
                      ),
                      (instance) {
                        instance.shouldAbsorb = widget.shouldAbsorb!;
                      },
                    ),
              }
            : const {},
        child: Listener(
          onPointerDown: _start,
          onPointerMove: (event) {
            if (event.pointer != _activePointerId) {
              return;
            }

            _add(event);

            if (widget.onStrokesSelected != null &&
                widget.intersectionDetector != null) {
              final removedStrokes = widget.intersectionDetector!(
                widget.strokes,
                _currentStroke!,
              );
              if (removedStrokes.isNotEmpty) {
                widget.onStrokesSelected!(removedStrokes);
              }
            }
          },
          onPointerUp: (event) {
            if (_activePointerId != event.pointer) return;
            _activePointerId = null;
            _complete();
          },
          onPointerCancel: (event) {
            if (_activePointerId != event.pointer) return;
            _activePointerId = null;
            _complete();
          },
          child: CustomPaint(
            painter: _FreehandPainter(
              strokesToPaint,
              widget.backgroundColor,
              converter,
              strokePainter,
            ),
          ),
        ),
      ),
    );
  }
}

class _AbsorbableScaleGestureRecognizer extends ScaleGestureRecognizer {
  _AbsorbableScaleGestureRecognizer({required this.shouldAbsorb});

  bool Function(PointerDownEvent event) shouldAbsorb;

  @override
  void addPointer(PointerDownEvent event) {
    if (shouldAbsorb(event)) {
      super.addPointer(event);
    }
  }
}

/// Subclass of [CustomPainter] to paint strokes
class _FreehandPainter extends CustomPainter {
  final List<Stroke> strokes;
  final Color backgroundColor;
  final Path Function(Stroke) pathConverter;
  final StrokePainter strokePainter;

  _FreehandPainter(
    this.strokes,
    this.backgroundColor,
    this.pathConverter,
    this.strokePainter,
  );

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = backgroundColor,
    );

    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());
    for (final stroke in strokes) {
      // Convert stroke points to Path
      final path = pathConverter(stroke);

      final painter = strokePainter(stroke);
      for (final paint in painter) {
        canvas.drawPath(path, paint);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return strokes != (oldDelegate as _FreehandPainter).strokes ||
        pathConverter != oldDelegate.pathConverter ||
        strokePainter != oldDelegate.strokePainter ||
        backgroundColor != oldDelegate.backgroundColor;
  }
}
