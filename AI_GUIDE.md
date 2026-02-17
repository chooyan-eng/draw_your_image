# AI Guide for draw_your_image

This guide helps AI assistants generate accurate code when using the `draw_your_image` package.

## Package Overview

`draw_your_image` is a Flutter package for creating easily customizable drawing canvases with a declarative API.

### Key Characteristics

- **User-Controlled Behavior**: You have full control over stroke behavior through callbacks
  - Distinguish between input devices (stylus, finger, mouse)
  - Apply custom smoothing algorithms
  - Modify stroke properties (color, width, custom data) based on any criteria
  
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
  PointerDeviceKind deviceKind;         // stylus, touch, mouse, etc.
  List<StrokePoint> points;             // Points that compose the stroke
  Color color;                          // Stroke color
  double width;                         // Stroke width in logical pixels
  Map<Object, dynamic>? data;           // User-defined additional data
}
```

The `data` field allows you to attach arbitrary metadata to each stroke. This is useful for distinguishing stroke types (e.g., eraser vs. normal drawing) or storing any application-specific information. You can use any object as a key (symbols, enums, strings, etc.).

### StrokePoint

A `StrokePoint` represents a single point in a stroke with rich input data from the pointer device:

```dart
class StrokePoint {
  final Offset position;       // Position of the point
  final double pressure;       // Pressure at this point (0.0 to 1.0+)
  final double pressureMin;    // Minimum pressure value for this pointer
  final double pressureMax;    // Maximum pressure value for this pointer
  final double tilt;           // Tilt angle in radians (0 to π/2)
  final double orientation;    // Orientation angle in radians (-π to π)
  
  // Normalized pressure getter
  double get normalizedPressure; // Returns (pressure - pressureMin) / (pressureMax - pressureMin)
}
```

**Key properties:**

- **position**: The (x, y) coordinate of the point
- **pressure**: Raw pressure value from the device. For devices without pressure support (mice), typically 0.5 or 1.0
- **pressureMin/pressureMax**: Device-specific pressure range. For devices without pressure support, both are 1.0
- **tilt**: For stylus input, the angle of the stylus relative to the surface (0 = perpendicular, π/2 = flat)
- **orientation**: For stylus input, the direction the stylus is pointing in the plane of the surface
- **normalizedPressure**: Convenience getter that normalizes pressure to 0.0-1.0 range. Returns 0.5 if pressureMin equals pressureMax (no variation possible)

**Usage example:**

```dart
// Access point data
final point = stroke.points.first;
print('Position: ${point.position}');
print('Raw pressure: ${point.pressure}');
print('Normalized pressure: ${point.normalizedPressure}');
print('Tilt angle: ${point.tilt}');

