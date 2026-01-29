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
  PointerDeviceKind deviceKind;     // stylus, touch, mouse, etc.
  List<Offset> points;              // Points that compose the stroke
  Color color;                      // Stroke color
  double width;                     // Stroke width in logical pixels
  ErasingBehavior erasingBehavior;  // Erasing behavior (none/pixel/stroke)
}
```

### ErasingBehavior

```dart
enum ErasingBehavior {
  none,   // Normal drawing (default)
  pixel,  // Pixel-level erasing - erases only overlapping pixels using BlendMode.clear
  stroke, // Stroke-level erasing - removes entire strokes that intersect
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

### onStrokeUpdated Callback

Called every time a point is added to the current stroke during drawing. This enables real-time stroke manipulation.

```dart
Stroke? Function(Stroke currentStroke)
```

- **currentStroke**: The stroke being drawn with the newly added point
- **Return**: The modified stroke to continue drawing, or null to cancel

**Key features**:
- Called for each pointer move event during drawing
- Allows real-time filtering, transformation, or styling
- Can cancel the stroke by returning null
- Enables dynamic effects that respond to stroke length, shape, or other properties

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

### 6. Trailing Effect (Last N Points Only)

Show only the last 30 points of the current stroke, creating a trailing effect.

```dart
Draw(
  strokes: _strokes,
  onStrokeDrawn: (stroke) {
    setState(() => _strokes.add(stroke));
  },
  onStrokeUpdated: (currentStroke) {
    return currentStroke.copyWith(
      points: currentStroke.points.length > 30
          ? currentStroke.points.sublist(currentStroke.points.length - 30)
          : currentStroke.points,
    );
  },
)
```

### 7. Dynamic Color Change

Change stroke color gradually based on length (longer = more visible).

```dart
Draw(
  strokes: _strokes,
  onStrokeDrawn: (stroke) {
    setState(() => _strokes.add(stroke));
  },
  onStrokeUpdated: (currentStroke) {
    final pointCount = currentStroke.points.length;
    final ratio = (pointCount / 500).clamp(0.0, 1.0);
    
    final newColor = Color.lerp(
      currentStroke.color,
      Colors.red,
      ratio,
    );
    
    return currentStroke.copyWith(color: newColor);
  },
)
```

### 8. Shape Recognition (Rectangle)

Convert ongoing stroke to a rectangle shape using first and last points.

```dart
Draw(
  strokes: _strokes,
  smoothingFunc: SmoothingMode.none.converter, // Disable smoothing for sharp corners
  onStrokeDrawn: (stroke) {
    setState(() => _strokes.add(stroke));
  },
  onStrokeUpdated: (currentStroke) {
    return currentStroke.points.length > 2
        ? currentStroke.copyWith(
            points: [
              currentStroke.points.first,
              Offset(
                currentStroke.points.first.dx,
                currentStroke.points.last.dy,
              ),
              currentStroke.points.last,
              Offset(
                currentStroke.points.last.dx,
                currentStroke.points.first.dy,
              ),
              currentStroke.points.first,
            ],
          )
        : currentStroke;
  },
)
```

### 9. Point Filtering/Resampling

Keep only points that are a certain distance apart for performance optimization.

```dart
Draw(
  strokes: _strokes,
  onStrokeDrawn: (stroke) {
    setState(() => _strokes.add(stroke));
  },
  onStrokeUpdated: (currentStroke) {
    if (currentStroke.points.length < 2) {
      return currentStroke;
    }
    
    final filtered = <Offset>[currentStroke.points.first];
    const minDistance = 5.0;
    
    for (final point in currentStroke.points.skip(1)) {
      final lastPoint = filtered.last;
      final distance = (point - lastPoint).distance;
      
      if (distance >= minDistance) {
        filtered.add(point);
      }
    }
    
    return currentStroke.copyWith(points: filtered);
  },
)
```

### 10. Stroke Length Limit

Cancel stroke automatically when it exceeds a certain length.

```dart
Draw(
  strokes: _strokes,
  onStrokeDrawn: (stroke) {
    setState(() => _strokes.add(stroke));
  },
  onStrokeUpdated: (currentStroke) {
    // Cancel stroke if it gets too long
    return currentStroke.points.length > 1000 ? null : currentStroke;
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
| `erasingBehavior` | `ErasingBehavior` | Erasing mode (none/pixel/stroke) |
| `smoothingFunc` | `Path Function(Stroke)` | Smoothing function |
| `intersectionDetector` | `IntersectionDetector` | Custom intersection detection function for stroke-level erasing |
| `shouldAbsorb` | `bool Function(PointerDownEvent)` | Control whether to absorb pointer events from parent widgets |
| `onStrokeDrawn` | `void Function(Stroke)` | Called when stroke is complete |
| `onStrokeStarted` | `Stroke? Function(Stroke, Stroke?)` | Called when stroke starts. Control whether to continue, modify, or prevent with return value |
| `onStrokeUpdated` | `Stroke? Function(Stroke)` | Called when a point is added to current stroke. Enables real-time stroke manipulation |
| `onStrokesRemoved` | `void Function(List<Stroke>)` | Called when strokes are removed by stroke-level erasing |

### Stroke Methods

```dart
// Create a new stroke with modified properties
stroke.copyWith({
  List<Offset>? points,
  Color? color,
  double? width,
  ErasingBehavior? erasingBehavior,
})
```

## Implementation Tips

### Undo/Redo

**Recommended approach: Stack entire state snapshots**

Instead of stacking individual strokes, stack the entire state (`List<Stroke>`) for each action. This approach is simpler and handles all operations (add, remove, modify) consistently.

```dart
/// Type definition for state snapshot
typedef StrokeState = List<Stroke>;

class _MyWidgetState extends State<MyWidget> {
  List<Stroke> _strokes = [];
  
