part of draw_your_image;

class Draw extends StatefulWidget {
  @override
  _DrawState createState() => _DrawState();
}

class _DrawState extends State<Draw> {
  var _currentColor = Colors.black;
  var _currentWidth = 4.0;

  final _strokes = <Stroke>[];

  late Size _canvasSize;

  void _start(double startX, double startY) {
    _strokes.add(
      Stroke(
        color: _currentColor,
        width: _currentWidth,
      ),
    );
    _strokes.last.path.moveTo(startX, startY);
  }

  void _add(double x, double y) {
    setState(() {
      _strokes.last.path.lineTo(x, y);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: double.infinity,
      width: double.infinity,
      child: GestureDetector(
        onPanStart: (details) => _start(
          details.localPosition.dx,
          details.localPosition.dy,
        ),
        onPanUpdate: (details) {
          _add(
            details.localPosition.dx,
            details.localPosition.dy,
          );
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            _canvasSize = Size(constraints.maxWidth, constraints.maxHeight);
            return CustomPaint(
              painter: FreehandPainter(_strokes),
            );
          },
        ),
      ),
    );
  }
}

class FreehandPainter extends CustomPainter {
  final List<Stroke> strokes;

  FreehandPainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.white,
    );
    for (final stroke in strokes) {
      final paint = Paint()
        ..strokeWidth = stroke.width
        ..color = stroke.color
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      canvas.drawPath(stroke.path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class Stroke {
  final path = Path();
  final Color color;
  final double width;

  Stroke({
    this.color = Colors.black,
    this.width = 4,
  });
}
