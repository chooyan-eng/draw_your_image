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
  final ValueChanged<Uint8List>? onConvertImage;

  /// Callback called when history is changed.
  /// This callback exposes if undo / redo is available.
  final HistoryChanged? onHistoryChange;

  /// Function to convert stroke points to Path.
  /// Defaults to Catmull-Rom spline interpolation.
  final Path Function(Stroke)? pathConverter;

  const Draw({
    Key? key,
    this.controller,
    this.backgroundColor = Colors.white,
    this.strokeColor = Colors.black,
    this.strokeWidth = 4,
    this.isErasing = false,
    this.onConvertImage,
    this.onHistoryChange,
    this.pathConverter,
  }) : super(key: key);

  @override
  _DrawState createState() => _DrawState();
}

class _DrawState extends State<Draw> {
  final _undoHistory = <History>[];
  final _redoStack = <History>[];

  // Strokes stored as point data
  final _strokes = <Stroke>[];

  // cached current canvas size
  late Size _canvasSize;

  // convert current canvas to png image data.
  Future<void> _convertToPng() async {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);

    // Get path converter (use default if not specified)
    final converter =
        widget.pathConverter ?? SmoothingMode.catmullRom.toConverter();

    // Emulate painting using _FreehandPainter
    // recorder will record this painting
    _FreehandPainter(
      _strokes,
      widget.backgroundColor,
      converter,
    ).paint(canvas, _canvasSize);

    // Stop emulating and convert to Image
    final result = await recorder
        .endRecording()
        .toImage(_canvasSize.width.floor(), _canvasSize.height.floor());

    // Cast image data to byte array with converting to png format
    final converted = (await result.toByteData(format: ImageByteFormat.png))!
        .buffer
        .asUint8List();

    // callback
    widget.onConvertImage?.call(converted);
  }

  @override
  void initState() {
    widget.controller?._delegate = _DrawControllerDelegate()
      ..onConvertToImage = _convertToPng
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
          final _removedStrokes = <Stroke>[]..addAll(_strokes);
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
    final newStroke = Stroke(
      points: [Offset(startX, startY)],
      color: widget.strokeColor,
      width: widget.strokeWidth,
      isErasing: widget.isErasing,
    );

    setState(() {
      _strokes.add(newStroke);
    });

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
      // Add point to the last stroke
      _strokes.last.points.add(Offset(x, y));
    });
  }

  @override
  Widget build(BuildContext context) {
    // Get path converter (use default if not specified)
    final converter =
        widget.pathConverter ?? SmoothingMode.catmullRom.toConverter();

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
              painter: _FreehandPainter(
                _strokes,
                widget.backgroundColor,
                converter,
              ),
            );
          },
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

  _FreehandPainter(
    this.strokes,
    this.backgroundColor,
    this.pathConverter,
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
    return true;
  }
}

class History {
  final VoidCallback undo;
  final VoidCallback redo;

  History({
    required this.undo,
    required this.redo,
  });
}
