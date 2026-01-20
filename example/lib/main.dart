import 'dart:ui';
import 'package:draw_your_image/draw_your_image.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'onStrokeStarted Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: MyHomePage(),
    );
  }
}

/// Drawing mode definition
enum DrawingMode {
  stylusOnly,
  stylusPrior,
  stylusDrawFingerErase,
  differentColors,
  differentWidths,
}

extension DrawingModeExtension on DrawingMode {
  String get displayName {
    switch (this) {
      case DrawingMode.stylusOnly:
        return 'Stylus Only';
      case DrawingMode.stylusPrior:
        return 'Stylus Priority';
      case DrawingMode.stylusDrawFingerErase:
        return 'Stylus Draw / Finger Erase';
      case DrawingMode.differentColors:
        return 'Different Colors';
      case DrawingMode.differentWidths:
        return 'Different Widths';
    }
  }

  String get description {
    switch (this) {
      case DrawingMode.stylusOnly:
        return 'Only accepts stylus input. Finger input is ignored.';
      case DrawingMode.stylusPrior:
        return 'Prioritizes stylus. Finger input is ignored while drawing with stylus.';
      case DrawingMode.stylusDrawFingerErase:
        return 'Draw with stylus and erase with finger.';
      case DrawingMode.differentColors:
        return 'Stylus draws in black, finger draws in red.';
      case DrawingMode.differentWidths:
        return 'Stylus draws thin lines, finger draws thick lines.';
    }
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var _strokes = <Stroke>[];
  var _currentMode = DrawingMode.stylusOnly;

  void _clear() {
    setState(() {
      _strokes = [];
    });
  }

  /// Returns the stroke handler for the current mode
  Stroke? Function(Stroke, Stroke?)? _getStrokeHandler() {
    switch (_currentMode) {
      case DrawingMode.stylusOnly:
        return stylusOnlyHandler;
      case DrawingMode.stylusPrior:
        return stylusPriorHandler;
      case DrawingMode.stylusDrawFingerErase:
        return _stylusDrawFingerEraseHandler;
      case DrawingMode.differentColors:
        return _differentColorsHandler;
      case DrawingMode.differentWidths:
        return _differentWidthsHandler;
    }
  }

  /// Handler for stylus drawing and finger erasing
  Stroke? _stylusDrawFingerEraseHandler(
      Stroke newStroke, Stroke? currentStroke) {
    // Continue current stroke if already drawing
    if (currentStroke != null) {
      return currentStroke;
    }

    // Stylus for normal drawing
    if (_isStylus(newStroke.deviceKind)) {
      return newStroke.copyWith(
        color: Colors.black,
        width: 4.0,
        isErasing: false,
      );
    }

    // Finger for erasing
    return newStroke.copyWith(
      isErasing: true,
      width: 20.0,
    );
  }

  /// Handler for different colors by device
  Stroke? _differentColorsHandler(Stroke newStroke, Stroke? currentStroke) {
    // Continue current stroke if already drawing
    if (currentStroke != null) {
      return currentStroke;
    }

    // Stylus: black, Finger: red
    final color = _isStylus(newStroke.deviceKind) ? Colors.black : Colors.red;
    return newStroke.copyWith(
      color: color,
      width: 4.0,
    );
  }

  /// Handler for different widths by device
  Stroke? _differentWidthsHandler(Stroke newStroke, Stroke? currentStroke) {
    // Continue current stroke if already drawing
    if (currentStroke != null) {
      return currentStroke;
    }

    // Stylus: thin line, Finger: thick line
    final width = _isStylus(newStroke.deviceKind) ? 2.0 : 8.0;
    return newStroke.copyWith(
      color: Colors.black,
      width: width,
    );
  }

  /// Check if the device kind is stylus
  bool _isStylus(PointerDeviceKind kind) {
    return kind == PointerDeviceKind.stylus ||
        kind == PointerDeviceKind.invertedStylus;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('onStrokeStarted Demo'),
        actions: [
          IconButton(
            icon: Icon(Icons.clear),
            onPressed: _strokes.isEmpty ? null : _clear,
            tooltip: 'Clear',
          ),
        ],
      ),
      body: Column(
        children: [
          // Mode selection area
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mode Selection',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                DropdownButton<DrawingMode>(
                  value: _currentMode,
                  isExpanded: true,
                  items: DrawingMode.values.map((mode) {
                    return DropdownMenuItem(
                      value: mode,
                      child: Text(mode.displayName),
                    );
                  }).toList(),
                  onChanged: (mode) {
                    if (mode != null) {
                      setState(() {
                        _currentMode = mode;
                        _strokes = []; // Clear on mode change
                      });
                    }
                  },
                ),
                SizedBox(height: 8),
                Text(
                  _currentMode.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
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
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Draw(
                  strokes: _strokes,
                  strokeColor: Colors.black,
                  strokeWidth: 4.0,
                  backgroundColor: Colors.white,
                  smoothingFunc: SmoothingMode.catmullRom.converter,
                  onStrokeDrawn: (stroke) {
                    setState(() => _strokes = [..._strokes, stroke]);
                  },
                  onStrokeStarted: _getStrokeHandler(),
                ),
              ),
            ),
          ),
          // Instructions area
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            color: Colors.blue[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '💡 How to Use',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[900],
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Select a mode and try drawing with both stylus and finger.\n'
                  'You can see how the behavior differs depending on the mode.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue[800],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
