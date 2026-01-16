# draw_your_image

draw_your_image is a Flutter package for drawing pictures/letters with fingers with `Draw` widget.

`Draw` is just a tiny widget which just feedbacks generated strokes by user's gestures and draws the given `strokes` on their screen.

Although this means all the state management for stroke data, such as undo/redo, clear, or preserving stroke values, is your business, __this approach enables you to seemlessly collaborate with the functionalities of your apps__, such as persistence of the strokes data, integrated undo/redo with other editings, etc.

Also, all the configuration about colors and stroke width, smoothing logics, strokes data can be customized.

# Demos

![Demo](https://github.com/chooyan-eng/draw_your_image/raw/main/assets/draw_sample.gif)

# Features

- Fully declarative
- Smoothing strokes
- All the data can be customized on your side
- Configuration of any __stroke colors__ and __background color__
- Configuration of __stroke width__
- Erasor mode

# Note

Though this package is available with a couple of features, it's still under development. Any feedbacks or bug reports, and off course Pull Requests, are welcome. Feel free to visit the GitHub repository below.

[https://github.com/chooyan-eng/draw_your_image](https://github.com/chooyan-eng/draw_your_image)

# Usage

## Draw

The very first step for draw_your_image is to place `Draw` widget at anywhere you want in the widget tree.

The `Draw` requires a parent widget, typically `StatefulWidget`, that manages the stroke state as `Draw` only handles the drawing interaction and draws the given strokes.

```dart
class MyDrawingPage extends StatefulWidget {
  @override
  _MyDrawingPageState createState() => _MyDrawingPageState();
}

class _MyDrawingPageState extends State<MyDrawingPage> {
  List<Stroke> _strokes = []; 

  @override
  Widget build(BuildContext context) {
    return Draw(
      // give back stroke data to Draw
      strokes: _strokes, 
      onStrokeDrawn: (stroke) {
        // Add a drawn stroke to _strokes
        setState(() {
          _strokes = [..._strokes, stroke];
        });
      },
      backgroundColor: Colors.blue.shade50,
      strokeColor: Colors.red,
      strokeWidth: 8,
      isErasing: false,
    );
  }
}
```

**Required properties:**
- `strokes`: List of `Stroke` objects to display on the canvas
- `onStrokeDrawn`: Callback invoked when a stroke is completed

**Optional properties: **
- `strokeColor`, `strokeWidth`: `Draw` widget displays a canvas where users can draw with the given configurations.
- `isErasing`: A flag for erasing drawn strokes. If `true`, new strokes will erase previously drawn strokes. Note that erasing strokes are also represented by `Stroke` and passed via `onStrokeDrawn` callback as well.

If you wish to change colors or width, simply call `setState()` in your `StatefulWidget` and change the properties passed to `Draw`. Other state management systems are also available.

## Path Smoothing

By default, strokes are smoothed using Catmull-Rom spline interpolation. You can customize this behavior using the `smoothingFunc` parameter.

### Using built-in smoothing modes:

You can use `SmoothingMode` enum for pre-defined smoothing logics. As `SmoothingMode` has a field of function named `converter`, you can simply pass the function to `smoothingFunc`.

```dart
// Smooth curves (default)
Draw(
  strokes: _strokes,
  onStrokeDrawn: (stroke) => setState(() => _strokes.add(stroke)),
  smoothingFunc: SmoothingMode.catmullRom.converter,
)

// No smoothing (straight lines)
Draw(
  strokes: _strokes,
  onStrokeDrawn: (stroke) => setState(() => _strokes.add(stroke)),
  smoothingFunc: SmoothingMode.none.converter,
)
```

### Using custom smoothing function:

Because `smoothingFunc` can receive any functions as long as they apply the type `Path Function(Stroke)`, you can implement your own logic and pass the function here for customizing smoothing logics.

```dart
Draw(
  strokes: _strokes,
  onStrokeDrawn: (stroke) => setState(() => _strokes.add(stroke)),
  smoothingFunc: (stroke) {
    // Custom path generation logic
    final path = Path();
    final points = stroke.points;
    
    if (points.isNotEmpty) {
      path.moveTo(points[0].dx, points[0].dy);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
    }
    
    return path;
  },
)
```

## Stroke Data Structure

Strokes are stored as a list of point and its metadata containing:
- `points`: List of `Offset` representing the stroke path
- `color`: Stroke color
- `width`: Stroke width
- `isErasing`: Whether the stroke is in eraser mode

This structure allows you to:
- Access and process stroke data independently from UI
- Apply post-processing like resampling
- Implement custom rendering logic

### Resampling Utility

The `resamplePoints` function allows you to resample stroke points for uniform density:

```dart
import 'package:draw_your_image/draw_your_image.dart';

// Resample points with 5.0 pixel spacing
final originalPoints = [
  Offset(0, 0),
  Offset(10, 10),
  Offset(20, 15),
  // ... more points
];

final resampledPoints = resamplePoints(originalPoints, 5.0);

// Use resampled points to create a new stroke
final newStroke = stroke.copyWith(points: resampledPoints);
```

This is useful for:
- Reducing the number of points while maintaining shape
- Normalizing point density across different drawing speeds
- Pre-processing data for machine learning or gesture recognition
