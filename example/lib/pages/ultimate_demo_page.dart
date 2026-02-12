import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/rendering.dart';
import 'package:draw_your_image/draw_your_image.dart';
import '../constants/demo_colors.dart';
import '../widgets/color_picker.dart';
import '../widgets/stroke_width_slider.dart';
import '../utils/undo_redo_manager.dart';

/// Ultimate Demo Page - Combines all features
///
/// Features:
/// - Multiple input modes (stylus only, palm rejection, finger eraser, etc.)
/// - Multiple visual effects (shaders, gradients, borders, glows)
/// - Undo/Redo
/// - Shape recognition
/// - Trailing effects
/// - Zoom/Pan
/// - Export to image
/// - Full customization
class UltimateDemoPage extends StatefulWidget {
  const UltimateDemoPage({super.key});

  @override
  State<UltimateDemoPage> createState() => _UltimateDemoPageState();
}

/// Input mode for device control
enum InputMode {
  anyDevice('Any Device', Icons.touch_app, 'Accept all input devices'),
  stylusOnly('Stylus Only', Icons.edit, 'Only accept stylus input'),
  palmRejection(
    'Palm Rejection',
    Icons.pan_tool,
    'Continue stylus when finger touches',
  ),
  fingerEraser(
    'Finger Eraser',
    Icons.cleaning_services,
    'Stylus draws, finger erases',
  );

  const InputMode(this.label, this.icon, this.description);
  final String label;
  final IconData icon;
  final String description;
}

/// Visual effect style
enum VisualStyle {
  solid('Solid', Icons.remove, 'Solid color'),
  border('Border', Icons.border_outer, 'With border'),
  glow('Glow', Icons.blur_on, 'Glow effect'),
  shadow3d('3D Shadow', Icons.layers, '3D shadow effect'),
  linearGradient('Linear Gradient', Icons.gradient, 'Linear gradient'),
  radialGradient('Radial Gradient', Icons.brightness_1, 'Radial gradient'),
  sweepGradient('Sweep Gradient', Icons.rotate_right, 'Sweep gradient'),
  fragmentShader('Tint Shader', Icons.color_lens, 'Tint shader animation'),
  rainbowWave('Rainbow Wave', Icons.waves, 'Rainbow wave effect'),
  neonGlow('Neon Glow', Icons.flare, 'Neon glow effect'),
  electricSpark('Electric Spark', Icons.bolt, 'Electric spark effect'),
  lavaFlow('Lava Flow', Icons.local_fire_department, 'Lava flow effect'),
  hologram('Hologram', Icons.grid_3x3, 'Hologram effect'),
  galaxyDust('Galaxy Dust', Icons.star, 'Galaxy dust effect');

  const VisualStyle(this.label, this.icon, this.description);
  final String label;
  final IconData icon;
  final String description;
}

/// Shape mode
enum ShapeMode {
  freehand('Freehand', Icons.gesture, 'Free drawing'),
  rectangle('Rectangle', Icons.crop_square, 'Auto rectangle'),
  line('Line', Icons.remove, 'Straight line'),
  circle('Circle', Icons.circle_outlined, 'Auto circle');

  const ShapeMode(this.label, this.icon, this.description);
  final String label;
  final IconData icon;
  final String description;
}