// Use normalized pressure for consistent width
final width = baseWidth * point.normalizedPressure;
```

### Erasing and Stroke Selection

This package does **not** provide a built-in "eraser mode" enum or property. Instead, erasing is achieved by composing existing features:

- **Pixel erasing** (erasing overlapping pixels): Use `strokePainter` to return `eraseWithDefault(stroke)` for eraser strokes. This applies `BlendMode.clear` to erase pixels where the stroke passes.
- **Stroke-level erasing** (removing entire strokes): Use `intersectionDetector` to detect intersecting strokes, and `onStrokesSelected` to handle the removal.

Use `Stroke.data` to tag each stroke with metadata (e.g., `{#erasing: true}`) so that `strokePainter` can distinguish eraser strokes from normal drawing strokes.

See [Erasing and Stroke Selection](#erasing-and-stroke-selection-1) in Common Use Cases for full examples.

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

### 3. Stylus Draws, Finger Erases (Pixel Erasing)

Use stylus for drawing and finger for pixel-level erasing. Tag eraser strokes with `data` and use `strokePainter` to apply `eraseWithDefault`.

```dart
Draw(
  strokes: _strokes,
  onStrokeDrawn: (stroke) {
    setState(() => _strokes = [..._strokes, stroke]);
  },
  onStrokeStarted: (newStroke, currentStroke) {
    if (currentStroke != null) {
      return currentStroke;
    }

    if (newStroke.deviceKind.isStylus) {
      // Stylus: normal drawing
      return newStroke;
    } else {
      // Finger: pixel eraser
      return newStroke.copyWith(
        data: {#erasing: true},
        width: 20.0,
      );
    }
  },
  strokePainter: (stroke) =>
      stroke.data?[#erasing] == true
          ? [eraseWithDefault(stroke)]
          : [paintWithDefault(stroke)],
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
  pathBuilder: PathBuilderMode.none.converter, // Disable smoothing for sharp corners
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

## Advanced Stroke Rendering with strokePainter

The `strokePainter` callback enables advanced visual effects by giving you full control over how strokes are rendered. Instead of using a single paint configuration, you can return multiple `Paint` objects that are applied in sequence, enabling effects like multi-layer strokes with borders, shadows, gradients, and fragment shader effects.

### What is strokePainter?

`strokePainter` is a callback function that takes a `Stroke` and returns a list of `Paint` objects:

```dart
typedef StrokePainter = List<Paint> Function(Stroke stroke);
```

**Key characteristics:**
- Called once per stroke during rendering
- Returns a list of `Paint` objects that are applied sequentially to the stroke path
- Each `Paint` is drawn on the same stroke path
- Later paints are drawn on top of earlier ones (layering effect)
- If not provided, uses `defaultStrokePainter` which renders solid color strokes

**Default behavior:**
```dart
List<Paint> defaultStrokePainter(Stroke stroke) => [
  paintWithDefault(stroke),
];
```

### How strokePainter Works

The `Draw` widget calls your `strokePainter` function for each stroke and applies all returned paints to the stroke path:

```dart
// Simplified rendering logic
for (final stroke in strokes) {
  final path = pathBuilder(stroke);       // Build Path from stroke
  final paints = strokePainter(stroke);   // Your custom function

  for (final paint in paints) {
    canvas.drawPath(path, paint);         // Draw each paint in order
  }
}
```

**Important notes:**
- All paints are drawn on the same path (the stroke's smoothed points)
- Order matters: first paint is drawn first (bottom layer), last paint is on top
- If you need canvas size (e.g., for gradients or shaders), use `LayoutBuilder` to measure the `Draw` widget's size - the canvas will be the same size

### Utility Functions

The package provides utility functions to simplify `Paint` creation:

**`paintWithDefault(Stroke stroke)`**

Creates a `Paint` with the stroke's default properties:
- Uses `stroke.color` for color
- Uses `stroke.width` for stroke width
- Sets `StrokeCap.round` for rounded ends
- Sets `PaintingStyle.stroke` for outline drawing

```dart
strokePainter: (stroke) => [paintWithDefault(stroke)]
```

**`paintWithOverride(Stroke stroke, {...})`**

Creates a `Paint` with overridden properties while keeping defaults for unspecified values:

Parameters:
- `strokeColor` - Override the stroke color (defaults to `stroke.color`)
- `strokeWidth` - Override the stroke width (defaults to `stroke.width`)
- `strokeCap` - Override the stroke cap style (defaults to `StrokeCap.round`)
- `style` - Override the painting style (defaults to `PaintingStyle.stroke`)

```dart
strokePainter: (stroke) => [
  paintWithOverride(stroke,
    strokeWidth: stroke.width * 2,
    strokeColor: Colors.black,
  ),
]
```

**`eraseWithDefault(Stroke stroke)`**

Creates a `Paint` with `BlendMode.clear` for pixel-level erasing. Use this in `strokePainter` to make a stroke act as an eraser:

```dart
strokePainter: (stroke) =>
    stroke.data?[#erasing] == true
        ? [eraseWithDefault(stroke)]
        : [paintWithDefault(stroke)],
```

### Common Use Cases with strokePainter

#### 1. Paint Layering for Borders and Outlines

Create strokes with multiple layers to add borders, shadows, and highlights by returning multiple paint objects.

```dart
List<Paint> multiLayerPainter(Stroke stroke) {
  return [
    // Layer 1: Drop shadow (bottom layer)
    paintWithOverride(
      stroke,
      strokeWidth: stroke.width + 6,
      strokeColor: Colors.black26,
    )..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),

    // Layer 2: Outer border
    paintWithOverride(
      stroke,
      strokeWidth: stroke.width + 4,
      strokeColor: Colors.black,
    ),

    // Layer 3: White highlight border
    paintWithOverride(
      stroke,
      strokeWidth: stroke.width + 2,
      strokeColor: Colors.white70,
    ),

    // Layer 4: Main stroke (top layer)
    paintWithOverride(
      stroke,
      strokeWidth: stroke.width,
      strokeColor: Colors.blue,
    ),
  ];
}

// Usage
Draw(
  strokes: _strokes,
  strokeWidth: 8.0,
  onStrokeDrawn: (stroke) => setState(() => _strokes.add(stroke)),
  strokePainter: multiLayerPainter,
)
```

**Key points:**
- Return multiple paints in a list
- First paint = bottom layer, last paint = top layer
- Increment stroke width for each outer layer
- Use `..maskFilter` for blur/glow effects
- This example does NOT need LayoutBuilder since it doesn't use canvas size

#### 2. Fragment Shader for Rich Stroke Rendering

Use Flutter's Fragment Shaders for dynamic, GPU-accelerated effects.

**Shader file** (`shaders/tint.frag`):

```glsl
#version 460 core
#include <flutter/runtime_effect.glsl>

uniform float u_time;
uniform vec2 u_resolution;

out vec4 fragColor;

void main() {
  vec2 uv = FlutterFragCoord().xy / u_resolution;
  vec2 center = uv - 0.5;
  float dist = length(center);

  // Animated color based on time and position
  vec3 color = vec3(
    0.5 + 0.5 * sin(u_time + dist * 3.0),
    0.5 + 0.5 * sin(u_time + dist * 3.0 + 2.0),
    0.5 + 0.5 * sin(u_time + dist * 3.0 + 4.0)
  );

  fragColor = vec4(color, 1.0);
}
```

**Add to `pubspec.yaml`:**

```yaml
flutter:
  shaders:
    - shaders/tint.frag
```

**Dart implementation:**

```dart
class _MyWidgetState extends State<MyWidget> with SingleTickerProviderStateMixin {
  ui.FragmentProgram? _shaderProgram;
  late Ticker _ticker;
  double _time = 0.0;

  @override
  void initState() {
    super.initState();
    ui.FragmentProgram.fromAsset('shaders/tint.frag').then((program) {
      setState(() => _shaderProgram = program);
    });
    _ticker = createTicker((elapsed) {
      setState(() => _time = elapsed.inMilliseconds / 1000.0);
    })..start();
  }

  List<Paint> fragmentShaderPainter(Stroke stroke, Size canvasSize) {
    if (_shaderProgram == null) return [paintWithDefault(stroke)];

    final shader = _shaderProgram!.fragmentShader();
    shader.setFloat(0, _time);                // u_time
    shader.setFloat(1, canvasSize.width);     // u_resolution.x
    shader.setFloat(2, canvasSize.height);    // u_resolution.y

    return [
      Paint()
        ..shader = shader
        ..strokeWidth = stroke.width
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    ];
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final canvasSize = Size(constraints.maxWidth, constraints.maxHeight);

        return Draw(
          strokes: _strokes,
          strokeWidth: 8.0,
          onStrokeDrawn: (stroke) => setState(() => _strokes.add(stroke)),
          strokePainter: (stroke) => fragmentShaderPainter(stroke, canvasSize),
        );
      },
    );
  }
}
```

**Key points:**
- Load shader with `FragmentProgram.fromAsset()`
- Create new shader instance with `.fragmentShader()` for each stroke
- Set uniforms with `setFloat(index, value)`
- Use `LayoutBuilder` to get canvas size for u_resolution uniform

#### 3. Gradients for Colorful Strokes

Apply gradient effects using Flutter's built-in gradient shaders.

**Linear gradient:**

```dart
List<Paint> linearGradientPainter(Stroke stroke, Size canvasSize) {
  final gradient = ui.Gradient.linear(
    Offset.zero,
    Offset(canvasSize.width, canvasSize.height),
    [Colors.blue, Colors.purple, Colors.pink],
    [0.0, 0.5, 1.0],  // Optional color stops
  );

  return [
    Paint()
      ..shader = gradient
      ..strokeWidth = stroke.width
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke,
  ];
}
```

**Radial gradient:**

```dart
List<Paint> radialGradientPainter(Stroke stroke, Size canvasSize) {
  final center = Offset(canvasSize.width / 2, canvasSize.height / 2);
  final radius = math.max(canvasSize.width, canvasSize.height) / 2;

  final gradient = ui.Gradient.radial(
    center,
    radius,
    [Colors.yellow, Colors.orange, Colors.red],
  );

  return [
    Paint()
      ..shader = gradient
      ..strokeWidth = stroke.width
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke,
  ];
}
```

**Sweep gradient:**

```dart
List<Paint> sweepGradientPainter(Stroke stroke, Size canvasSize) {
  final center = Offset(canvasSize.width / 2, canvasSize.height / 2);

  final gradient = ui.Gradient.sweep(
    center,
    [
      Colors.red,
      Colors.yellow,
      Colors.green,
      Colors.cyan,
      Colors.blue,
      Colors.magenta,
      Colors.red,  // Back to red for smooth loop
    ],
  );

  return [
    Paint()
      ..shader = gradient
      ..strokeWidth = stroke.width
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke,
  ];
}
```

**Usage with LayoutBuilder:**

```dart
import 'dart:ui' as ui;
import 'dart:math' as math;

