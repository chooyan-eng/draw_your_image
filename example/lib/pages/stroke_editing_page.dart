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
  bool _isDraggingStroke = false;

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

  /// Returns index of a selected stroke near [position], or null.
  int? _getSelectedStrokeIndexNear(Offset position) {
    for (final i in _selectedIndices) {
      for (final p in _strokes[i].points) {
        if ((p.position - position).distance < 20.0) return i;
      }
    }
    return null;
  }

  /// Creates a copy of [stroke] with all points offset by [delta].
  Stroke _moveStrokeBy(Stroke stroke, Offset delta) {
    return stroke.copyWith(
      points: stroke.points
          .map(
            (p) => StrokePoint(
              position: p.position + delta,
              pressure: p.pressure,
              pressureMin: p.pressureMin,
              pressureMax: p.pressureMax,
              tilt: p.tilt,
              orientation: p.orientation,
            ),
          )
          .toList(),
    );
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
                  _mode == EditMode.selecting && _selectedIndices.isNotEmpty
                  ? (details) {
                      if (_getSelectedStrokeIndexNear(details.localPosition) !=
                          null) {
                        _undoRedoManager.saveState(_strokes);
                        setState(() => _isDraggingStroke = true);
                      }
                    }
                  : null,
              onPanUpdate: _mode == EditMode.selecting && _isDraggingStroke
                  ? (details) {
                      setState(() {
                        _strokes = _strokes.asMap().entries.map((entry) {
                          if (_selectedIndices.contains(entry.key)) {
                            return _moveStrokeBy(entry.value, details.delta);
                          }
                          return entry.value;
                        }).toList();
                      });
                    }
                  : null,
              onPanEnd: _mode == EditMode.selecting && _isDraggingStroke
                  ? (_) {
                      setState(() => _isDraggingStroke = false);
                    }
                  : null,
              child: Draw(
                strokes: _strokes,
                strokeColor: _currentColor,
                strokeWidth: _currentWidth,
                backgroundColor: DemoColors.canvasBackground,
                onStrokeDrawn: (stroke) {
                  if (_mode == EditMode.drawing) {
                    _undoRedoManager.saveState(_strokes);
                    setState(() => _strokes = [..._strokes, stroke]);
                  }
                },
                onStrokeStarted: (newStroke, currentStroke) {
                  if (currentStroke != null) return currentStroke;
                  if (_mode == EditMode.selecting) {
                    if (_selectedIndices.isNotEmpty) {
                      return null;
                    }
                    if (_selectionMethod == SelectionMethod.lasso) {
                      return newStroke.copyWith(
                        color: DemoColors.lassoColor,
                        width: 2.0,
                      );
                    }
                    return null;
                  }
                  return newStroke;
                },
                intersectionDetector:
                    _mode == EditMode.selecting &&
                        _selectionMethod == SelectionMethod.lasso
                    ? detectLassoIntersection
                    : null,
                onStrokesSelected:
                    _mode == EditMode.selecting &&
                        _selectionMethod == SelectionMethod.lasso
                    ? (selectedStrokes) {
                        setState(() {
                          _selectedIndices = selectedStrokes
                              .map((s) => _strokes.indexOf(s))
                              .where((i) => i >= 0)
                              .toSet();
                        });
                      }
                    : null,
                strokePainter: (stroke) {
                  final idx = _strokes.indexWhere((s) => identical(s, stroke));
                  final isSelected = idx >= 0 && _selectedIndices.contains(idx);
                  if (isSelected) {
                    return [
                      paintWithOverride(
                        stroke,
                        strokeWidth: stroke.width + 10,
                        strokeColor: DemoColors.selectionHighlight,
                      ),
                      paintWithOverride(
                        stroke,
                        strokeWidth: stroke.width,
                        strokeColor: stroke.color,
                      ),
                    ];
                  }
                  return [paintWithDefault(stroke)];
                },
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
