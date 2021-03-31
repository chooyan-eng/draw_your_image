part of draw_your_image;

typedef HistoryChanged = void Function(
    bool isUndoAvailable, bool isRedoAvailable);

/// A widget representing a canvas for drawing.
class Draw extends StatefulWidget {
  /// A controller to call drawing actions.
  final DrawController? controller;

  /// [Color] for background of canvas.
  final Color backgroundColor;

  /// [Color] of strokes as an initial configuration.
  final Color strokeColor;

  /// Width of strokes
  final double strokeWidth;

  /// Flag for erase mode
  final bool isErasing;

  /// Callback called when [Canvas] is converted to image data.
  /// See [DrawController] to check how to convert.
  final ValueChanged<Uint8List>? onConvert;

  /// Callback called when history is changed.
  /// This callback exposes if undo / redo is available.
  final HistoryChanged? onHistoryChange;

  const Draw({
    Key? key,
    this.controller,
    this.backgroundColor = Colors.white,
    this.strokeColor = Colors.black,
    this.strokeWidth = 4,
    this.isErasing = false,
    this.onConvert,
    this.onHistoryChange,
  }) : super(key: key);

  @override
  _DrawState createState() => _DrawState();
}

class _DrawState extends State<Draw> {
  final _undoHistory = <History>[];
  final _redoStack = <History>[];

  // late Size _canvasSize;
  final _strokes = <_Stroke>[];

  @override
  void initState() {
    widget.controller?._delegate = _DrawControllerDelegate()
      ..onConvertToPng = () {
        // currently do nothing.
      }
      ..onUndo = () {
        if (_undoHistory.isEmpty) return false;

        _redoStack.add(_undoHistory.removeLast()..undo());
        _callHistoryChanged();
        return true;
      }
      ..onRedo = () {
        if (_redoStack.isEmpty) return false;

        _undoHistory.add(_redoStack.removeLast()..redo());
        _callHistoryChanged();
        return true;
      }
      ..onClear = () {
        if (_strokes.isEmpty) return;
        setState(() {
          final _removedStrokes = <_Stroke>[]..addAll(_strokes);
          _undoHistory.add(
            History(
              undo: () {
                setState(() => _strokes.addAll(_removedStrokes));
              },
              redo: () {
                setState(() => _strokes.clear());
              },
            ),
          );
          setState(() {
            _strokes.clear();
            _redoStack.clear();
          });
        });
        _callHistoryChanged();
      };
    super.initState();
  }

  void _callHistoryChanged() {
    widget.onHistoryChange?.call(
      _undoHistory.isNotEmpty,
      _redoStack.isNotEmpty,
    );
  }

  void _start(double startX, double startY) {
    final newStroke = _Stroke(
      color: widget.strokeColor,
      width: widget.strokeWidth,
      erase: widget.isErasing,
    );
    newStroke.path.moveTo(startX, startY);

    _strokes.add(newStroke);
    _undoHistory.add(
      History(
        undo: () {
          setState(() => _strokes.remove(newStroke));
        },
        redo: () {
          setState(() => _strokes.add(newStroke));
        },
      ),
    );
    _redoStack.clear();
    _callHistoryChanged();
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
            // _canvasSize = Size(constraints.maxWidth, constraints.maxHeight);
            return CustomPaint(
              painter: _FreehandPainter(_strokes, widget.backgroundColor),
            );
          },
        ),
      ),
    );
  }
}

/// Subclass of [CustomPainter] to paint strokes
class _FreehandPainter extends CustomPainter {
  final List<_Stroke> strokes;
  final Color backgroundColor;

  _FreehandPainter(
    this.strokes,
    this.backgroundColor,
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
      final paint = Paint()
        ..strokeWidth = stroke.width
        ..color = stroke.erase ? Colors.transparent : stroke.color
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke
        ..blendMode = stroke.erase ? BlendMode.clear : BlendMode.srcOver;
      canvas.drawPath(stroke.path, paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

/// Data class representing strokes
class _Stroke {
  final path = Path();
  final Color color;
  final double width;
  final bool erase;

  _Stroke({
    this.color = Colors.black,
    this.width = 4,
    this.erase = false,
  });
}

class History {
  final VoidCallback undo;
  final VoidCallback redo;

  History({
    required this.undo,
    required this.redo,
  });
}
