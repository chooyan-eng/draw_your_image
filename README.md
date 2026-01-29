# draw_your_image

A Flutter package for creating customizable drawing canvases with a declarative API.

![demo gif of draw_your_image](https://github.com/chooyan-eng/draw_your_image/raw/main/assets/draw_your_image_demo.gif)

## Core Concept

**Fully declarative, fully customizable**

- **No controllers required** - Manage stroke data in your widget state
- **Customize everything** - Control stroke behavior through simple callbacks
- **Bring your own features** - Implement undo/redo, zoom/pan, image export as your app needs

This package focuses on providing a flexible drawing widget, leaving app-specific features to you.

## Features

✨ **Device-aware drawing** - Distinguish between stylus, finger, and mouse input  
🎨 **Flexible stroke handling** - Customize behavior per input device or any other criteria  
🖌️ **Built-in smoothing** - Catmull-Rom spline interpolation included  
⚙️ **Fully customizable** - Colors, widths, smoothing algorithms  
🧹 **Multiple erasing modes** - Pixel-level and stroke-level erasing  
🔍 **Intersection detection** - Customizable stroke overlap detection

## Quick Start

```dart
class MyDrawingPage extends StatefulWidget {
  @override
  _MyDrawingPageState createState() => _MyDrawingPageState();
}

class _MyDrawingPageState extends State<MyDrawingPage> {
  /// Store all the strokes on app side as state
  List<Stroke> _strokes = [];

  @override
  Widget build(BuildContext context) {
    return Draw(
      strokes: _strokes, // pass strokes via 
      onStrokeDrawn: (stroke) {
        // store new drawn stroke and rebuild
        setState(() {
          _strokes = [..._strokes, stroke];
        });
      },
    );
  }
}
```

That's it! The canvas accepts any input and draws with default settings.

## Device-Aware Drawing with `onStrokeStarted`

The `onStrokeStarted` callback lets you control stroke behavior based on input devices or any other criteria.

```dart
Stroke? Function(Stroke newStroke, Stroke? currentStroke)
```

**Parameters:**
- `newStroke` - The stroke about to be started
- `currentStroke` - The stroke currently being drawn (null if none)

**Return:**
- The stroke to draw (can be `newStroke`, `currentStroke`, or a modified version)
- `null` to reject the stroke

### Example: Stylus draws, finger erases

If you want to draw lines with stylus while erase them with a finger, the function can be implemented like below:

```dart
extension on PointerDeviceKind {
  bool get isStylus =>
      this ||
      this == PointerDeviceKind.invertedStylus;
}

Stroke? customHandler(Stroke newStroke, Stroke? currentStroke) {
  // if we have an ongoing stroke, just continue.
  if (currentStroke != null) {
    return currentStroke;
  }
  
  if (newStroke.deviceKind == PointerDeviceKind.stylus) {
    // if stylus, draw black line
    return newStroke.copyWith(color: Colors.black);
  } else {
    // if finger, erasor mode
    return newStroke.copyWith(isErasing: true, width: 20.0);
  }
}

Draw(
  strokes: _strokes,
  onStrokeDrawn: (stroke) => setState(() => _strokes.add(stroke)),
  onStrokeStarted: customHandler,
)
```

### Example: Stylus-only drawing

If pre-defined utility functions fit to your needs, you can pick one of them.

```dart
Draw(
  strokes: _strokes,
  onStrokeDrawn: (stroke) => setState(() => _strokes.add(stroke)),
  onStrokeStarted: stylusOnlyHandler,  // Pre-defined utility
)
```

### Pre-defined Utilities

- `stylusOnlyHandler` - Accept only stylus input
- `stylusPriorHandler` - Prioritize stylus when drawing (palm rejection)

## API Reference

### Draw Widget Properties

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `strokes` | `List<Stroke>` | ✓ | List of strokes to display |
| `onStrokeDrawn` | `void Function(Stroke)` | ✓ | Called when a stroke is complete |
| `onStrokeStarted` | `Stroke? Function(Stroke, Stroke?)` |  | Control stroke behavior based on input |
| `onStrokeUpdated` | `Stroke? Function(Stroke)` |  | Modify stroke in real-time as points are added |
| `onStrokesRemoved` | `void Function(List<Stroke>)` |  | Called when strokes are removed by erasing |
| `strokeColor` | `Color` |  | Default stroke color |
| `strokeWidth` | `double` |  | Default stroke width |
| `backgroundColor` | `Color` |  | Canvas background color |
| `erasingBehavior` | `ErasingBehavior` |  | Erasing mode (`none`, `pixel`, `stroke`) |
| `smoothingFunc` | `Path Function(Stroke)` |  | Custom smoothing function |
| `intersectionDetector` | `IntersectionDetector` |  | Custom intersection detection function |
| `shouldAbsorb` | `bool Function(PointerDownEvent)` |  | Control whether to absorb pointer events |

### Stroke Properties

```dart
class Stroke {
  PointerDeviceKind deviceKind;     // Input device type
  List<Offset> points;              // Stroke points
  Color color;                      // Stroke color
  double width;                     // Stroke width
  ErasingBehavior erasingBehavior;  // Erasing mode
}
```

### ErasingBehavior

```dart
enum ErasingBehavior {
  none,   // Normal drawing (default)
  pixel,  // Pixel-level erasing (BlendMode.clear)
  stroke, // Stroke-level erasing (removes entire strokes)
}
```

## Smoothing Modes

Smoothing algorithm is also customizable. You can choose pre-defined functions below or make your own function.

```dart
SmoothingMode.catmullRom.converter  // Smooth curves (default)
SmoothingMode.none.converter        // No smoothing (straight lines)
```

## Using with InteractiveViewer

The `shouldAbsorb` callback allows you to control which pointer events are handled by the `Draw` widget versus parent widgets like `InteractiveViewer`. This enables powerful combinations like:

- **Touch for pan/zoom, stylus for drawing**
- **Device-specific gesture handling**
- **Conditional pointer event absorption**

```dart
InteractiveViewer(
  child: Draw(
    strokes: _strokes,
    shouldAbsorb: (event) {
      // Absorb stylus events for drawing, let touch events pass through for pan/zoom
      return event.kind == PointerDeviceKind.stylus ||
             event.kind == PointerDeviceKind.invertedStylus;
    },
    onStrokeDrawn: (stroke) => setState(() => _strokes.add(stroke)),
    onStrokeStarted: (newStroke, currentStroke) {
      if (currentStroke != null) return currentStroke;
      // Only draw with stylus (touch is for pan/zoom)
      return newStroke.deviceKind == PointerDeviceKind.stylus ? newStroke : null;
    },
  ),
)
```

See the [example app](example/lib/main.dart) for a complete implementation of touch-for-pan/stylus-for-draw functionality.

## Working with AI Assistants

This package is designed to work well with AI coding assistants. If you want accurate response from AI agents, refer [AI_GUIDE.md](https://github.com/chooyan-eng/draw_your_image/blob/main/AI_GUIDE.md) before asking.
