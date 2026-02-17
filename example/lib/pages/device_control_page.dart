import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:draw_your_image/draw_your_image.dart';
import '../utils/stylus_helper.dart';
import '../constants/demo_colors.dart';

/// Device control mode
enum DeviceControlMode {
  allDevices('All Devices Allowed', 'Drawing possible with all devices'),
  stylusOnly('Stylus Only', 'Only stylus responds'),
  palmRejection('Palm Rejection', 'Ignore finger while drawing with pen'),
  stylusDrawFingerErase(
    'Pen Draw, Finger Erase',
    'Different actions by device',
  ),
  deviceSpecificColor(
    'Device-Specific Color',
    'Pen=Black, Finger=Red, Mouse=Blue',
  ),
  deviceSpecificWidth('Device-Specific Width', 'Pen=Thin, Finger=Thick');

  const DeviceControlMode(this.label, this.description);
  final String label;
  final String description;
}

/// Device Control Demo Page
///
/// Demo of device-specific drawing control using onStrokeStarted.
class DeviceControlPage extends StatefulWidget {
  const DeviceControlPage({super.key});

  @override
  State<DeviceControlPage> createState() => _DeviceControlPageState();
}

class _DeviceControlPageState extends State<DeviceControlPage> {
  List<Stroke> _strokes = [];
  DeviceControlMode _currentMode = DeviceControlMode.allDevices;
  PointerDeviceKind? _lastDeviceKind;

  /// Stroke start processing (control based on mode)
  Stroke? _onStrokeStarted(Stroke newStroke, Stroke? currentStroke) {
    // Record last device kind (for display)
    setState(() => _lastDeviceKind = newStroke.deviceKind);

    switch (_currentMode) {
      case DeviceControlMode.allDevices:
        // Allow all devices
        if (currentStroke != null) return currentStroke;
        return newStroke;

      case DeviceControlMode.stylusOnly:
        // Allow stylus only
        if (currentStroke != null) return currentStroke;
        return newStroke.deviceKind.isStylus ? newStroke : null;

      case DeviceControlMode.palmRejection:
        // Palm rejection
        return switch (currentStroke?.deviceKind.isStylus) {
          true => currentStroke, // Continue while stylus drawing
          false =>
            newStroke.deviceKind.isStylus
                ? newStroke
                : currentStroke, // If drawing with non-stylus, switch if stylus
          null => newStroke, // Start new if nothing is being drawn
        };

      case DeviceControlMode.stylusDrawFingerErase:
        // Pen draw, finger erase
        if (currentStroke != null) return currentStroke;
        if (newStroke.deviceKind.isStylus) {
          // Stylus: Normal drawing
          return newStroke;
        } else {
          // Finger/Mouse: Pixel erasing
          return newStroke.copyWith(
            data: {#erasing: true},
            width: 20.0,
          );
        }

      case DeviceControlMode.deviceSpecificColor:
        // Device-specific color
        if (currentStroke != null) return currentStroke;
        final color = switch (newStroke.deviceKind) {
          PointerDeviceKind.stylus ||
          PointerDeviceKind.invertedStylus => Colors.black,
          PointerDeviceKind.touch => Colors.red,
          PointerDeviceKind.mouse => Colors.blue,
          _ => Colors.grey,
        };
        return newStroke.copyWith(color: color, width: 4.0);

      case DeviceControlMode.deviceSpecificWidth:
        // Device-specific width
        if (currentStroke != null) return currentStroke;
        final width = newStroke.deviceKind.isStylus ? 2.0 : 8.0;
        return newStroke.copyWith(color: Colors.black, width: width);
    }
  }

  /// Get display name for device kind
  String _getDeviceKindLabel(PointerDeviceKind? kind) {
    if (kind == null) return 'Not detected';
    return switch (kind) {
      PointerDeviceKind.stylus => 'Stylus',
      PointerDeviceKind.invertedStylus => 'Inverted Stylus',
      PointerDeviceKind.touch => 'Finger (Touch)',
      PointerDeviceKind.mouse => 'Mouse',
      PointerDeviceKind.trackpad => 'Trackpad',
      _ => 'Unknown',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Control'),
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
          // Information panel
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Mode: ${_currentMode.label}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _currentMode.description,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 8),
                Text(
                  'Last Input Device: ${_getDeviceKindLabel(_lastDeviceKind)}',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          // Canvas
          Expanded(
            child: Draw(
              strokes: _strokes,
              strokeColor: Colors.black,
              strokeWidth: 4.0,
              backgroundColor: DemoColors.canvasBackground,
              onStrokeDrawn: (stroke) {
                setState(() => _strokes = [..._strokes, stroke]);
              },
              onStrokeStarted: _onStrokeStarted,
              strokePainter: (stroke) =>
                  stroke.data?[#erasing] == true
                      ? [eraseWithDefault(stroke)]
                      : [paintWithDefault(stroke)],
            ),
          ),
          // Mode selection
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
                  'Device Control Mode:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: DeviceControlMode.values.map((mode) {
                    return ChoiceChip(
                      label: Text(mode.label),
                      selected: _currentMode == mode,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _currentMode = mode);
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