LayoutBuilder(
  builder: (context, constraints) {
    final canvasSize = Size(constraints.maxWidth, constraints.maxHeight);

    return Draw(
      strokes: _strokes,
      strokeWidth: 8.0,
      onStrokeDrawn: (stroke) => setState(() => _strokes.add(stroke)),
      strokePainter: (stroke) => linearGradientPainter(stroke, canvasSize),
    );
  },
)
```

**Gradient types:**
- **Linear** - `ui.Gradient.linear(start, end, colors, [stops])` - Goes from start point to end point
- **Radial** - `ui.Gradient.radial(center, radius, colors, [stops])` - Radiates from center point outward
- **Sweep** - `ui.Gradient.sweep(center, colors, [stops])` - Rotates around center point

**Combining with multi-layer:**

```dart
List<Paint> gradientWithBorder(Stroke stroke, Size canvasSize) {
  final gradient = ui.Gradient.linear(
    Offset.zero,
    Offset(canvasSize.width, canvasSize.height),
    [Colors.blue, Colors.purple],
  );

  return [
    // Black border (bottom)
    paintWithOverride(stroke,
      strokeWidth: stroke.width + 2,
      strokeColor: Colors.black,
    ),
    // Gradient fill (top)
    Paint()
      ..shader = gradient
      ..strokeWidth = stroke.width
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke,
  ];
}
```

### Common Mistakes

❌ **Forgetting to get canvas size when needed (gradients, shaders)**
```dart
// Wrong: No canvas size available
Draw(
  strokePainter: (stroke) {
    final gradient = ui.Gradient.linear(/* Need canvas size! */);
  },
)
```

✅ **Use LayoutBuilder when canvas size is required**
```dart
// Correct
LayoutBuilder(
  builder: (context, constraints) {
    final canvasSize = Size(constraints.maxWidth, constraints.maxHeight);
    return Draw(
      strokePainter: (stroke) => gradientPainter(stroke, canvasSize),
    );
  },
)
```

❌ **Manually creating eraser Paint**
```dart
// Wrong: Manually setting BlendMode.clear is fragile
Paint()
  ..blendMode = BlendMode.clear
  ..strokeWidth = stroke.width
