import 'package:draw_your_image/draw_your_image.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var _currentColor = Colors.black;
  var _currentWidth = 4.0;
  var _smoothingMode = SmoothingMode.catmullRom;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('draw_your_image example'),
      ),
      body: SizedBox(
        height: double.infinity,
        width: double.infinity,
        child: Column(
          children: [
            const SizedBox(height: 16),
            const Text('DRAW WHAT YOU WANT!'),
            const SizedBox(height: 8),
            // Smoothing mode selector
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Smoothing: '),
                  SegmentedButton<SmoothingMode>(
                    segments: const [
                      ButtonSegment(
                        value: SmoothingMode.none,
                        label: Text('None'),
                      ),
                      ButtonSegment(
                        value: SmoothingMode.catmullRom,
                        label: Text('Smooth'),
                      ),
                    ],
                    selected: {_smoothingMode},
                    onSelectionChanged: (Set<SmoothingMode> newSelection) {
                      setState(() {
                        _smoothingMode = newSelection.first;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: InteractiveViewer(
                maxScale: 10.0,
                child: Draw(
                  strokeColor: _currentColor,
                  strokeWidth: _currentWidth,
                  pathConverter: _smoothingMode.toConverter(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Colors:'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              children: [
                Colors.black,
                Colors.blue,
                Colors.red,
                Colors.green,
                Colors.yellow
              ].map(
                (color) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _currentColor = color;
                      });
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 40,
                        height: 40,
                        color: color,
                        child: Center(
                          child: _currentColor == color
                              ? Icon(
                                  Icons.brush,
                                  color: Colors.white,
                                )
                              : SizedBox.shrink(),
                        ),
                      ),
                    ),
                  );
                },
              ).toList(),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Text('Width: '),
                  Expanded(
                    child: Slider(
                      max: 40,
                      min: 1,
                      value: _currentWidth,
                      onChanged: (value) {
                        setState(() {
                          _currentWidth = value;
                        });
                      },
                    ),
                  ),
                  Text(_currentWidth.toStringAsFixed(1)),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
