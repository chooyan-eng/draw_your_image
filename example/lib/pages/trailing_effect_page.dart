import 'package:flutter/material.dart';
import 'package:draw_your_image/draw_your_image.dart';
import '../constants/demo_colors.dart';

/// Effect type
enum EffectType {
  trailing('Trailing', 'Display only last 30 points (afterimage effect)'),
  dynamicColor('Dynamic Color Change', 'Color changes as drawing gets longer'),
  pointFiltering('Point Filtering', 'Keep only points 5px or more apart'),
  lengthLimit('Length Limit', 'Stroke ends at 1000 points');

  const EffectType(this.label, this.description);
  final String label;
  final String description;
}

/// Effects Demo Page
///
/// Demo of dynamic effects using onStrokeUpdated.
class TrailingEffectPage extends StatefulWidget {
  const TrailingEffectPage({super.key});

  @override
  State<TrailingEffectPage> createState() => _TrailingEffectPageState();
}

class _TrailingEffectPageState extends State<TrailingEffectPage> {
  List<Stroke> _strokes = [];
  EffectType _currentEffect = EffectType.trailing;

  /// Process when stroke is updated (apply effect)
  Stroke? _onStrokeUpdated(Stroke currentStroke) {
    switch (_currentEffect) {
      case EffectType.trailing:
        // Trailing: Display only last 30 points
        return currentStroke.copyWith(
          points: currentStroke.points.length > 30
              ? currentStroke.points.sublist(currentStroke.points.length - 30)
              : currentStroke.points,
        );

      case EffectType.dynamicColor:
        // Dynamic color change: Color changes based on length
        final pointCount = currentStroke.points.length;
        final ratio = (pointCount / 500).clamp(0.0, 1.0);
        final newColor = Color.lerp(Colors.blue, Colors.red, ratio);
        return currentStroke.copyWith(color: newColor);

      case EffectType.pointFiltering:
        // Point filtering: Keep only points at a certain distance apart
        if (currentStroke.points.length < 2) {
          return currentStroke;
        }
        final filtered = <StrokePoint>[currentStroke.points.first];
        const minDistance = 5.0;

        for (final point in currentStroke.points.skip(1)) {
          final lastPoint = filtered.last.position;
          final distance = (point.position - lastPoint).distance;

          if (distance >= minDistance) {
            filtered.add(point);
          }
        }
        return currentStroke.copyWith(points: filtered);

      case EffectType.lengthLimit:
        // Length limit: End stroke after 1000 points
        return currentStroke.points.length > 1000 ? null : currentStroke;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Effects Demo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: _strokes.isEmpty
                ? null
                : () => setState(() => _strokes = []),
            tooltip: 'Clear All',
          ),
        ],
      ),
      body: Column(
        children: [
          // Description panel
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.orange.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Effect: ${_currentEffect.label}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _currentEffect.description,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
          // Canvas
          Expanded(
            child: Draw(
              strokes: _strokes,
              strokeColor: Colors.blue,
              strokeWidth: 4.0,
              backgroundColor: DemoColors.canvasBackground,
              onStrokeDrawn: (stroke) {
                setState(() => _strokes = [..._strokes, stroke]);
              },
              onStrokeUpdated: _onStrokeUpdated,
            ),
          ),
          // Effect selection
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: DemoColors.toolbarBackground,
              border: Border(top: BorderSide(color: Colors.grey, width: 0.5)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Effect Type:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: EffectType.values.map((effect) {
                    return ChoiceChip(
                      label: Text(effect.label),
                      selected: _currentEffect == effect,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _currentEffect = effect);
                        }
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
