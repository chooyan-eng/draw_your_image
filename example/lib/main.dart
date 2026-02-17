import 'package:draw_your_image/draw_your_image.dart';
import 'package:example/constants/demo_colors.dart';
import 'package:example/utils/undo_redo_manager.dart';
import 'package:example/widgets/color_picker.dart';
import 'package:example/widgets/demo_toolbar.dart';
import 'package:example/widgets/stroke_width_slider.dart';
import 'package:example/widgets/tool_button.dart';
import 'package:flutter/material.dart';
import 'pages/pressure_demo_page.dart';
import 'pages/device_control_page.dart';
import 'pages/stroke_editing_page.dart';
import 'pages/stroke_painter_demo_page.dart';
import 'pages/trailing_effect_page.dart';
import 'pages/zoom_pan_page.dart';

void main() => runApp(const MainApp());

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Draw Your Image Examples',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const BasicDrawingPage(),
    );
  }
}

/// Basic Drawing Page
///
/// A simple drawing demo page with color/width settings,
/// eraser mode, and Undo/Redo functionality.
class BasicDrawingPage extends StatefulWidget {
  const BasicDrawingPage({super.key});

  @override
  State<BasicDrawingPage> createState() => _BasicDrawingPageState();
}

enum ErasingBehavior { none, pixel, stroke }

class _BasicDrawingPageState extends State<BasicDrawingPage> {
  // List of strokes
  List<Stroke> _strokes = [];

  // Undo/Redo manager
  final UndoRedoManager _undoRedoManager = UndoRedoManager();

  // Current drawing settings
  Color _currentColor = Colors.black;
  double _currentWidth = 4.0;
  ErasingBehavior _erasingBehavior = ErasingBehavior.none;
  bool get _isErasingMode => _erasingBehavior != ErasingBehavior.none;

  /// Process when stroke is completed
  void _onStrokeDrawn(Stroke stroke) {
    setState(() {
      // Save current state (for Undo)
      _undoRedoManager.saveState(_strokes);
      // Add new stroke
      _strokes = [..._strokes, stroke];
    });
  }

  /// Process when strokes are removed (stroke-level erasing)
  void _onStrokesRemoved(List<Stroke> removedStrokes) {
    setState(() {
      // Save current state (for Undo)
      _undoRedoManager.saveState(_strokes);
      // Remove strokes
      _strokes = _strokes
          .where((stroke) => !removedStrokes.contains(stroke))
          .toList();
    });
  }

  /// Undo process
  void _undo() {
    setState(() {
      _strokes = _undoRedoManager.undo(_strokes);
    });
  }

  /// Redo process
  void _redo() {
    setState(() {
      _strokes = _undoRedoManager.redo(_strokes);
    });
  }

  /// Clear all
  void _clear() {
    setState(() {
      _strokes = [];
      _undoRedoManager.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(child: const DemoList()),
      appBar: AppBar(
        title: const Text('Basic Drawing'),
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
            child: Draw(
              strokes: _strokes,
              strokeColor: _currentColor,
              strokeWidth: _currentWidth,
              backgroundColor: DemoColors.canvasBackground,
              onStrokeStarted: (newStroke, currentStroke) {
                return currentStroke ??
                    newStroke.copyWith(
                      data: {ErasingBehavior: _erasingBehavior},
                    );
              },
              onStrokeDrawn: _onStrokeDrawn,
              onStrokesSelected: _onStrokesRemoved,
              intersectionDetector: _erasingBehavior == ErasingBehavior.stroke
                  ? detectIntersectionBySegmentDistance
                  : null,
              strokePainter: (stroke) =>
                  switch (stroke.data?[ErasingBehavior]) {
                    ErasingBehavior.stroke => [],
                    ErasingBehavior.pixel => [eraseWithDefault(stroke)],
                    _ => [paintWithDefault(stroke)],
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
                // Color picker
                Row(
                  children: [
                    const SizedBox(width: 8),
                    const Text('Color: '),
                    const SizedBox(width: 8),
                    ColorPicker(
                      selectedColor: _currentColor,
                      onColorChanged: (color) {
                        setState(() => _currentColor = color);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Stroke width slider
                Row(
                  children: [
                    const SizedBox(width: 8),
                    const Text('Width: '),
                    const SizedBox(width: 8),
                    StrokeWidthSlider(
                      width: _currentWidth,
                      onWidthChanged: (width) {
                        setState(() => _currentWidth = width);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Eraser mode
                Row(
                  children: [
                    const SizedBox(width: 8),
                    ToolButton(
                      icon: Icons.cleaning_services,
                      isSelected: _isErasingMode,
                      onTap: () {
                        setState(
                          () => _erasingBehavior = _isErasingMode
                              ? ErasingBehavior.none
                              : ErasingBehavior.pixel,
                        );
                      },
                      tooltip: 'Eraser',
                    ),
                    const SizedBox(width: 16),
                    if (_isErasingMode) ...[
                      const Text('Erasing Mode: '),
                      const SizedBox(width: 8),
                      SegmentedButton<ErasingBehavior>(
                        segments: const [
                          ButtonSegment(
                            value: ErasingBehavior.pixel,
                            label: Text('Pixel'),
                            icon: Icon(Icons.brush, size: 16),
                          ),
                          ButtonSegment(
                            value: ErasingBehavior.stroke,
                            label: Text('Stroke'),
                            icon: Icon(Icons.timeline, size: 16),
                          ),
                        ],
                        selected: {_erasingBehavior},
                        onSelectionChanged: (Set<ErasingBehavior> selected) {
                          setState(() {
                            _erasingBehavior = selected.first;
                          });
                        },
                      ),
                    ],
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

class DemoList extends StatelessWidget {
  const DemoList({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Draw Your Image Examples')),
      body: ListView(
        children: [
          _buildDemoTile(
            context,
            title: 'Pressure Sensitive Drawing',
            subtitle: 'NEW! Variable stroke width based on stylus pressure',
            icon: Icons.line_weight,
            color: Colors.purple,
            page: const PressureDemoPage(),
          ),
          _buildDemoTile(
            context,
            title: 'Device Control',
            subtitle: 'Stylus-only, palm rejection, finger eraser',
            icon: Icons.touch_app,
            color: Colors.green,
            page: const DeviceControlPage(),
          ),
          _buildDemoTile(
            context,
            title: 'Stroke Editing',
            subtitle: 'Resampling, smoothing, shape recognition',
            icon: Icons.transform,
            color: Colors.orange,
            page: const StrokeEditingPage(),
          ),
          _buildDemoTile(
            context,
            title: 'Stroke Painter',
            subtitle: 'Custom rendering with shaders and gradients',
            icon: Icons.palette,
            color: Colors.pink,
            page: const StrokePainterDemoPage(),
          ),
          _buildDemoTile(
            context,
            title: 'Trailing Effect',
            subtitle: 'Show only last N points',
            icon: Icons.show_chart,
            color: Colors.teal,
            page: const TrailingEffectPage(),
          ),
          _buildDemoTile(
            context,
            title: 'Zoom & Pan',
            subtitle: 'InteractiveViewer integration',
            icon: Icons.zoom_in,
            color: Colors.indigo,
            page: const ZoomPanPage(),
          ),
        ],
      ),
    );
  }

  Widget _buildDemoTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Widget page,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => page),
          );
        },
      ),
    );
  }
}
