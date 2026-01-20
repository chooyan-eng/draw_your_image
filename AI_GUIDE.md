# AI Guide for draw_your_image

This guide helps AI assistants generate accurate code when using the `draw_your_image` package.

## Package Overview

`draw_your_image` is a Flutter package for creating easily customizable drawing canvases with a declarative API.

### Key Characteristics

- **User-Controlled Behavior**: You have full control over stroke behavior through callbacks
  - Distinguish between input devices (stylus, finger, mouse)
  - Apply custom smoothing algorithms
  - Modify stroke properties (color, width, erasing mode) based on any criteria
  
- **Declarative API**: No imperative controllers required
  - Stroke data is managed in your widget state
  - Behavior is defined through callback functions
  - Few hidden state or side effects (except for ongoing stroke state)

### What This Package Does NOT Provide

The following features are intentionally left for you to implement (examples provided in this guide):

- **Undo/Redo functionality** - Manage stroke history in your state
- **Image conversion** - Export canvas to images using Flutter's rendering APIs
- **Canvas zoom/pan** - Use `InteractiveViewer` or similar widgets

This design keeps the package focused and allows you to implement these features exactly as your app needs them.

## Key Concepts

### Stroke

A `Stroke` represents a drawing stroke with the following properties:

```dart
class Stroke {
  PointerDeviceKind deviceKind;  // stylus, touch, mouse, etc.
  List<Offset> points;           // Points that compose the stroke
  Color color;                   // Stroke color
  double width;                  // Stroke width in logical pixels
  bool isErasing;                // Whether this stroke erases
}
```

### Device Types

Flutter provides the `PointerDeviceKind` enum to distinguish between input devices:

```dart
PointerDeviceKind.stylus          // Apple Pencil, S-Pen, etc.
PointerDeviceKind.touch           // Finger input
PointerDeviceKind.mouse           // Mouse input
PointerDeviceKind.invertedStylus  // Stylus eraser tip
```

### onStrokeStarted Callback

Called when a new pointer touches the screen. This is where you control stroke behavior.

```dart
Stroke? Function(Stroke newStroke, Stroke? currentStroke)
```

- **newStroke**: The stroke about to be started
- **currentStroke**: The stroke currently being drawn (null if none)
- **Return**: The stroke to draw, or null to reject

**Pattern**: Always check `currentStroke != null` first to handle ongoing strokes.

### Stylus Helper Extension

When working with stylus input, this extension method is convenient for checking device types:

```dart
/// Extension to check if PointerDeviceKind is stylus
extension on PointerDeviceKind {
  bool get isStylus =>
      this == PointerDeviceKind.stylus ||
      this == PointerDeviceKind.invertedStylus;
}
```

Usage example:

```dart
if (newStroke.deviceKind.isStylus) {
  // Handle stylus input
}
```

## Common Use Cases

### 1. Stylus-Only Drawing

Only accept stylus input, ignore finger and mouse.

```dart
Draw(
  strokes: _strokes,
  onStrokeDrawn: (stroke) {
    setState(() => _strokes.add(stroke));
  },
  onStrokeStarted: (newStroke, currentStroke) {
    // Continue current stroke if already drawing
    if (currentStroke != null) {
        return currentStroke;
    }
    
    // Only accept stylus input
    return newStroke.deviceKind.isStylus 
      ? newStroke 
      : null;
  },
)
```

### 2. Palm Rejection

Continue stylus stroke even when finger touches the screen.

```dart
Draw(
  strokes: _strokes,
  onStrokeDrawn: (stroke) {
    setState(() => _strokes.add(stroke));
  },
  onStrokeStarted: (newStroke, currentStroke) {
  return switch (currentStroke?.deviceKind.isStylus) {
    true => currentStroke,
    false => newStroke.deviceKind.isStylus ? newStroke : currentStroke,
    null => newStroke,
  };   
)
```

### 3. Stylus Draws, Finger Erases

Use stylus for drawing and finger for erasing.