class _UltimateDemoPageState extends State<UltimateDemoPage>
    with SingleTickerProviderStateMixin {
  // State management
  final UndoRedoManager _undoRedo = UndoRedoManager();
  List<Stroke> _strokes = [];
  final GlobalKey _repaintKey = GlobalKey();

  // Settings
  InputMode _inputMode = InputMode.anyDevice;
  VisualStyle _visualStyle = VisualStyle.solid;
  ShapeMode _shapeMode = ShapeMode.freehand;
  Color _strokeColor = Colors.blue;
  double _strokeWidth = 8.0;
  Color _backgroundColor = Colors.white;
  bool _enableTrailing = false;
  bool _enableZoomPan = false;
  bool _isDrawing = false;

  // Fragment shaders
  final Map<String, ui.FragmentProgram> _shaderPrograms = {};
  Ticker? _ticker;
  double _time = 0.0;

  @override
  void initState() {
    super.initState();
    _loadShaders();
    _ticker = createTicker((elapsed) {
      setState(() => _time = elapsed.inMilliseconds / 1000.0);
    })..start();
  }

  @override
  void dispose() {
    _ticker?.dispose();
    super.dispose();
  }

  /// Load all fragment shaders
  Future<void> _loadShaders() async {
    final shaders = {
      'tint': 'shaders/tint.frag',
      'rainbowWave': 'shaders/rainbow_wave.frag',
      'neonGlow': 'shaders/neon_glow.frag',
      'electricSpark': 'shaders/electric_spark.frag',
      'lavaFlow': 'shaders/lava_flow.frag',
      'hologram': 'shaders/hologram.frag',
      'galaxyDust': 'shaders/galaxy_dust.frag',
    };

    for (final entry in shaders.entries) {
      try {
        final program = await ui.FragmentProgram.fromAsset(entry.value);
        _shaderPrograms[entry.key] = program;
      } catch (e) {
        debugPrint('Failed to load ${entry.key} shader: $e');
      }
    }
    setState(() {});
  }

  /// Handle stroke start based on input mode
  Stroke? _handleStrokeStarted(Stroke newStroke, Stroke? currentStroke) {
    if (currentStroke != null) {
      // Continue current stroke based on input mode
      return switch (_inputMode) {
        InputMode.palmRejection => switch (currentStroke.deviceKind.isStylus) {
          true => currentStroke,
          false => newStroke.deviceKind.isStylus ? newStroke : currentStroke,
        },
        _ => currentStroke,
      };
    }

    // Start new stroke based on input mode
    return switch (_inputMode) {
      InputMode.anyDevice => newStroke.copyWith(
        color: _strokeColor,
        width: _strokeWidth,
      ),
      InputMode.stylusOnly =>
        newStroke.deviceKind.isStylus
            ? newStroke.copyWith(color: _strokeColor, width: _strokeWidth)
            : null,
      InputMode.palmRejection => newStroke.copyWith(
        color: _strokeColor,
        width: _strokeWidth,
      ),
      InputMode.fingerEraser =>
        newStroke.deviceKind.isStylus
            ? newStroke.copyWith(color: _strokeColor, width: _strokeWidth)
            : newStroke.copyWith(
                erasingBehavior: ErasingBehavior.stroke,
                width: 30.0,
              ),
    };
  }

  /// Handle stroke update based on shape mode and trailing
  Stroke? _handleStrokeUpdated(Stroke currentStroke) {
    var stroke = currentStroke;

    // Apply trailing effect
    if (_enableTrailing && stroke.points.length > 30) {
      stroke = stroke.copyWith(
        points: stroke.points.sublist(stroke.points.length - 30),
      );
    }

    // Apply shape recognition
    if (stroke.points.length > 2) {
      stroke = switch (_shapeMode) {
        ShapeMode.freehand => stroke,
        ShapeMode.rectangle => _convertToRectangle(stroke),
        ShapeMode.line => _convertToLine(stroke),
        ShapeMode.circle => _convertToCircle(stroke),
      };
    }

    return stroke;
  }

  /// Convert stroke to rectangle
  Stroke _convertToRectangle(Stroke stroke) {
    final first = stroke.points.first.position;
    final last = stroke.points.last.position;
    return stroke.copyWith(
      points: [
        StrokePoint(
          position: first,
          pressure: 1.0,
          pressureMin: 1.0,
          pressureMax: 1.0,
          tilt: 0.0,
          orientation: 0.0,
        ),
        StrokePoint(
          position: Offset(first.dx, last.dy),
          pressure: 1.0,
          pressureMin: 1.0,
          pressureMax: 1.0,
          tilt: 0.0,
          orientation: 0.0,
        ),
        StrokePoint(
          position: last,
          pressure: 1.0,
          pressureMin: 1.0,
          pressureMax: 1.0,
          tilt: 0.0,
          orientation: 0.0,
        ),
        StrokePoint(
          position: Offset(last.dx, first.dy),
          pressure: 1.0,
          pressureMin: 1.0,
          pressureMax: 1.0,
          tilt: 0.0,
          orientation: 0.0,
        ),
        StrokePoint(
          position: first,
          pressure: 1.0,
          pressureMin: 1.0,
          pressureMax: 1.0,
          tilt: 0.0,
          orientation: 0.0,
        ),
      ],
    );
  }

  /// Convert stroke to line
  Stroke _convertToLine(Stroke stroke) {
    return stroke.copyWith(points: [stroke.points.first, stroke.points.last]);
  }

  /// Convert stroke to circle
  Stroke _convertToCircle(Stroke stroke) {
    final first = stroke.points.first.position;
    final last = stroke.points.last.position;
    final center = Offset((first.dx + last.dx) / 2, (first.dy + last.dy) / 2);
    final radius = (last - first).distance / 2;

    final points = <StrokePoint>[];
    for (int i = 0; i <= 60; i++) {
      final angle = (i / 60) * 2 * math.pi;
      points.add(
        StrokePoint(
          position: center + Offset(math.cos(angle), math.sin(angle)) * radius,
          pressure: 1.0,
          pressureMin: 1.0,
          pressureMax: 1.0,
          tilt: 0.0,
          orientation: 0.0,
        ),
      );
    }
    return stroke.copyWith(points: points);
  }

  /// Get stroke painter based on visual style
  List<ui.Paint> _getPainterForStyle(Stroke stroke, ui.Size canvasSize) {
    return switch (_visualStyle) {
      VisualStyle.solid => [paintWithDefault(stroke)],
      VisualStyle.border => [
        paintWithOverride(
          stroke,
          strokeWidth: stroke.width + 4,
          strokeColor: Colors.black,
        ),
        paintWithDefault(stroke),
      ],
      VisualStyle.glow => [
        paintWithOverride(
          stroke,
          strokeWidth: stroke.width + 8,
          strokeColor: stroke.color,
        )..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 4),
        paintWithDefault(stroke),
      ],
      VisualStyle.shadow3d => [
        paintWithOverride(
          stroke,
          strokeWidth: stroke.width + 6,
          strokeColor: Colors.black26,
        )..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 3),
        paintWithOverride(
          stroke,
          strokeWidth: stroke.width + 4,
          strokeColor: Colors.black,
        ),
        paintWithOverride(
          stroke,
          strokeWidth: stroke.width + 2,
          strokeColor: Colors.white70,
        ),
        paintWithDefault(stroke),
      ],
      VisualStyle.linearGradient => [
        ui.Paint()
          ..shader = ui.Gradient.linear(
            ui.Offset.zero,
            ui.Offset(canvasSize.width, canvasSize.height),
            [Colors.blue, Colors.purple, Colors.pink],
            [0.0, 0.5, 1.0],
          )
          ..strokeWidth = stroke.width
          ..strokeCap = ui.StrokeCap.round
          ..style = ui.PaintingStyle.stroke,
      ],
      VisualStyle.radialGradient => [
        ui.Paint()
          ..shader = ui.Gradient.radial(
            ui.Offset(canvasSize.width / 2, canvasSize.height / 2),
            math.max(canvasSize.width, canvasSize.height) / 2,
            [Colors.yellow, Colors.red],
          )
          ..strokeWidth = stroke.width
          ..strokeCap = ui.StrokeCap.round
          ..style = ui.PaintingStyle.stroke,
      ],
      VisualStyle.sweepGradient => [
        ui.Paint()
          ..shader = ui.Gradient.sweep(
            ui.Offset(canvasSize.width / 2, canvasSize.height / 2),
            [
              Colors.red,
              Colors.yellow,
              Colors.green,
              Colors.cyan,
              Colors.blue,
              const Color(0xFFFF00FF), // Magenta
              Colors.red,
            ],
          )
          ..strokeWidth = stroke.width
          ..strokeCap = ui.StrokeCap.round
          ..style = ui.PaintingStyle.stroke,
      ],
      VisualStyle.fragmentShader => _createShaderPaint(
        'tint',
        stroke,
        canvasSize,
      ),
      VisualStyle.rainbowWave => _createShaderPaint(
        'rainbowWave',
        stroke,
        canvasSize,
      ),
      VisualStyle.neonGlow => _createShaderPaint(
        'neonGlow',
        stroke,
        canvasSize,
      ),
      VisualStyle.electricSpark => _createShaderPaint(
        'electricSpark',
        stroke,
        canvasSize,
      ),
      VisualStyle.lavaFlow => _createShaderPaint(
        'lavaFlow',
        stroke,
        canvasSize,
      ),
      VisualStyle.hologram => _createShaderPaint(
        'hologram',
        stroke,
        canvasSize,
      ),
      VisualStyle.galaxyDust => _createShaderPaint(
        'galaxyDust',
        stroke,
        canvasSize,
      ),
    };
  }

  /// Create shader paint helper
  List<ui.Paint> _createShaderPaint(
    String shaderKey,
    Stroke stroke,
    ui.Size canvasSize,
  ) {
    final program = _shaderPrograms[shaderKey];
    if (program == null) {
      return [paintWithDefault(stroke)];
    }

    final shader = program.fragmentShader();
    shader.setFloat(0, _time);
    shader.setFloat(1, canvasSize.width);
    shader.setFloat(2, canvasSize.height);

    return [
      ui.Paint()
        ..shader = shader
        ..strokeWidth = stroke.width
        ..strokeCap = ui.StrokeCap.round
        ..style = ui.PaintingStyle.stroke,
    ];
  }

  /// Undo action
  void _undo() {
    setState(() {
      _strokes = _undoRedo.undo(_strokes);
    });
  }

  /// Redo action
  void _redo() {
    setState(() {
      _strokes = _undoRedo.redo(_strokes);
    });
  }

  /// Clear all strokes
  void _clearAll() {
    setState(() {
      _undoRedo.saveState(_strokes);
      _strokes = [];
    });
  }

  /// Export canvas to image
  Future<void> _exportImage() async {
    try {
      final boundary =
          _repaintKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Image exported (${byteData!.lengthInBytes} bytes)'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ultimate Demo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: _undoRedo.canUndo ? _undo : null,
            tooltip: 'Undo',
          ),
          IconButton(
            icon: const Icon(Icons.redo),
            onPressed: _undoRedo.canRedo ? _redo : null,
            tooltip: 'Redo',
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportImage,
            tooltip: 'Export Image',
          ),
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: _strokes.isEmpty ? null : _clearAll,
            tooltip: 'Clear All',
          ),
        ],
      ),
      body: Column(
        children: [
          // Toolbar
          _buildToolbar(),
          // Canvas
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final canvasSize = ui.Size(
                  constraints.maxWidth,
                  constraints.maxHeight,
                );

                Widget drawWidget = RepaintBoundary(
                  key: _repaintKey,
                  child: Draw(
                    strokes: _strokes,
                    strokeColor: _strokeColor,
                    strokeWidth: _strokeWidth,
                    backgroundColor: _backgroundColor,
                    smoothingFunc: _shapeMode == ShapeMode.freehand
                        ? SmoothingMode.catmullRom.converter
                        : SmoothingMode.none.converter,
                    shouldAbsorb: _enableZoomPan
                        ? (event) => event.kind.isStylus
                        : null,
                    onStrokeDrawn: (stroke) {
                      setState(() {
                        _undoRedo.saveState(_strokes);
                        _strokes = [..._strokes, stroke];
                        _isDrawing = false;
                      });
                    },
                    onStrokesRemoved: (removedStrokes) {
                      setState(() {
                        _undoRedo.saveState(_strokes);
                        _strokes = _strokes
                            .where((s) => !removedStrokes.contains(s))
                            .toList();
                      });
                    },
                    onStrokeStarted: (newStroke, currentStroke) {
                      setState(() => _isDrawing = true);
                      return _handleStrokeStarted(newStroke, currentStroke);
                    },
                    onStrokeUpdated: _handleStrokeUpdated,
                    strokePainter: (stroke) =>
                        _getPainterForStyle(stroke, canvasSize),
                  ),
                );

                if (_enableZoomPan) {
                  drawWidget = InteractiveViewer(
                    scaleEnabled: !_isDrawing,
                    panEnabled: !_isDrawing,
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: drawWidget,
                  );
                }

                return drawWidget;
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Build toolbar
  Widget _buildToolbar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Main controls
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // Color picker
                ColorPicker(
                  selectedColor: _strokeColor,
                  onColorChanged: (color) =>
                      setState(() => _strokeColor = color),
                ),
                const SizedBox(width: 16),
                // Width slider
                Expanded(
                  child: StrokeWidthSlider(
                    width: _strokeWidth,
                    onWidthChanged: (width) =>
                        setState(() => _strokeWidth = width),
                  ),
                ),
              ],
            ),
          ),
          // Mode selectors
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                _buildModeSelector<InputMode>(
                  'Input',
                  Icons.touch_app,
                  _inputMode,
                  InputMode.values,
                  (mode) => setState(() => _inputMode = mode),
                ),
                const SizedBox(width: 12),
                _buildModeSelector<VisualStyle>(
                  'Style',
                  Icons.brush,
                  _visualStyle,
                  VisualStyle.values,
                  (style) => setState(() => _visualStyle = style),
                ),
                const SizedBox(width: 12),
                _buildModeSelector<ShapeMode>(
                  'Shape',
                  Icons.crop_square,
                  _shapeMode,
                  ShapeMode.values,
                  (mode) => setState(() => _shapeMode = mode),
                ),
                const SizedBox(width: 12),
                _buildToggleChip(
                  'Trailing',
                  Icons.show_chart,
                  _enableTrailing,
                  (value) => setState(() => _enableTrailing = value),
                ),
                const SizedBox(width: 8),
                _buildToggleChip(
                  'Zoom/Pan',
                  Icons.zoom_in,
                  _enableZoomPan,
                  (value) => setState(() => _enableZoomPan = value),
                ),
                const SizedBox(width: 8),
                _buildColorButton('BG', _backgroundColor, () async {
                  final color = await _showColorDialog(_backgroundColor);
                  if (color != null) {
                    setState(() => _backgroundColor = color);
                  }
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build mode selector dropdown
  Widget _buildModeSelector<T>(
    String label,
    IconData icon,
    T current,
    List<T> values,
    void Function(T) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey[700]),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(width: 4),
          DropdownButton<T>(
            value: current,
            underline: const SizedBox(),
            isDense: true,
            items: values.map((value) {
              final item = value as dynamic;
              return DropdownMenuItem<T>(
                value: value,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(item.icon, size: 16),
                    const SizedBox(width: 8),
                    Text(item.label, style: const TextStyle(fontSize: 12)),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) onChanged(value);
            },
          ),
        ],
      ),
    );
  }

  /// Build toggle chip
  Widget _buildToggleChip(
    String label,
    IconData icon,
    bool value,
    void Function(bool) onChanged,
  ) {
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
      selected: value,
      onSelected: onChanged,
      selectedColor: Colors.blue[100],
      checkmarkColor: Colors.blue,
    );
  }

  /// Build color button
  Widget _buildColorButton(String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.grey[400]!),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Show color picker dialog
  Future<Color?> _showColorDialog(Color initialColor) async {
    Color selectedColor = initialColor;
    return showDialog<Color>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Color'),
        content: SingleChildScrollView(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                [
                  Colors.white,
                  Colors.grey[200]!,
                  Colors.black,
                  ...DemoColors.palette,
                ].map((color) {
                  return InkWell(
                    onTap: () {
                      selectedColor = color;
                      Navigator.pop(context, color);
                    },
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: color,
                        border: Border.all(
                          color: color == selectedColor
                              ? Colors.blue
                              : Colors.grey[400]!,
                          width: color == selectedColor ? 3 : 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  );
                }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

/// Extension to check if PointerDeviceKind is stylus
extension on PointerDeviceKind {
  bool get isStylus =>
      this == PointerDeviceKind.stylus ||
      this == PointerDeviceKind.invertedStylus;
}
