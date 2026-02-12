import 'package:flutter/material.dart';

/// Stroke Width Slider Widget
///
/// A slider for adjusting stroke width and displaying the current value.
class StrokeWidthSlider extends StatelessWidget {
  /// Current stroke width
  final double width;

  /// Callback when width is changed
  final ValueChanged<double> onWidthChanged;

  /// Minimum value (default: 1.0)
  final double min;

  /// Maximum value (default: 20.0)
  final double max;

  const StrokeWidthSlider({
    super.key,
    required this.width,
    required this.onWidthChanged,
    this.min = 1.0,
    this.max = 20.0,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.brush, size: 16),
        const SizedBox(width: 8),
        SizedBox(
          width: 150,
          child: Slider(
            value: width,
            min: min,
            max: max,
            onChanged: onWidthChanged,
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 35,
          child: Text(
            width.toStringAsFixed(1),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}