  /// Undo and redo stacks store complete state snapshots
  List<StrokeState> _undoStack = [];
  List<StrokeState> _redoStack = [];

  bool get _canUndo => _undoStack.isNotEmpty;
  bool get _canRedo => _redoStack.isNotEmpty;

  void _undo() {
    if (_canUndo) {
      setState(() {
        // Save current state to redo stack
        _redoStack.add(List.from(_strokes));
        
        // Restore previous state from undo stack
        _strokes = _undoStack.removeLast();
      });
    }
  }

  void _redo() {
    if (_canRedo) {
      setState(() {
        // Save current state to undo stack
        _undoStack.add(List.from(_strokes));
        
        // Restore next state from redo stack
        _strokes = _redoStack.removeLast();
      });
    }
  }

  void _clear() {
    setState(() {
      _strokes = [];
      _undoStack = [];
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
            // Save current state before modifying
            _undoStack.add(List.from(_strokes));
            
            // Add new stroke
            _strokes = [..._strokes, stroke];
            
            // Clear redo stack on new action
            _redoStack = [];
          });
        },
        onStrokesRemoved: (removedStrokes) {
          setState(() {
            // Save current state before modifying
            _undoStack.add(List.from(_strokes));
            
            // Remove strokes
            _strokes = _strokes
                .where((s) => !removedStrokes.contains(s))
                .toList();
            
            // Clear redo stack on new action
            _redoStack = [];
          });
        },
      ),
    );
  }
}
```

**Why this approach?**
- **Simpler**: No need to track what changed (add/remove/modify)
- **Consistent**: Works for all operations uniformly
- **Reliable**: Always maintains correct state

**Note**: For apps with very large canvases (1000s of strokes), consider using a more memory-efficient approach like storing only deltas.

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

### Canvas Zoom/Pan with InteractiveViewer

There are two approaches to integrate `Draw` with `InteractiveViewer` for zoom/pan functionality:

#### Approach 1: Disable InteractiveViewer while drawing (Simple)

Disable pan/zoom gestures while drawing using state management:

```dart
class _MyWidgetState extends State<MyWidget> {
  List<Stroke> _strokes = [];
  bool _isDrawing = false;

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      // suppress scale/pan when drawing
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
        onStrokeStarted: (newStroke, _) {
          setState(() => _isDrawing = true);
          return newStroke;
        }
      ),
    );
  }
}
```

**Pros**: Simple, works for all input devices
**Cons**: Requires state management, always disables pan/zoom while drawing

#### Approach 2: Device-specific absorption with shouldAbsorb (Recommended)

Use `shouldAbsorb` to selectively absorb pointer events based on device type. This allows touch for pan/zoom while stylus for drawing:

```dart
class _MyWidgetState extends State<MyWidget> {
  List<Stroke> _strokes = [];

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      child: Draw(
        strokes: _strokes,
        // Absorb stylus events, let touch events pass through to InteractiveViewer
        shouldAbsorb: (event) {
          return event.kind == PointerDeviceKind.stylus ||
                 event.kind == PointerDeviceKind.invertedStylus;
        },
        onStrokeDrawn: (stroke) {
          setState(() => _strokes.add(stroke));
        },
        onStrokeStarted: (newStroke, currentStroke) {
          if (currentStroke != null) {
            return currentStroke;
          }
          // Only draw with stylus
          if (newStroke.deviceKind == PointerDeviceKind.stylus) {
            return newStroke;
          }
          // Ignore touch (let it be handled by InteractiveViewer)
          return null;
        },
      ),
    );
  }
}
```

**Pros**: 
- Touch can be used for pan/zoom (InteractiveViewer)
- Stylus can be used for drawing (Draw widget)
- No state management needed
- Natural separation of concerns

**Cons**: Requires devices that support both touch and stylus

**Key Points**:
- `shouldAbsorb` returns `true` to absorb pointer events (prevent from reaching InteractiveViewer)
- `shouldAbsorb` returns `false` to let pointer events pass through (allow InteractiveViewer to handle)
- Common pattern: absorb stylus, pass through touch
- Must coordinate with `onStrokeStarted` to ensure consistent behavior

**Important**: When using `shouldAbsorb`, make sure `onStrokeStarted` behavior matches. If you absorb stylus events, you should also handle them in `onStrokeStarted`. If you don't absorb touch events, you should typically return `null` for touch in `onStrokeStarted`.

## Related Resources

- [Example App](./example/lib/main.dart) - Complete implementation with multiple modes
- [API Documentation](https://pub.dev/documentation/draw_your_image/latest/)
- [Package on pub.dev](https://pub.dev/packages/draw_your_image)
