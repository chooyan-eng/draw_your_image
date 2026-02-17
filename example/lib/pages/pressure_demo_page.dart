import 'dart:ui' as ui;
import 'package:draw_your_image/draw_your_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class PressureDemoPage extends StatefulWidget {
  const PressureDemoPage({super.key});

  @override
  State<PressureDemoPage> createState() => _PressureDemoPageState();
}

class _PressureDemoPageState extends State<PressureDemoPage>
    with SingleTickerProviderStateMixin {
  List<Stroke> _strokes = [];
  ui.FragmentProgram? _shaderProgram;
  Ticker? _ticker;
  double _time = 0.0;
  bool _useShader = false;
  Color _selectedColor = Colors.black;

  // Predefined color palette
  static const List<Color> _colorPalette = [
    Colors.black,
    Color(0xFFFF2702), // Cadmium Red
    Color(0xFFFF6900), // Cadmium Orange
    Color(0xFFFEEC00), // Cadmium Yellow
    Color(0xFF076D16), // Permanent Green
    Color(0xFF003C32), // Phthalo Green
    Color(0xFF002185), // Cobalt Blue
    Color(0xFF190059), // Ultramarine Blue
    Color(0xFF80022E), // Quinacridone Magenta
    Color(0xFF4E0042), // Cobalt Violet
    Color(0xFF7B4800), // Burnt Sienna
    Colors.white,
  ];

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

  Future<void> _loadShader() async {
    try {
      final program = await ui.FragmentProgram.fromAsset('shaders/tint.frag');
      setState(() => _shaderProgram = program);
    } catch (e) {
      debugPrint('Failed to load shader: $e');
    }
  }

  void _clear() {
    setState(() => _strokes = []);
  }

  List<Paint> _getPaint(Stroke stroke, Size canvasSize) {
    if (_useShader && _shaderProgram != null) {
      final shader = _shaderProgram!.fragmentShader();
      shader.setFloat(0, _time);
      shader.setFloat(1, canvasSize.width);
      shader.setFloat(2, canvasSize.height);

      return [
        Paint()
          ..shader = shader
          ..style = PaintingStyle.fill,
      ];
    } else {
      return [
        Paint()
          ..color = stroke.color
          ..style = PaintingStyle.fill,
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pressure Sensitive Drawing'),
        actions: [
          IconButton(
            icon: Icon(
              _useShader ? Icons.color_lens : Icons.color_lens_outlined,
            ),
            onPressed: _shaderProgram != null
                ? () => setState(() => _useShader = !_useShader)
                : null,
            tooltip: _useShader ? 'Disable Shader' : 'Enable Shader',
          ),
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: _strokes.isEmpty ? null : _clear,
            tooltip: 'Clear',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Draw with a stylus or pressure-sensitive device.\n'
              'The stroke width will vary based on pressure.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final canvasSize = Size(
                      constraints.maxWidth,
                      constraints.maxHeight,
                    );

                    return Draw(
                      strokes: _strokes,
                      strokeColor: _selectedColor,
                      strokeWidth: 20.0,
                      backgroundColor: Colors.white,
                      // Use the appropriate path converter based on brush mode
                      pathBuilder: PathBuilderMode.pressureSensitive.converter,
                      // Use fill style for pressure-sensitive strokes with optional shader
                      strokePainter: (stroke) => _getPaint(stroke, canvasSize),
                      onStrokeDrawn: (stroke) {
                        setState(() {
                          _strokes = [..._strokes, stroke];
                        });
                      },
                      onStrokeStarted: (newStroke, currentStroke) {
                        if (currentStroke != null) {
                          return currentStroke;
                        }
                        return newStroke;
                      },
                    );
                  },
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Color:', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _colorPalette.map((color) {
                    final isSelected = _selectedColor == color;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedColor = color),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color,
                          border: Border.all(
                            color: isSelected ? Colors.blue : Colors.grey,
                            width: isSelected ? 3 : 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.3),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Text('Tips:', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                Text(
                  '• Light pressure = thin lines',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  '• Heavy pressure = thick lines',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  '• Works best with Apple Pencil, S-Pen, or Wacom stylus',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Text(
                  '• Tap the brush icon to switch modes',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (_shaderProgram != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    '• Tap the color lens icon to toggle shader effect',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