```

✅ **Use `eraseWithDefault` for eraser strokes**
```dart
// Correct: Use utility function
eraseWithDefault(stroke)
```

❌ **Reusing shader instances across strokes**
```dart
// Wrong: Shader created once, reused
final shader = _program.fragmentShader();
strokePainter: (stroke) {
  return [Paint()..shader = shader];  // Same instance for all strokes!
}
```

✅ **Create new shader instance per stroke**
```dart
// Correct: Fresh shader for each stroke
strokePainter: (stroke) {
  final shader = _program!.fragmentShader();
  shader.setFloat(0, _time);
  return [Paint()..shader = shader];
}
```

❌ **Wrong paint order in multi-layer**
```dart
// Wrong: Border on top (won't create border effect)
return [
  paintWithDefault(stroke),              // Main stroke first
  paintWithOverride(stroke,               // Border on top
    strokeWidth: stroke.width + 4,
    strokeColor: Colors.black,
  ),
];
```

✅ **Correct paint order (bottom to top)**
```dart
// Correct: Border first, then main stroke
return [
  paintWithOverride(stroke,               // Border on bottom
    strokeWidth: stroke.width + 4,
    strokeColor: Colors.black,
  ),
  paintWithDefault(stroke),              // Main stroke on top
];
```

**Performance Considerations:**
- Fragment shaders: GPU-accelerated but more expensive than simple paints
- Multiple blur layers: Can be costly on low-end devices
- Gradient complexity: More color stops = slightly more computation

**Technique Selection:**

| Effect | Technique | Best For |
|--------|-----------|----------|
| Solid borders | Multi-layer | Simple, fast, works everywhere |
| Glows/shadows | Multi-layer + blur | Dramatic effects, moderate performance |
| Color gradients | Gradients | Beautiful colors, good performance |
| Animated effects | Fragment shader | Complex dynamic effects, GPU power |

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
        pathBuilder: PathBuilderMode.catmullRom.converter,
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

## Path Builder Options

Available `PathBuilderMode` options:

```dart
PathBuilderMode.none.converter              // No smoothing
PathBuilderMode.catmullRom.converter        // Catmull-Rom spline (recommended)
PathBuilderMode.pressureSensitive.converter // Pressure-sensitive variable width
```

### Pressure-Sensitive Drawing

For variable-width strokes based on stylus pressure, use `PathBuilderMode.pressureSensitive.converter` (or `generatePressureSensitivePath` directly for custom parameters):

```dart
import 'package:draw_your_image/draw_your_image.dart';