```dart
Draw(
  strokes: _strokes,
  onStrokeDrawn: (stroke) {
    setState(() => _strokes.add(stroke));
  },
  onStrokeStarted: (newStroke, currentStroke) {
    if (currentStroke != null) {
      return currentStroke;
    }
    
    if (newStroke.deviceKind.isStylus)) {
      // Stylus: normal drawing
      return newStroke;
    } else {
      // Finger: eraser
      return newStroke.copyWith(
        isErasing: true,
        width: 20.0,
      );
    }
  },
)
```

### 4. Device-Specific Colors

Different colors for stylus and finger.

```dart
Draw(
  strokes: _strokes,
  onStrokeDrawn: (stroke) {
    setState(() => _strokes.add(stroke));
  },
  onStrokeStarted: (newStroke, currentStroke) {
    if (currentStroke != null) {
      return currentStroke;
    }
    
    final color = newStroke.deviceKind.isStylus
      ? Colors.black
      : Colors.red;
    
    return newStroke.copyWith(
      color: color,
      width: 4.0,
    );
  },
)
```

### 5. Device-Specific Widths

Thin lines for stylus, thick lines for finger.

```dart
Draw(
  strokes: _strokes,
  onStrokeDrawn: (stroke) {
    setState(() => _strokes.add(stroke));
  },
  onStrokeStarted: (newStroke, currentStroke) {
    if (currentStroke != null) {
      return currentStroke;
    }
    
    final width = newStroke.deviceKind.isStylus ? 2.0 : 8.0;
    
    return newStroke.copyWith(
      color: Colors.black,
      width: width,
    );
  },
)
```

## Complete Example Template

```dart
import 'dart:ui';
import 'package:draw_your_image/draw_your_image.dart';
import 'package:flutter/material.dart';

class DrawingCanvas extends StatefulWidget {
  @override
  State<DrawingCanvas> createState() => _DrawingCanvasState();
}

class _DrawingCanvasState extends State<DrawingCanvas> {
  List<Stroke> _strokes = [];

  void _clear() {
    setState(() => _strokes = []);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Drawing Canvas'),
        actions: [
          IconButton(
            icon: Icon(Icons.clear),
            onPressed: _strokes.isEmpty ? null : _clear,
          ),
        ],
      ),
      body: Draw(
        strokes: _strokes,
        strokeColor: Colors.black,
        strokeWidth: 4.0,
        backgroundColor: Colors.white,
        smoothingFunc: SmoothingMode.catmullRom.converter,
        onStrokeDrawn: (stroke) {
          setState(() {
            _strokes = [..._strokes, stroke];
          });
        },
        onStrokeStarted: (newStroke, currentStroke) {
          if (currentStroke != null) {
            return currentStroke;
          }
          
          // Customize behavior here
          return newStroke;
        },
      ),
    );
  }
}
```

## Smoothing Options

Available smoothing modes:

```dart
SmoothingMode.none.converter           // No smoothing
SmoothingMode.catmullRom.converter     // Catmull-Rom spline (recommended)
```

## Tips for AI Code Generation

### User Request Patterns

| User Says | Implementation |
|-----------|----------------|
| "Only stylus" | Check `deviceKind == PointerDeviceKind.stylus` |
| "Palm rejection" | Return a stroke which is `deviceKind == PointerDeviceKind.stylus` is `currentStroke` is `deviceKind != PointerDeviceKind.stylus`|
| "Finger erases" | Set `isErasing: true` for non-stylus input |
| "Different colors" | Use `copyWith(color: ...)` based on device |
| "Different widths" | Use `copyWith(width: ...)` based on device |

### Common Mistakes to Avoid

❌ **Forgetting to check currentStroke**
```dart
// Wrong: loses palm rejection
onStrokeStarted: (newStroke, currentStroke) {
  return newStroke.deviceKind == PointerDeviceKind.stylus ? newStroke : null;
}
```

✅ **Always check currentStroke first**
```dart
// Correct: maintains palm rejection
onStrokeStarted: (newStroke, currentStroke) {
  // if you always want to continue ongoing stroke, just check and return currentStroke
  if (currentStroke != null) {
    return currentStroke;
  }
  return newStroke.deviceKind == PointerDeviceKind.stylus ? newStroke : null;
}
```

