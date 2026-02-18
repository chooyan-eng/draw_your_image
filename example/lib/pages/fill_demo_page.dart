import 'dart:collection';
import 'dart:math' as math;

import 'package:draw_your_image/draw_your_image.dart';
import 'package:flutter/material.dart';

import '../constants/demo_colors.dart';
import '../utils/undo_redo_manager.dart';
import '../widgets/color_picker.dart';
import '../widgets/demo_toolbar.dart';

enum _DrawingMode { line, fill }

/// Fill Demo Page
///
/// Demonstrates flood-fill functionality built on top of draw_your_image.
///
/// Architecture:
/// - Line strokes are drawn normally.
/// - In fill mode, a tap triggers a geometric flood fill:
///     1. Each stroke is treated as a "capsule" (line segment with radius = strokeWidth/2).
///     2. For each integer y-scanline, the x-intervals blocked by capsules are computed
///        analytically from the stroke coordinate data in [_strokes].
///     3. The complement (free intervals) represents open space at each y.
///     4. BFS from the tap position propagates through adjacent free intervals.
///     5. The visited set is converted to a Path and stored in a new Stroke's data.
/// - [pathBuilder] returns the pre-computed fill Path for fill strokes.
/// - [strokePainter] renders fill strokes with PaintingStyle.fill.
class FillDemoPage extends StatefulWidget {
  const FillDemoPage({super.key});

  @override
  State<FillDemoPage> createState() => _FillDemoPageState();
}

class _FillDemoPageState extends State<FillDemoPage> {
  List<Stroke> _strokes = [];

  _DrawingMode _mode = _DrawingMode.line;

  Color _lineColor = Colors.black;
  Color _fillColor = Colors.blue;

  Size _canvasSize = Size.zero;

  final UndoRedoManager _undoRedoManager = UndoRedoManager();
  void _undo() => setState(() => _strokes = _undoRedoManager.undo(_strokes));
  void _redo() => setState(() => _strokes = _undoRedoManager.redo(_strokes));
  void _clear() => setState(() {
    _strokes = [];
    _undoRedoManager.clear();
  });