Draw(
  strokes: _strokes,
  strokeWidth: 8.0,
  pathBuilder: PathBuilderMode.pressureSensitive.converter,
  onStrokeDrawn: (stroke) {
    setState(() => _strokes.add(stroke));
  },
)
```

**How it works:**

- Creates a filled path where width varies according to `normalizedPressure` at each point
- Uses Catmull-Rom spline interpolation for smooth curves
- Automatically interpolates pressure, tilt, and orientation between points
- Width calculation: `width = baseWidth * point.normalizedPressure`

**Advanced customization:**

You can also pass custom parameters:

```dart
pathBuilder: (stroke) => generatePressureSensitivePath(
  stroke,
  tension: 0.8,   // Controls curve tightness (default: 0.8)
  segments: 20,   // Interpolation segments between points (default: 20)
)
```

**Combining with tilt for calligraphy effects:**

For advanced effects using tilt and orientation data, create custom path converters:

```dart
Path calligraphyPath(Stroke stroke) {
  final points = stroke.points;
  // Build path using point.tilt and point.orientation
  // to create brush-like effects
  for (final point in points) {
    final tiltFactor = 1.0 + (point.tilt / (math.pi / 2)) * 1.5;
    final width = baseWidth * tiltFactor * point.normalizedPressure;
    // Apply orientation to rotate brush angle...
  }
}