❌ **Mutating strokes list directly**
```dart
// Wrong: won't trigger rebuild
_strokes.add(stroke);
```

✅ **Create new list for setState**
```dart
// Correct: triggers rebuild
_strokes = [..._strokes, stroke];
```

## Property Reference

### Draw Widget Properties

| Property | Type | Description |
|----------|------|-------------|
| `strokes` | `List<Stroke>` | List of strokes to display |
| `strokeColor` | `Color` | Default stroke color |
| `strokeWidth` | `double` | Default stroke width |
| `backgroundColor` | `Color` | Canvas background color |
| `smoothingFunc` | `Path Function(Stroke)` | Smoothing function |
| `onStrokeDrawn` | `void Function(Stroke)` | Called when stroke is complete |
| `onStrokeStarted` | `Stroke? Function(Stroke, Stroke?)` | Called when stroke starts. You can control wether to continue, modify, or prevent, with returning value |

### Stroke Methods

```dart
// Create a new stroke with modified properties
stroke.copyWith({
  List<Offset>? points,
  Color? color,
  double? width,
  bool? isErasing,
})
```

## Implementation Tips

### Undo/Redo

Use a redo stack to manage stroke history:

```dart
class _MyWidgetState extends State<MyWidget> {
  List<Stroke> _strokes = [];
  List<Stroke> _redoStack = [];

  bool get _canUndo => _strokes.isNotEmpty;
  bool get _canRedo => _redoStack.isNotEmpty;

  void _undo() {
    if (_canUndo) {
      setState(() {
        final lastStroke = _strokes.removeLast();
        _redoStack.add(lastStroke);
      });
    }
  }

  void _redo() {
    if (_canRedo) {
      setState(() {
        final stroke = _redoStack.removeLast();
        _strokes.add(stroke);
      });
    }
  }

  void _clear() {
    setState(() {
      _strokes = [];
      _redoStack = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: Icon(Icons.undo),
            onPressed: _canUndo ? _undo : null,
          ),
          IconButton(
            icon: Icon(Icons.redo),
            onPressed: _canRedo ? _redo : null,
          ),
        ],
      ),
      body: Draw(
        strokes: _strokes,
        onStrokeDrawn: (stroke) {
          setState(() {
            _strokes = [..._strokes, stroke];
            _redoStack = []; // Clear redo stack on new stroke
          });
        },
      ),
    );
  }
}
```

### Export to Image

Convert the canvas to an image using `RepaintBoundary`:

```dart
class _MyWidgetState extends State<MyWidget> {
  final GlobalKey _repaintKey = GlobalKey();
  List<Stroke> _strokes = [];

  Future<void> _saveImage() async {
    final boundary = _repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();
    // Save bytes to file or share
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: _repaintKey,
      child: Draw(
        strokes: _strokes,
        onStrokeDrawn: (stroke) => setState(() => _strokes.add(stroke)),
      ),
    );
  }
}
```

### Canvas Zoom/Pan

Use `InteractiveViewer` to add zoom and pan functionality:

```dart
class _MyWidgetState extends State<MyWidget> {
  List<Stroke> _strokes = [];
  bool _isDrawing = false;

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      // surpress scale/pan when drawing
      scaleEnabled: !_isDrawing,
      panEnabled: !_isDrawing, 
      child: Draw(
        strokes: _strokes,
        onStrokeDrawn: (stroke) {
          setState(() {
            _strokes.add(stroke);
            _isDrawing = false;
          });
        },
        onStrokeStarted(newStroke, _) {
          setState(() => _isDrawing = true);
          return newStroke;
        }
      ),
    );
  }
}
```

## Related Resources

- [Example App](./example/lib/main.dart) - Complete implementation with multiple modes
- [API Documentation](https://pub.dev/documentation/draw_your_image/latest/)
- [Package on pub.dev](https://pub.dev/packages/draw_your_image)
