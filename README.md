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
      this == PointerDeviceKind.stylus ||
      this == PointerDeviceKind.invertedStylus;
}

Draw(
  strokes: _strokes,
  onStrokeDrawn: (stroke) => setState(() => _strokes = [..._strokes, stroke]),
  onStrokeStarted: (newStroke, currentStroke) {
    if (currentStroke != null) return currentStroke;

    if (newStroke.deviceKind.isStylus) {
      // if stylus, draw black line
      return newStroke.copyWith(color: Colors.black);
    } else {
      // if finger, pixel eraser — tag with data so strokePainter can identify it
      return newStroke.copyWith(data: {#erasing: true}, width: 20.0);
    }
  },
  strokePainter: (stroke) =>
      stroke.data?[#erasing] == true
          ? [eraseWithDefault(stroke)]
          : [paintWithDefault(stroke)],
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
| `onStrokesSelected` | `void Function(List<Stroke>)` |  | Called when strokes are selected |
| `strokeColor` | `Color` |  | Default stroke color |
| `strokeWidth` | `double` |  | Default stroke width |
| `backgroundColor` | `Color` |  | Canvas background color |
| `pathBuilder` | `Path Function(Stroke)` |  | Function to build `Path` from a `Stroke`. Use for smoothing or pressure-sensitive effects |
| `strokePainter` | `List<Paint> Function(Stroke)` |  | Custom stroke painting function |
| `intersectionDetector` | `IntersectionDetector` |  | Custom intersection detection function |
| `shouldAbsorbScale` | `bool Function(PointerDownEvent)` |  | Control whether to absorb scale/pan pointer events from parent widgets like `InteractiveViewer` |
| `shouldAbsorbLongPress` | `bool Function(PointerDownEvent)` |  | Control whether to absorb long press pointer events from parent widgets like `GestureDetector` |

### Stroke Properties

```dart
class Stroke {
  PointerDeviceKind deviceKind;     // Input device type
  List<StrokePoint> points;         // Stroke points with pressure/tilt data
  Color color;                      // Stroke color
  double width;                     // Stroke width
}
```

### StrokePoint

Each point in a stroke contains rich input data:

```dart
class StrokePoint {
  final Offset position;       // Position of the point
  final double pressure;       // Raw pressure (0.0 to 1.0+)
  final double pressureMin;    // Minimum pressure for this device
  final double pressureMax;    // Maximum pressure for this device
  final double tilt;           // Stylus tilt angle (0 to π/2 radians)
  final double orientation;    // Stylus orientation (-π to π radians)
  
  // Normalized pressure getter (0.0 to 1.0)
  double get normalizedPressure;
}
```

Note that all the parameters are originated in Flutter's `PointerEvent`. See documentation of `PointerEvent` for detailed information.

**Key features:**
- `tilt` and `orientation` enable calligraphy-style effects
- `normalizedPressure` automatically adjusts for device-specific pressure ranges
- Works seamlessly with all input devices (stylus, touch, mouse)

## Path Builder Modes

Path building algorithm is also customizable. You can choose pre-defined modes below or provide your own `Path Function(Stroke)`.

```dart
PathBuilderMode.catmullRom.converter        // Smooth curves (default)
PathBuilderMode.none.converter              // No smoothing (straight lines)
PathBuilderMode.pressureSensitive.converter // Variable-width based on pressure
```

## Pressure-Sensitive Drawing

Create variable-width strokes that respond to stylus pressure using `PathBuilderMode.pressureSensitive`:

```dart
Draw(
  strokes: _strokes,
  strokeWidth: 8.0,
  pathBuilder: PathBuilderMode.pressureSensitive.converter,
  onStrokeDrawn: (stroke) => setState(() => _strokes.add(stroke)),
)
```

### Tilt-Based Effects

For advanced calligraphy effects using stylus tilt and orientation:

```dart
Path calligraphyPath(Stroke stroke) {
  for (final point in stroke.points) {
    // More tilt (flat stylus) = wider stroke
    final tiltFactor = 1.0 + (point.tilt / (math.pi / 2)) * 1.5;
    final width = baseWidth * tiltFactor * point.normalizedPressure;
    
    // Use orientation to rotate brush angle
    final angle = point.orientation;
    // ... create path with rotated brush shape
  }
}

Draw(
  pathBuilder: calligraphyPath,
  // ...
)
```

See [example/lib/pages/tilt_demo_page.dart](example/lib/pages/tilt_demo_page.dart) for a complete implementation.

## Custom Stroke Painting with `strokePainter`

The `strokePainter` callback allows you to fully customize how strokes are rendered. You can create advanced visual effects like gradients, glows, shadows, and shader effects by returning multiple `Paint` objects.

```dart
Draw(
  strokePainter: (Stroke stroke) {
    final List<Paint> paint = _buildYourPaint(stroke);
    return paint;
  },
)
```

**Parameters:**
- `stroke` - The stroke to be painted

**Return:**
- A list of `Paint` objects to be applied to the stroke (in order)

### Example: Gradient Effect

```dart
LayoutBuilder(
  builder: (context, constraints) {
    final canvasSize = Size(constraints.maxWidth, constraints.maxHeight);

    return Draw(
      strokes: _strokes,
      onStrokeDrawn: (stroke) => setState(() => _strokes.add(stroke)),
      strokePainter: (stroke) {
        final gradient = ui.Gradient.linear(
          Offset.zero,
          Offset(canvasSize.width, canvasSize.height),
          [Colors.blue, Colors.purple, Colors.pink],
        );

        return [
          Paint()
            ..shader = gradient
            ..strokeWidth = stroke.width
            ..strokeCap = StrokeCap.round
            ..style = PaintingStyle.stroke,
        ];
      },
    );
  },
)
```

### Example: Multi-Layer Effect (Glow)

```dart
strokePainter: (stroke) {
  return [
    // Outer glow
    paintWithOverride(stroke, strokeWidth: stroke.width + 8, strokeColor: Colors.cyan)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    // Inner glow
    paintWithOverride(stroke, strokeWidth: stroke.width + 4, strokeColor: Colors.blue)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    // Core stroke
    paintWithDefault(stroke),
  ];
}
```

### Helper Functions

The package provides utility functions for creating `Paint` objects:

- `paintWithDefault` - Creates a paint with default properties
- `paintWithOverride` - Creates a paint with overridden properties
- `eraseWithDefault` - Creates a paint with `BlendMode.clear` for pixel-level erasing

## Using with InteractiveViewer

The `shouldAbsorbScale` callback allows you to control which pointer events are handled by the `Draw` widget versus parent widgets like `InteractiveViewer`. This enables powerful combinations like:

- **Touch for pan/zoom, stylus for drawing**
- **Device-specific gesture handling**
- **Conditional pointer event absorption**

```dart
InteractiveViewer(
  child: Draw(
    strokes: _strokes,
    shouldAbsorbScale: (event) {
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