Draw(
  pathBuilder: calligraphyPath,
  // ...
)
```

See [example/lib/pages/tilt_demo_page.dart](./example/lib/pages/tilt_demo_page.dart) for a complete tilt-based calligraphy implementation.

## Tips for AI Code Generation

### User Request Patterns

| User Says | Implementation |
|-----------|----------------|
| "Only stylus" | Check `deviceKind == PointerDeviceKind.stylus` |
| "Palm rejection" | Return a stroke which is `deviceKind == PointerDeviceKind.stylus` is `currentStroke` is `deviceKind != PointerDeviceKind.stylus`|
| "Finger erases (pixel)" | Set a tag to each `Stroke` (e.g. `data: {#erasing: true}`) + `strokePainter` with `eraseWithDefault` |
| "Finger erases (stroke)" | Set `intersectionDetector` + `onStrokesSelected` (+ `strokePainter` returns `[]` if erasing stroke should be invisible) |
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
| `pathBuilder` | `Path Function(Stroke)` | Function to build `Path` from a `Stroke`. Use for smoothing or pressure-sensitive effects |
| `strokePainter` | `StrokePainter` | Custom painter function. Returns `List<Paint>` for each stroke |
| `intersectionDetector` | `IntersectionDetector` | Intersection detection function. Enables `onStrokesSelected` |
| `shouldAbsorb` | `bool Function(PointerDownEvent)` | Control whether to absorb pointer events from parent widgets |
| `onStrokeDrawn` | `void Function(Stroke)` | Called when stroke is complete |
| `onStrokeStarted` | `Stroke? Function(Stroke, Stroke?)` | Called when stroke starts. Control whether to continue, modify, or prevent with return value |
| `onStrokeUpdated` | `Stroke? Function(Stroke)` | Called when a point is added to current stroke. Enables real-time stroke manipulation |
| `onStrokesSelected` | `void Function(List<Stroke>)` | Called with strokes that intersect the drawn stroke. Requires `intersectionDetector` |

### Stroke Methods

```dart
// Create a new stroke with modified properties
stroke.copyWith({
  List<StrokePoint>? points,
  Color? color,
  double? width,
  Map<Object, dynamic>? data,
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
        onStrokesSelected: (selectedStrokes) {
          setState(() {
            // Save current state before modifying
            _undoStack.add(List.from(_strokes));

            // Remove selected strokes
            _strokes = _strokes
                .where((s) => !selectedStrokes.contains(s))
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

## Erasing and Stroke Selection

This section explains how erasing and stroke selection work in this package. There is no dedicated "eraser mode"—erasing is composed from the same building blocks used for drawing and stroke selection.

### Design Philosophy

The eraser functionality is intentionally **not** a special-cased feature. Instead, it is built from general-purpose mechanisms:

1. **Stroke selection logic is swappable via `intersectionDetector`**: The `intersectionDetector` + `onStrokesSelected` pattern is not limited to "erasing." The same mechanism can power **lasso selection**, **stroke editing** (e.g., changing the color of selected strokes), or any other interaction that requires identifying strokes by geometric relationship. By making the detection logic a pluggable function, you can swap in different algorithms (segment distance, bounding box, lasso polygon, etc.) without changing any other code.

2. **"Eraser strokes" are just a visual style**: An eraser stroke that clears pixels (`eraseWithDefault`) is fundamentally the same as a "bold stroke" or a "gradient stroke"—it's a `Paint` configuration returned by `strokePainter`. This means the eraser is not a separate mode that needs special handling; it sits alongside all other visual styles in a single `strokePainter` callback.

3. **Consistency prevents feature conflicts**: By unifying erasing with stroke selection and visual styling, the package avoids situations where "eraser mode" and "stroke editing" need separate, potentially conflicting code paths. Adding a new feature (e.g., lasso selection + delete) requires no changes to the erasing code—they share the same `onStrokesSelected` callback.

### Pixel Erasing

Pixel erasing clears the pixels where the eraser stroke passes over existing strokes. Use `Stroke.data` to tag eraser strokes and `strokePainter` to apply `eraseWithDefault`.

```dart
Draw(
  strokes: _strokes,
  onStrokeDrawn: (stroke) {
    setState(() => _strokes = [..._strokes, stroke]);
  },
  onStrokeStarted: (newStroke, currentStroke) {
    return currentStroke ??
        newStroke.copyWith(data: {#erasing: true});
  },
  strokePainter: (stroke) =>
      stroke.data?[#erasing] == true
          ? [eraseWithDefault(stroke)]
          : [paintWithDefault(stroke)],
)
```

### Stroke-Level Erasing (Selection + Removal)

Stroke-level erasing removes entire strokes that intersect with the drawn stroke. This uses `intersectionDetector` and `onStrokesSelected`.

```dart
Draw(
  strokes: _strokes,
  onStrokeDrawn: (stroke) {
    setState(() => _strokes = [..._strokes, stroke]);
  },
  onStrokeStarted: (newStroke, currentStroke) {
    return currentStroke ??
        newStroke.copyWith(data: {#erasing: true});
  },
  onStrokesSelected: (selectedStrokes) {
    setState(() {
      _strokes = _strokes
          .where((s) => !selectedStrokes.contains(s))
          .toList();
    });
  },
  intersectionDetector: detectIntersectionBySegmentDistance,
  strokePainter: (stroke) =>
      stroke.data?[#erasing] == true
          ? []  // Don't render the eraser stroke itself
          : [paintWithDefault(stroke)],
)
```

### Combined Example: Pixel + Stroke Erasing with Mode Switch

For an app that supports both pixel and stroke erasing modes, use an enum in `Stroke.data` to distinguish:

```dart
enum ErasingBehavior { none, pixel, stroke }

// In onStrokeStarted:
onStrokeStarted: (newStroke, currentStroke) {
  return currentStroke ??
      newStroke.copyWith(data: {ErasingBehavior: _currentBehavior});
},

// In strokePainter:
strokePainter: (stroke) =>
    switch (stroke.data?[ErasingBehavior]) {
      ErasingBehavior.stroke => [],
      ErasingBehavior.pixel => [eraseWithDefault(stroke)],
      _ => [paintWithDefault(stroke)],
    },

// Conditionally enable intersection detection:
intersectionDetector: _currentBehavior == ErasingBehavior.stroke
    ? detectIntersectionBySegmentDistance
    : null,
```

See [example/lib/main.dart](./example/lib/main.dart) for the full working implementation of this pattern.

## Migration from ErasingBehavior / ErasingMode

If you are migrating from a version that used `ErasingBehavior` enum, `erasingBehavior` property on `Draw`/`Stroke`, or `onStrokesRemoved` callback, follow this guide.

### Summary of Removed APIs

| Removed | Replacement |
|---------|-------------|
| `ErasingBehavior` enum | User-defined enum or symbol in `Stroke.data` |
| `Draw(erasingBehavior: ...)` | `onStrokeStarted` to set `data` + `strokePainter` |
| `Stroke.erasingBehavior` | `Stroke.data` (e.g., `data: {#erasing: true}`) |
| `Stroke.copyWith(erasingBehavior: ...)` | `Stroke.copyWith(data: ...)` |
| `onStrokesRemoved` | `onStrokesSelected` |

### Migration Steps

**1. Replace `Draw(erasingBehavior: ErasingBehavior.pixel)`**

Before:
```dart
Draw(
  erasingBehavior: ErasingBehavior.pixel,
  onStrokeDrawn: (stroke) => ...,
)
```

After:
```dart
Draw(
  onStrokeStarted: (newStroke, currentStroke) {
    return currentStroke ??
        newStroke.copyWith(data: {#erasing: true});
  },
  strokePainter: (stroke) =>
      stroke.data?[#erasing] == true
          ? [eraseWithDefault(stroke)]
          : [paintWithDefault(stroke)],
  onStrokeDrawn: (stroke) => ...,
)
```

**2. Replace `Draw(erasingBehavior: ErasingBehavior.stroke)`**

Before:
```dart
Draw(
  erasingBehavior: ErasingBehavior.stroke,
  onStrokesRemoved: (removed) => ...,
)
```

After:
```dart
Draw(
  intersectionDetector: detectIntersectionBySegmentDistance,
  onStrokesSelected: (selected) => ...,
  onStrokeStarted: (newStroke, currentStroke) {
    return currentStroke ??
        newStroke.copyWith(data: {#erasing: true});
  },
  strokePainter: (stroke) =>
      stroke.data?[#erasing] == true
          ? []
          : [paintWithDefault(stroke)],
)
```

**3. Replace `Stroke.copyWith(erasingBehavior: ...)`**

Before:
```dart
newStroke.copyWith(erasingBehavior: ErasingBehavior.pixel)
```

After:
```dart
newStroke.copyWith(data: {#erasing: true})
```

**4. Replace `stroke.erasingBehavior` checks**

Before:
```dart
if (stroke.erasingBehavior == ErasingBehavior.pixel) { ... }
```

After:
```dart
if (stroke.data?[#erasing] == true) { ... }
```

**5. Replace `onStrokesRemoved` with `onStrokesSelected`**

The callback name changed to reflect that it is a general-purpose stroke selection mechanism, not limited to erasing. The signature and behavior are the same.

## Related Resources

- [Example App](./example/lib/main.dart) - Complete implementation with multiple modes
- [API Documentation](https://pub.dev/documentation/draw_your_image/latest/)
- [Package on pub.dev](https://pub.dev/packages/draw_your_image)
