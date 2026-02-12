import 'package:flutter/material.dart';
import 'package:draw_your_image/draw_your_image.dart';
import '../widgets/color_picker.dart';
import '../widgets/stroke_width_slider.dart';
import '../widgets/demo_toolbar.dart';
import '../utils/undo_redo_manager.dart';
import '../utils/point_in_polygon.dart';
import '../constants/demo_colors.dart';

/// Edit mode
enum EditMode {
  drawing('Drawing Mode'),
  selecting('Selection Mode');

  const EditMode(this.label);
  final String label;
}

/// Selection method
enum SelectionMethod {
  tap('Tap Selection'),
  lasso('Lasso Selection');

  const SelectionMethod(this.label);
  final String label;
}

/// Stroke Selection and Editing Page
///
/// Demo of stroke editing features after drawing.
class StrokeEditingPage extends StatefulWidget {
  const StrokeEditingPage({super.key});

  @override
  State<StrokeEditingPage> createState() => _StrokeEditingPageState();
}

class _StrokeEditingPageState extends State<StrokeEditingPage> {
  List<Stroke> _strokes = [];
  EditMode _mode = EditMode.drawing;
  SelectionMethod _selectionMethod = SelectionMethod.tap;
  Set<int> _selectedIndices = {};
  final UndoRedoManager _undoRedoManager = UndoRedoManager();

  // For lasso selection
  List<Offset> _lassoPoints = [];
  bool _isDrawingLasso = false;

  // Editing settings
  Color _currentColor = Colors.black;
  double _currentWidth = 4.0;

  /// Select stroke close to tap position
  void _selectStrokeAt(Offset position) {
    double minDistance = double.infinity;
    int? closestIndex;

    for (int i = 0; i < _strokes.length; i++) {
      for (final point in _strokes[i].points) {
        final distance = (point.position - position).distance;
        if (distance < minDistance && distance < 20.0) {
          minDistance = distance;
          closestIndex = i;
        }
      }
    }

    if (closestIndex != null) {
      final index = closestIndex;
      setState(() {
        if (_selectedIndices.contains(index)) {
          _selectedIndices.remove(index);
        } else {
          _selectedIndices.add(index);
        }
      });
    }
  }

  /// Start lasso selection
  void _startLassoSelection(Offset position) {
    setState(() {
      _isDrawingLasso = true;
      _lassoPoints = [position];
    });
  }

  /// Update lasso selection
  void _updateLassoSelection(Offset position) {
    if (_isDrawingLasso) {
      setState(() {
        _lassoPoints.add(position);
      });
    }
  }

  /// Complete lasso selection
  void _completeLassoSelection() {
    if (_lassoPoints.length > 2) {
      // Select strokes within lasso
      final selectedIndices = <int>{};
      for (int i = 0; i < _strokes.length; i++) {
        final strokePositions = _strokes[i].points
            .map((p) => p.position)
            .toList();
        if (isStrokeInPolygon(strokePositions, _lassoPoints)) {
          selectedIndices.add(i);
        }
      }
      setState(() {
        _selectedIndices = selectedIndices;
      });
    }
    setState(() {
      _isDrawingLasso = false;
      _lassoPoints = [];
    });
  }

  /// Change color of selected strokes
  void _changeSelectedColor(Color color) {
    if (_selectedIndices.isEmpty) return;

    _undoRedoManager.saveState(_strokes);
    setState(() {
      _strokes = _strokes.asMap().entries.map((entry) {
        if (_selectedIndices.contains(entry.key)) {
          return entry.value.copyWith(color: color);
        }
        return entry.value;
      }).toList();
    });
  }

  /// Change width of selected strokes
  void _changeSelectedWidth(double width) {
    if (_selectedIndices.isEmpty) return;

    _undoRedoManager.saveState(_strokes);
    setState(() {
      _strokes = _strokes.asMap().entries.map((entry) {
        if (_selectedIndices.contains(entry.key)) {
          return entry.value.copyWith(width: width);
        }
        return entry.value;
      }).toList();
    });
  }

  /// Delete selected strokes
  void _deleteSelected() {
    if (_selectedIndices.isEmpty) return;

    _undoRedoManager.saveState(_strokes);
    setState(() {
      _strokes = _strokes
          .asMap()
          .entries
          .where((entry) => !_selectedIndices.contains(entry.key))
          .map((entry) => entry.value)
          .toList();
      _selectedIndices = {};
    });
  }

