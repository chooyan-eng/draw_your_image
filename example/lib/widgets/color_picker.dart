import 'package:flutter/material.dart';
import '../constants/demo_colors.dart';

/// Color Picker Widget
///
/// Horizontally arranged round color buttons for selecting from predefined colors.
/// Selected color is highlighted with white border.
class ColorPicker extends StatelessWidget {
  /// Currently selected color
  final Color selectedColor;

  /// Callback when color is changed
  final ValueChanged<Color> onColorChanged;

  /// List of colors to display (default is DemoColors.palette)
  final List<Color> colors;

  const ColorPicker({
    super.key,
    required this.selectedColor,
    required this.onColorChanged,
    this.colors = DemoColors.palette,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: colors.map((color) {
        final isSelected = color == selectedColor;
        return GestureDetector(
          onTap: () => onColorChanged(color),
          child: Container(
            width: 36,
            height: 36,
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(color: Colors.white, width: 3)
                  : Border.all(color: Colors.grey.shade300, width: 1),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
