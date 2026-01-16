part of draw_your_image;

/// A widget representing a canvas for drawing.
class Draw extends StatefulWidget {
  /// List of strokes to be drawn on the canvas.
  final List<Stroke> strokes;

  /// Callback called when one stroke is completed.
  final ValueChanged<Stroke> onStrokeDrawn;

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
  void _start(double startX, double startY) {
    setState(() {
      _currentStroke = Stroke(
        points: [Offset(startX, startY)],
        color: widget.strokeColor,
        width: widget.strokeWidth,
        isErasing: widget.isErasing,
      );
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
        onPointerDown: (event) {
          if (_activePointerId != null) return;
          _activePointerId = event.pointer;
          _start(event.localPosition.dx, event.localPosition.dy);
        },
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