  /// Get list of strokes for display (selected strokes are highlighted)
  List<Stroke> _getDisplayStrokes() {
    return _strokes.asMap().entries.map((entry) {
      if (_selectedIndices.contains(entry.key)) {
        return entry.value.copyWith(color: DemoColors.selectionHighlight);
      }
      return entry.value;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stroke Editing'),
        actions: [
          // Mode toggle
          SegmentedButton<EditMode>(
            segments: EditMode.values.map((mode) {
              return ButtonSegment(value: mode, label: Text(mode.label));
            }).toList(),
            selected: {_mode},
            onSelectionChanged: (Set<EditMode> selected) {
              setState(() {
                _mode = selected.first;
                _selectedIndices = {};
              });
            },
          ),
          const SizedBox(width: 8),
          DemoToolbar(
            onUndo: () =>
                setState(() => _strokes = _undoRedoManager.undo(_strokes)),
            onRedo: () =>
                setState(() => _strokes = _undoRedoManager.redo(_strokes)),
            canUndo: _undoRedoManager.canUndo,
            canRedo: _undoRedoManager.canRedo,
          ),
        ],
      ),
      body: Column(
        children: [
          // Canvas
          Expanded(
            child: GestureDetector(
              onTapUp:
                  _mode == EditMode.selecting &&
                      _selectionMethod == SelectionMethod.tap
                  ? (details) => _selectStrokeAt(details.localPosition)
                  : null,
              onPanStart:
                  _mode == EditMode.selecting &&
                      _selectionMethod == SelectionMethod.lasso
                  ? (details) => _startLassoSelection(details.localPosition)
                  : null,
              onPanUpdate:
                  _mode == EditMode.selecting &&
                      _selectionMethod == SelectionMethod.lasso
                  ? (details) => _updateLassoSelection(details.localPosition)
                  : null,
              onPanEnd:
                  _mode == EditMode.selecting &&
                      _selectionMethod == SelectionMethod.lasso
                  ? (_) => _completeLassoSelection()
                  : null,
              child: Stack(
                children: [
                  Draw(
                    strokes: _getDisplayStrokes(),
                    strokeColor: _currentColor,
                    strokeWidth: _currentWidth,
                    backgroundColor: DemoColors.canvasBackground,
                    onStrokeDrawn: (stroke) {
                      if (_mode == EditMode.drawing) {
                        _undoRedoManager.saveState(_strokes);
                        setState(() => _strokes = [..._strokes, stroke]);
                      }
                    },
                    onStrokeStarted: _mode == EditMode.selecting
                        ? (_, __) =>
                              null // Do not draw in selection mode
                        : null,
                  ),
                  // Display lasso line
                  if (_isDrawingLasso && _lassoPoints.length > 1)
                    CustomPaint(
                      painter: _LassoPainter(_lassoPoints),
                      size: Size.infinite,
                    ),
                ],
              ),
            ),
          ),
          // Toolbar
          if (_mode == EditMode.selecting && _selectedIndices.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: DemoColors.toolbarBackground,
                border: Border(top: BorderSide(color: Colors.grey, width: 0.5)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${_selectedIndices.length} stroke(s) selected'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('Color: '),
                      const SizedBox(width: 8),
                      ColorPicker(
                        selectedColor: _currentColor,
                        onColorChanged: _changeSelectedColor,
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: _deleteSelected,
                        tooltip: 'Delete',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('Width: '),
                      const SizedBox(width: 8),
                      Expanded(
                        child: StrokeWidthSlider(
                          width: _currentWidth,
                          onWidthChanged: (width) {
                            setState(() => _currentWidth = width);
                            _changeSelectedWidth(width);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          // Selection method toggle when in selection mode
          if (_mode == EditMode.selecting && _selectedIndices.isEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: DemoColors.toolbarBackground,
                border: Border(top: BorderSide(color: Colors.grey, width: 0.5)),
              ),
              child: Row(
                children: [
                  const Text('Selection Method: '),
                  const SizedBox(width: 8),
                  SegmentedButton<SelectionMethod>(
                    segments: SelectionMethod.values.map((method) {
                      return ButtonSegment(
                        value: method,
                        label: Text(method.label),
                      );
                    }).toList(),
                    selected: {_selectionMethod},
                    onSelectionChanged: (Set<SelectionMethod> selected) {
                      setState(() => _selectionMethod = selected.first);
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// CustomPainter to draw lasso line
class _LassoPainter extends CustomPainter {
  final List<Offset> points;

  _LassoPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final paint = Paint()
      ..color = DemoColors.lassoColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_LassoPainter oldDelegate) {
    return oldDelegate.points.length != points.length;
  }
}
