import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:draw_your_image/draw_your_image.dart';
import '../constants/demo_colors.dart';

/// strokePainter style
enum PainterStyle {
  defaultStyle('Default', 'Solid color line'),
  border('Border', 'Black border + color line'),
  glow('Glow', 'Blur + line'),
  shadow3d('3D Effect', 'Shadow + Highlight + line'),
  linearGradient('Linear Gradient', 'Top left → Bottom right'),
  radialGradient('Radial Gradient', 'Center → Outer'),
  fragmentShader('Fragment Shader', 'Animation effect'),
  rainbowWave('Rainbow Wave', 'Rainbow colors with wave effect'),
  neonGlow('Neon Glow', 'Pulsing cyan/magenta neon'),
  electricSpark('Electric Spark', 'Electric blue sparks'),
  lavaFlow('Lava Flow', 'Flowing lava animation'),
  hologram('Hologram', 'Holographic scan lines'),
  galaxyDust('Galaxy Dust', 'Rotating galaxy particles');

  const PainterStyle(this.label, this.description);
  final String label;
  final String description;
}

/// strokePainter Demo Page
///
/// Demo of 8 diverse drawing styles.
class StrokePainterDemoPage extends StatefulWidget {
  const StrokePainterDemoPage({super.key});

  @override
  State<StrokePainterDemoPage> createState() => _StrokePainterDemoPageState();
}

class _StrokePainterDemoPageState extends State<StrokePainterDemoPage>
    with SingleTickerProviderStateMixin {
  List<Stroke> _strokes = [];
  PainterStyle _currentStyle = PainterStyle.defaultStyle;

  // For fragment shaders
  final Map<String, ui.FragmentProgram> _shaderPrograms = {};
  Ticker? _ticker;
  double _time = 0.0;

  @override
  void initState() {
    super.initState();
    _loadShader();
    _ticker = createTicker((elapsed) {
      setState(() => _time = elapsed.inMilliseconds / 1000.0);
    })..start();
  }

  @override
  void dispose() {
    _ticker?.dispose();
    super.dispose();
  }

  /// Load fragment shaders
  Future<void> _loadShader() async {
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

  /// Return painter based on style
  List<ui.Paint> _getPainterForStyle(Stroke stroke, ui.Size canvasSize) {
    switch (_currentStyle) {
      case PainterStyle.defaultStyle:
        return [paintWithDefault(stroke)];

      case PainterStyle.border:
        return [
          // Black border (bottom layer)
          paintWithOverride(
            stroke,
            strokeWidth: stroke.width + 4,
            strokeColor: Colors.black,
          ),
          // Color line (top layer)
          paintWithOverride(stroke, strokeColor: Colors.white),
        ];

      case PainterStyle.glow:
        return [
          // Glow effect (bottom layer)
          paintWithOverride(
            stroke,
            strokeWidth: stroke.width + 8,
            strokeColor: stroke.color,
          )..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 4),
          // Line (top layer)
          paintWithDefault(stroke),
        ];

      case PainterStyle.shadow3d:
        return [
          // Drop shadow (bottom layer)
          paintWithOverride(
            stroke,
            strokeWidth: stroke.width + 6,
            strokeColor: Colors.black26,
          )..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 3),
          // Outer border (middle layer)
          paintWithOverride(
            stroke,
            strokeWidth: stroke.width + 4,
            strokeColor: Colors.black,
          ),
          // Highlight (middle-top layer)
          paintWithOverride(
            stroke,
            strokeWidth: stroke.width + 2,
            strokeColor: Colors.white70,
          ),
          // Line (top layer)
          paintWithDefault(stroke),
        ];

      case PainterStyle.linearGradient:
        final gradient = ui.Gradient.linear(
          ui.Offset.zero,
          ui.Offset(canvasSize.width, canvasSize.height),
          [Colors.blue, Colors.purple, Colors.pink],
          [0.0, 0.5, 1.0],
        );
        return [
          ui.Paint()
            ..shader = gradient
            ..strokeWidth = stroke.width
            ..strokeCap = ui.StrokeCap.round
            ..style = ui.PaintingStyle.stroke,
        ];

      case PainterStyle.radialGradient:
        final center = ui.Offset(canvasSize.width / 2, canvasSize.height / 2);
        final radius = math.max(canvasSize.width, canvasSize.height) / 2;
        final gradient = ui.Gradient.radial(center, radius, [
          Colors.yellow,
          Colors.red,
        ]);
        return [
          ui.Paint()
            ..shader = gradient
            ..strokeWidth = stroke.width
            ..strokeCap = ui.StrokeCap.round
            ..style = ui.PaintingStyle.stroke,
        ];

      case PainterStyle.fragmentShader:
        return _createShaderPaint('tint', stroke, canvasSize);

      case PainterStyle.rainbowWave:
        return _createShaderPaint('rainbowWave', stroke, canvasSize);

      case PainterStyle.neonGlow:
        return _createShaderPaint('neonGlow', stroke, canvasSize);

      case PainterStyle.electricSpark:
        return _createShaderPaint('electricSpark', stroke, canvasSize);

      case PainterStyle.lavaFlow:
        return _createShaderPaint('lavaFlow', stroke, canvasSize);

      case PainterStyle.hologram:
        return _createShaderPaint('hologram', stroke, canvasSize);

      case PainterStyle.galaxyDust:
        return _createShaderPaint('galaxyDust', stroke, canvasSize);
    }
  }

  /// Create shader paint helper
  List<ui.Paint> _createShaderPaint(
    String shaderKey,
    Stroke stroke,
    ui.Size canvasSize,
  ) {
    final program = _shaderPrograms[shaderKey];
    if (program == null) {
      // Use default if shader is not loaded
      return [paintWithDefault(stroke)];
    }

    final shader = program.fragmentShader();
    shader.setFloat(0, _time); // u_time
    shader.setFloat(1, canvasSize.width); // u_resolution.x
    shader.setFloat(2, canvasSize.height); // u_resolution.y

    return [
      ui.Paint()
        ..shader = shader
        ..strokeWidth = stroke.width
        ..strokeCap = ui.StrokeCap.round
        ..style = ui.PaintingStyle.stroke,
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('strokePainter Demo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: _strokes.isEmpty
                ? null
                : () => setState(() => _strokes = []),
            tooltip: 'Clear All',
          ),
        ],
      ),
      body: Column(
        children: [
          // Canvas
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final canvasSize = ui.Size(
                  constraints.maxWidth,
                  constraints.maxHeight,
                );
                return Draw(
                  strokes: _strokes,
                  strokeColor: Colors.blue,
                  strokeWidth: 8.0,
                  backgroundColor: DemoColors.canvasBackground,
                  onStrokeDrawn: (stroke) {
                    setState(() => _strokes = [..._strokes, stroke]);
                  },
                  strokePainter: (stroke) =>
                      _getPainterForStyle(stroke, canvasSize),
                );
              },
            ),
          ),
          // Style selection and description
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: DemoColors.toolbarBackground,
              border: Border(top: BorderSide(color: Colors.grey, width: 0.5)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Style:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButton<PainterStyle>(
                        value: _currentStyle,
                        isExpanded: true,
                        items: PainterStyle.values.map((style) {
                          return DropdownMenuItem(
                            value: style,
                            child: Text(style.label),
                          );
                        }).toList(),
                        onChanged: (style) {
                          if (style != null) {
                            setState(() => _currentStyle = style);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _currentStyle.description,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
