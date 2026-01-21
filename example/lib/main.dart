import 'dart:ui';
import 'package:draw_your_image/draw_your_image.dart';
import 'package:flutter/material.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'draw_your_image Demo', home: MyHomePage());
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

/// Type definition for local state for undo/redo functionality
typedef StrokeState = List<Stroke>;

class _MyHomePageState extends State<MyHomePage> {
  var _strokes = <Stroke>[];

  /// Undo and redo stacks.
  /// Undo/redo is implemented by saving the list of states.
  var _undoStack = <StrokeState>[];
  var _redoStack = <StrokeState>[];

  PointerDeviceKind? _currentDevice;
  PointerDeviceKind? _visibleDevice;
  ErasingBehavior _erasingBehavior = ErasingBehavior.none;

  bool get _canUndo => _undoStack.isNotEmpty;
  bool get _canRedo => _redoStack.isNotEmpty;
  bool get _isDrawing => _currentDevice != null;

  void _clear() {
    setState(() {
      _strokes = [];
      _undoStack = [];
      _redoStack = [];
    });
  }

  void _undo() {
    setState(() {
      /// save current state to redo stack
      _redoStack.add(List.from(_strokes));

      /// restore last state from undo stack
      _strokes = _undoStack.removeLast();
    });
  }

  void _redo() {
    setState(() {
      /// save current state to undo stack
      _undoStack.add(List.from(_strokes));

      /// restore last state from redo stack
      _strokes = _redoStack.removeLast();
    });
  }

  MaterialColor get _deviceColor =>
      _currentDevice == PointerDeviceKind.stylus ? Colors.blue : Colors.green;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('draw_your_image Demo')),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Show Strokes From:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  spacing: 16,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FilterChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit, size: 32),
                          SizedBox(width: 8),
                          Text('Stylus', style: TextStyle(fontSize: 24)),
                        ],
                      ),
                      selected: _visibleDevice == PointerDeviceKind.stylus,
                      onSelected: (selected) {
                        setState(
                          () => _visibleDevice = selected
                              ? PointerDeviceKind.stylus
                              : null,
                        );
                      },
                    ),
                    FilterChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.touch_app, size: 32),
                          SizedBox(width: 8),
                          Text('Finger', style: TextStyle(fontSize: 24)),
                        ],
                      ),
                      selected: _visibleDevice == PointerDeviceKind.touch,
                      onSelected: (selected) {
                        setState(
                          () => _visibleDevice = selected
                              ? PointerDeviceKind.touch
                              : null,
                        );
                      },
                    ),
                    FilterChip(
                      label: Text('All', style: TextStyle(fontSize: 24)),
                      selected: _visibleDevice == null,
                      onSelected: (selected) {
                        setState(() => _visibleDevice = null);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Drawing area
          Expanded(
            child: Container(
              margin: EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: InteractiveViewer(
                      scaleEnabled: !_isDrawing,
                      panEnabled: !_isDrawing,
                      child: Draw(
                        strokes: _strokes
                            .map(
                              (stroke) =>
                                  (stroke.deviceKind == _visibleDevice ||
                                      _visibleDevice == null)
                                  ? stroke
                                  : stroke.copyWith(color: Colors.grey[200]!),
                            )
                            .toList(),
                        strokeColor: Colors.black,
                        strokeWidth: 4.0,
                        backgroundColor: Colors.white,
                        erasingBehavior: _erasingBehavior,
                        onStrokeDrawn: (stroke) {
                          setState(() => _currentDevice = null);
                          if (stroke.shouldPaint) {
                            setState(() {
                              _undoStack.add(List.from(_strokes));
                              _strokes = [..._strokes, stroke];
                              _redoStack = [];
                            });
                          }
                        },
                        onStrokeStarted: (newStroke, currentStroke) {
                          if (currentStroke != null) {
                            return currentStroke;
                          }
                          setState(() => _currentDevice = newStroke.deviceKind);
                          return newStroke.copyWith(
                            color:
                                newStroke.deviceKind == PointerDeviceKind.stylus
                                ? Colors.blue
                                : Colors.green,
                            width:
                                newStroke.deviceKind == PointerDeviceKind.stylus
                                ? 4.0
                                : 8.0,
                          );
                        },
                        onStrokesRemoved: (value) {
                          setState(() {
                            /// save current state to undo stack
                            _undoStack.add(List.from(_strokes));

                            /// clear redo stack
                            _redoStack = [];
                            _strokes = _strokes
                                .where((stroke) => !value.contains(stroke))
                                .toList();
                          });
                        },
                      ),
                    ),
                  ),
                  if (_currentDevice != null)
                    Positioned(
                      top: 16,
                      left: 0,
                      right: 0,
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _deviceColor[50],
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: _deviceColor[200]!),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _currentDevice == PointerDeviceKind.stylus
                                    ? Icons.edit
                                    : Icons.touch_app,
                                size: 32,
                                color: _deviceColor[700],
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Drawing with ${_currentDevice == PointerDeviceKind.stylus ? "Stylus" : "Finger"}...',
                                style: TextStyle(
                                  fontSize: 24,
                                  color: _deviceColor[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Control buttons
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Column(
              children: [
                // Eraser mode toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: FilterChip(
                        label: Text('Draw'),
                        selected: _erasingBehavior == ErasingBehavior.none,
                        onSelected: (_) {
                          setState(
                            () => _erasingBehavior = ErasingBehavior.none,
                          );
                        },
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: FilterChip(
                        label: Text('Erase Pixel'),
                        selected: _erasingBehavior == ErasingBehavior.pixel,
                        onSelected: (_) {
                          setState(
                            () => _erasingBehavior = ErasingBehavior.pixel,
                          );
                        },
                        selectedColor: Colors.orange[100],
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: FilterChip(
                        label: Text('Erase Stroke'),
                        selected: _erasingBehavior == ErasingBehavior.stroke,
                        onSelected: (_) {
                          setState(
                            () => _erasingBehavior = ErasingBehavior.stroke,
                          );
                        },
                        selectedColor: Colors.red[100],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: Icon(Icons.undo),
                        label: Text('Undo'),
                        onPressed: _canUndo ? _undo : null,
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: Icon(Icons.redo),
                        label: Text('Redo'),
                        onPressed: _canRedo ? _redo : null,
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: Icon(Icons.clear),
                        label: Text('Clear'),
                        onPressed: _strokes.isEmpty ? null : _clear,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[50],
                          foregroundColor: Colors.red[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
