import 'package:flutter/material.dart';

/// Color definitions used in demo app
class DemoColors {
  /// Color palette used in color picker
  static const List<Color> palette = [
    Colors.black,
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.yellow,
    Colors.orange,
    Colors.purple,
    Colors.pink,
  ];

  /// Canvas background color
  static const Color canvasBackground = Colors.white;

  /// Toolbar background color
  static const Color toolbarBackground = Color(0xFFF5F5F5);

  /// Highlight color for selected strokes
  static const Color selectionHighlight = Color(0x8064B5F6); // Blue translucent

  /// Line color during lasso selection
  static const Color lassoColor = Color(0xFF2196F3); // Blue
}