  List<Stroke> get lineStrokes =>
      _strokes.where((s) => s.data?[#fillPath] == null).toList();

  @override
  Widget build(BuildContext context) {
    final isLine = _mode == _DrawingMode.line;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fill Demo'),
        actions: [
          DemoToolbar(
            onUndo: _undo,
            onRedo: _redo,
            onClear: _strokes.isEmpty ? null : _clear,
            canUndo: _undoRedoManager.canUndo,
            canRedo: _undoRedoManager.canRedo,
          ),
        ],
      ),
      body: Column(
        children: [
          // Canvas
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                _canvasSize = Size(constraints.maxWidth, constraints.maxHeight);
                return Draw(
                  strokes: _strokes,
                  strokeColor: _lineColor,
                  strokeWidth: 4.0,
                  backgroundColor: DemoColors.canvasBackground,
                  onStrokeStarted: (newStroke, currentStroke) {
                    if (currentStroke != null) return currentStroke;
                    return _mode == _DrawingMode.fill
                        ? newStroke.copyWith(
                            // remember this stroke is for filling
                            data: {#drawingMode: _DrawingMode.fill},
                            color: Colors.transparent,
                          )
                        : newStroke;
                  },
                  onStrokeDrawn: (stroke) {
                    // Fill-mode tap strokes are identified by #drawingMode data.
                    // They are not saved — instead they trigger the geometric fill.
                    if (stroke.data?[#drawingMode] == _DrawingMode.fill) {
                      if (stroke.points.isNotEmpty &&
                          _canvasSize != Size.zero) {
                        // generate another Path for filling
                        final fillPath = _geometricFill(
                          lineStrokes,
                          stroke.points.first.position,
                          _canvasSize,
                        );
                        if (fillPath == null) return;

                        // generate another Stroke preserving the Path and fill color
                        final fillStroke = stroke.copyWith(
                          color: _fillColor,
                          data: {#fillPath: fillPath},
                        );

                        setState(() {
                          _undoRedoManager.saveState(_strokes);
                          _strokes = [..._strokes, fillStroke];
                        });
                      }
                      return;
                    }

                    setState(() {
                      _undoRedoManager.saveState(_strokes);
                      _strokes = [..._strokes, stroke];
                    });
                  },
                  pathBuilder: (stroke) {
                    final fillPath = stroke.data?[#fillPath];
                    return fillPath is Path
                        ? fillPath // apply pre-computed fill Path for fill strokes
                        : PathBuilderMode.catmullRom.converter(stroke);
                  },
                  strokePainter: (stroke) {
                    return stroke.data?[#fillPath] is Path
                        ? [paintWithOverride(stroke, style: PaintingStyle.fill)]
                        : [paintWithDefault(stroke)];
                  },
                );
              },
            ),
          ),

          // Toolbar
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: DemoColors.toolbarBackground,
              border: Border(top: BorderSide(color: Colors.grey, width: 0.5)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Mode toggle
                Row(
                  children: [
                    const SizedBox(width: 8),
                    const Text('Mode: '),
                    const SizedBox(width: 8),
                    SegmentedButton<_DrawingMode>(
                      segments: const [
                        ButtonSegment(
                          value: _DrawingMode.line,
                          label: Text('Line'),
                          icon: Icon(Icons.edit, size: 16),
                        ),
                        ButtonSegment(
                          value: _DrawingMode.fill,
                          label: Text('Fill'),
                          icon: Icon(Icons.format_color_fill, size: 16),
                        ),
                      ],
                      selected: {_mode},
                      onSelectionChanged: (selected) {
                        setState(() => _mode = selected.first);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Color picker — shows relevant color for the active mode
                Row(
                  children: [
                    const SizedBox(width: 8),
                    Text(isLine ? 'Line Color: ' : 'Fill Color: '),
                    const SizedBox(width: 8),
                    ColorPicker(
                      selectedColor: isLine ? _lineColor : _fillColor,
                      onColorChanged: (color) {
                        setState(() {
                          if (isLine) {
                            _lineColor = color;
                          } else {
                            _fillColor = color;
                          }
                        });
                      },
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
// ---------------------------------------------------- geometric fill engine

/// Produces a fill [Path] by propagating through the open space in [strokes]
/// starting from [tapPos], using scanline-based BFS.
///
/// Returns `null` if [tapPos] falls directly on a stroke (no free space).
Path? _geometricFill(List<Stroke> strokes, Offset tapPos, Size canvasSize) {
  final height = canvasSize.height.round();
  final width = canvasSize.width;

  // Precompute free (unblocked) x-intervals for every integer y-scanline.
  final freeByY = <int, List<(double, double)>>{};
  for (int y = 0; y < height; y++) {
    final blocked = _blockedIntervalsAtY(strokes, y.toDouble());
    final free = _invertIntervals(blocked, 0, width);
    if (free.isNotEmpty) freeByY[y] = free;
  }

  // Find the free interval at the tap y that contains the tap x.
  final tapY = tapPos.dy.round().clamp(0, height - 1);
  final tapIntervals = freeByY[tapY] ?? [];
  int? startIdx;
  for (int i = 0; i < tapIntervals.length; i++) {
    if (tapPos.dx >= tapIntervals[i].$1 && tapPos.dx <= tapIntervals[i].$2) {
      startIdx = i;
      break;
    }
  }
  if (startIdx == null) return null; // Tap is on a stroke.

  // BFS over (y, intervalIndex) pairs, connecting intervals that overlap
  // vertically between adjacent scanlines.
  final visited = <int, Set<int>>{};
  final queue = Queue<(int, int)>()..add((tapY, startIdx));

  while (queue.isNotEmpty) {
    final (y, idx) = queue.removeFirst();

    visited.putIfAbsent(y, () => {});
    if (!visited[y]!.add(idx)) continue; // Already visited.

    final interval = freeByY[y]![idx];

    for (final nextY in [y - 1, y + 1]) {
      if (nextY < 0 || nextY >= height) continue;
      final nextIntervals = freeByY[nextY] ?? [];
      for (int ni = 0; ni < nextIntervals.length; ni++) {
        if (visited[nextY]?.contains(ni) == true) continue;
        // Connect if the two intervals overlap in x.
        if (_intervalsOverlap(interval, nextIntervals[ni])) {
          queue.add((nextY, ni));
        }
      }
    }
  }

  if (visited.isEmpty) return null;

  // Build the fill Path from all visited scanline intervals.
  final path = Path();
  for (final entry in visited.entries) {
    final y = entry.key.toDouble();
    final intervals = freeByY[entry.key]!;
    for (final idx in entry.value) {
      final (l, r) = intervals[idx];
      path.addRect(Rect.fromLTWH(l, y, r - l, 1.0));
    }
  }

  return path;
}

/// Returns the merged x-intervals blocked by [strokes] at scanline [y].
List<(double, double)> _blockedIntervalsAtY(List<Stroke> strokes, double y) {
  final intervals = <(double, double)>[];

  for (final stroke in strokes) {
    final r = stroke.width / 2;
    final pts = stroke.points;

    if (pts.isEmpty) continue;

    // Single-point stroke: treat as a circle.
    if (pts.length == 1) {
      final p = pts[0].position;
      final interval = _circleXIntervalAtY(p, r, y);
      if (interval != null) intervals.add(interval);
      continue;
    }

    // Multi-point stroke: each consecutive pair forms a capsule.
    for (int i = 0; i < pts.length - 1; i++) {
      final interval = _capsuleXIntervalAtY(
        pts[i].position,
        pts[i + 1].position,
        r,
        y,
      );
      if (interval != null) intervals.add(interval);
    }
  }

  return _mergeIntervals(intervals);
}

/// Returns the x-interval covered by a circle of radius [r] at [center],
/// at scanline height [y]. Returns `null` if the circle doesn't reach [y].
(double, double)? _circleXIntervalAtY(Offset center, double r, double y) {
  final dy = y - center.dy;
  if (dy.abs() > r) return null;
  final hw = math.sqrt(r * r - dy * dy);
  return (center.dx - hw, center.dx + hw);
}

/// Returns the x-interval blocked by the capsule of segment ([p1], [p2])
/// with radius [r] at scanline [y].
///
/// The capsule is the Minkowski sum of the segment and a disk of radius [r].
/// Its cross-section at height [y] is computed as the union of:
///   - The circle cross-sections at each endpoint
///   - The parallelogram (rectangular corridor) cross-section
(double, double)? _capsuleXIntervalAtY(
  Offset p1,
  Offset p2,
  double r,
  double y,
) {
  double? xMin, xMax;

  void expand(double left, double right) {
    xMin = xMin == null ? left : math.min(xMin!, left);
    xMax = xMax == null ? right : math.max(xMax!, right);
  }

  // End-cap circles.
  final c1 = _circleXIntervalAtY(p1, r, y);
  if (c1 != null) expand(c1.$1, c1.$2);

  final c2 = _circleXIntervalAtY(p2, r, y);
  if (c2 != null) expand(c2.$1, c2.$2);

  // Rectangular corridor (parallelogram).
  final dx = p2.dx - p1.dx;
  final dy = p2.dy - p1.dy;
  final len = math.sqrt(dx * dx + dy * dy);
  if (len < 1e-10) return xMin == null ? null : (xMin!, xMax!);

  // Unit normal vector: n = (-dy, dx) / len
  final nx = -dy / len;
  final ny = dx / len;

  // Four corners of the parallelogram:
  //   A = p1 + r*n,  B = p2 + r*n,  C = p2 - r*n,  D = p1 - r*n
  final ax = p1.dx + r * nx;
  final ay = p1.dy + r * ny;
  final bx = p2.dx + r * nx;
  final by = p2.dy + r * ny;
  final cx = p2.dx - r * nx;
  final cy = p2.dy - r * ny;
  final ex = p1.dx - r * nx; // 'e' instead of 'd' to avoid conflict
  final ey = p1.dy - r * ny;

  // For each edge, find the x value where it crosses scanline [y].
  void checkEdge(double fromX, double fromY, double toX, double toY) {
    final edgeDy = toY - fromY;
    if (edgeDy.abs() < 1e-10) return; // Horizontal edge — skip.
    final t = (y - fromY) / edgeDy;
    if (t < 0 || t > 1) return;
    final x = fromX + t * (toX - fromX);
    expand(x, x);
  }

  checkEdge(ax, ay, bx, by); // AB
  checkEdge(bx, by, cx, cy); // BC
  checkEdge(cx, cy, ex, ey); // CD
  checkEdge(ex, ey, ax, ay); // DA

  return xMin == null ? null : (xMin!, xMax!);
}

/// Merges overlapping intervals. Input need not be sorted.
List<(double, double)> _mergeIntervals(List<(double, double)> intervals) {
  if (intervals.isEmpty) return [];
  intervals.sort((a, b) => a.$1.compareTo(b.$1));
  final merged = [intervals[0]];
  for (int i = 1; i < intervals.length; i++) {
    final (curL, curR) = merged.last;
    final (nextL, nextR) = intervals[i];
    if (nextL <= curR) {
      merged[merged.length - 1] = (curL, math.max(curR, nextR));
    } else {
      merged.add(intervals[i]);
    }
  }
  return merged;
}

/// Returns the complement of [blocked] intervals within [minX]..[maxX].
List<(double, double)> _invertIntervals(
  List<(double, double)> blocked,
  double minX,
  double maxX,
) {
  final free = <(double, double)>[];
  double cursor = minX;
  for (final (l, r) in blocked) {
    if (cursor < l) free.add((cursor, l));
    cursor = math.max(cursor, r);
  }
  if (cursor < maxX) free.add((cursor, maxX));
  return free;
}

bool _intervalsOverlap((double, double) a, (double, double) b) =>
    a.$1 <= b.$2 && b.$1 <= a.$2;
