import 'package:draw_your_image/src/intersection_detection.dart';
import 'package:draw_your_image/src/smoothing.dart';
import 'package:draw_your_image/src/stroke.dart';
import 'package:flutter/material.dart';

/// A widget representing a canvas for drawing.
class Draw extends StatefulWidget {
  /// List of strokes to be drawn on the canvas.
  final List<Stroke> strokes;

  /// Callback called when one stroke is completed.
  final ValueChanged<Stroke> onStrokeDrawn;

  /// Callback called when strokes are removed by erasing.
  final ValueChanged<List<Stroke>>? onStrokesRemoved;

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

  /// [Color] for background of canvas.
  final Color backgroundColor;

  /// [Color] of strokes as an initial configuration.
  final Color strokeColor;

  /// Width of strokes
  final double strokeWidth;

  /// Erasing behavior for drawing
  final ErasingBehavior erasingBehavior;

  /// Function to convert stroke points to Path.
  /// Defaults to Catmull-Rom spline interpolation.
  final SmoothingFunc? smoothingFunc;

  /// Function to detect intersecting strokes.
  /// Defaults to segment distance based detection.
  /// This is used when [isErasing] is true to detect which strokes
  /// should be removed by the erasing stroke.
  final IntersectionDetector? intersectionDetector;

  const Draw({
    super.key,
    required this.strokes,
    required this.onStrokeDrawn,
    this.onStrokesRemoved,
    this.onStrokeStarted,
    this.backgroundColor = Colors.white,
    this.strokeColor = Colors.black,
    this.strokeWidth = 4,
    this.erasingBehavior = ErasingBehavior.none,
    this.smoothingFunc,
    this.intersectionDetector,
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

  /// strokes removed by erasing within one removing stroke
  List<Stroke> _removedStrokes = [];

  /// start drawing
  void _start(PointerDownEvent event) {
    final newStroke = Stroke(
      deviceKind: event.kind,
      points: [event.localPosition],
      color: widget.strokeColor,
      width: widget.strokeWidth,
      erasingBehavior: widget.erasingBehavior,
    );

    final effectiveStroke =
        widget.onStrokeStarted?.call(newStroke, _currentStroke) ??
        _currentStroke;

    if (_currentStroke != effectiveStroke) {
      _activePointerId = event.pointer;
    }

    setState(() {
      _currentStroke = effectiveStroke;
    });
  }

  /// add point when drawing is ongoing
  void _add(double x, double y) {
    if (_currentStroke != null) {
      setState(() => _currentStroke!.points.add(Offset(x, y)));
    }
  }

  /// complete drawing
  void _complete() {
    if (_currentStroke != null) {
      widget.onStrokeDrawn(_currentStroke!);

      setState(() => _currentStroke = null);
      _removedStrokes.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final converter =
        widget.smoothingFunc ?? SmoothingMode.catmullRom.converter;
    final detector =
        widget.intersectionDetector ??
        IntersectionMode.segmentDistance.detector;

    /// strokes to paint (including currently drawing stroke)
    final strokesToPaint = [...widget.strokes, ?_currentStroke];

    return SizedBox.expand(
      child: Listener(
        onPointerDown: _start,
        onPointerMove: (event) {
          if (event.pointer != _activePointerId) {
            return;
          }

          _add(event.localPosition.dx, event.localPosition.dy);

          if (_currentStroke?.erasingBehavior == ErasingBehavior.stroke) {
            final removedStrokes = detector(
              widget.strokes
                  .where((stroke) => !_removedStrokes.contains(stroke))
                  .toList(),
              _currentStroke!,
            );
            if (removedStrokes.isNotEmpty && widget.onStrokesRemoved != null) {
              widget.onStrokesRemoved!(removedStrokes);
              _removedStrokes.addAll(removedStrokes);
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
            strokesToPaint.where((stroke) => stroke.shouldPaint).toList(),
            widget.backgroundColor,
            converter,
          ),
        ),
      ),
    );
  }
}

/// Subclass of [CustomPainter] to paint strokes
class _FreehandPainter extends CustomPainter {
  final List<Stroke> strokes;
  final Color backgroundColor;
  final Path Function(Stroke) pathConverter;

  _FreehandPainter(this.strokes, this.backgroundColor, this.pathConverter);

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

      final paint = Paint()
        ..strokeWidth = stroke.width
        ..color = stroke.erasingBehavior == ErasingBehavior.pixel
            ? Colors.transparent
            : stroke.color
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke
        ..blendMode = stroke.erasingBehavior == ErasingBehavior.pixel
            ? BlendMode.clear
            : BlendMode.srcOver;
      canvas.drawPath(path, paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return strokes != (oldDelegate as _FreehandPainter).strokes ||
        pathConverter != oldDelegate.pathConverter ||
        backgroundColor != oldDelegate.backgroundColor;
  }
}
