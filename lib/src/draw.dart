import 'package:draw_your_image/src/smoothing.dart';
import 'package:draw_your_image/src/stroke.dart';
import 'package:flutter/material.dart';

/// A widget representing a canvas for drawing.
class Draw extends StatefulWidget {
  /// List of strokes to be drawn on the canvas.
  final List<Stroke> strokes;

  /// Callback called when one stroke is completed.
  final ValueChanged<Stroke> onStrokeDrawn;

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

  /// Flag for erase mode
  final bool isErasing;

  /// Function to convert stroke points to Path.
  /// Defaults to Catmull-Rom spline interpolation.
  final SmoothingFunc? smoothingFunc;

  const Draw({
    super.key,
    required this.strokes,
    required this.onStrokeDrawn,
    this.onStrokeStarted,
    this.backgroundColor = Colors.white,
    this.strokeColor = Colors.black,
    this.strokeWidth = 4,
    this.isErasing = false,
    this.smoothingFunc,
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
      points: [event.localPosition],
      color: widget.strokeColor,
      width: widget.strokeWidth,
      isErasing: widget.isErasing,
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final converter =
        widget.smoothingFunc ?? SmoothingMode.catmullRom.converter;

    /// strokes to paint (including currently drawing stroke)
    final strokesToPaint = [...widget.strokes, ?_currentStroke];

    return SizedBox.expand(
      child: Listener(
        onPointerDown: _start,
        onPointerMove: (event) {
          if (event.pointer != _activePointerId) return;
          _add(event.localPosition.dx, event.localPosition.dy);
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
        ..color = stroke.isErasing ? Colors.transparent : stroke.color
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke
        ..blendMode = stroke.isErasing ? BlendMode.clear : BlendMode.srcOver;
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
