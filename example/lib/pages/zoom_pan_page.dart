import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:draw_your_image/draw_your_image.dart';
import '../utils/stylus_helper.dart';
import '../constants/demo_colors.dart';

/// InteractiveViewer integration mode
enum IntegrationMode {
  disableWhileDrawing('Disable While Drawing', 'Zoom/Pan disabled while drawing'),
  deviceSpecific('Device-Specific', 'Stylus=Draw, Finger=Zoom/Pan'),
  fittedBox('Fitted Box', 'Auto-scale to window size');

  const IntegrationMode(this.label, this.description);
  final String label;
  final String description;
}

/// Zoom & Pan integration demo page
///
/// InteractiveViewer and Draw widget integration demo.
class ZoomPanPage extends StatefulWidget {
  const ZoomPanPage({super.key});

  @override
  State<ZoomPanPage> createState() => _ZoomPanPageState();
}

class _ZoomPanPageState extends State<ZoomPanPage> {
  List<Stroke> _strokes = [];
  IntegrationMode _currentMode = IntegrationMode.deviceSpecific;
  bool _isDrawing = false; // For disable while drawing mode

  /// Stroke start processing
  Stroke? _onStrokeStarted(Stroke newStroke, Stroke? currentStroke) {
    if (_currentMode == IntegrationMode.disableWhileDrawing) {
      setState(() => _isDrawing = true);
    }

    if (currentStroke != null) return currentStroke;

    // For device-specific mode, only stylus can draw
    if (_currentMode == IntegrationMode.deviceSpecific) {
      return newStroke.deviceKind.isStylus ? newStroke : null;
    }

    return newStroke;
  }

  /// Stroke completion processing
  void _onStrokeDrawn(Stroke stroke) {
    setState(() {
      _strokes = [..._strokes, stroke];
      if (_currentMode == IntegrationMode.disableWhileDrawing) {
        _isDrawing = false;
      }
    });
  }

  /// Get hint text based on current mode
  String _getHintText() {
    switch (_currentMode) {
      case IntegrationMode.deviceSpecific:
        return 'Draw with stylus, zoom/pan with finger';
      case IntegrationMode.disableWhileDrawing:
        return 'Pinch zoom and pan are disabled while drawing';
      case IntegrationMode.fittedBox:
        return 'Canvas auto-scales to fit window size';
    }
  }

  /// Build content based on current mode
  Widget _buildContent() {
    if (_currentMode == IntegrationMode.fittedBox) {
      return LayoutBuilder(
        builder: (context, constraints) {
          return FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(
              width: 1000,
              height: 1000,
              child: Container(
                color: DemoColors.canvasBackground,
                child: Draw(
                  strokes: _strokes,
                  strokeColor: Colors.purple,
                  strokeWidth: 4.0,
                  backgroundColor: Colors.transparent,
                  onStrokeStarted: _onStrokeStarted,
                  onStrokeDrawn: _onStrokeDrawn,
                ),
              ),
            ),
          );
        },
      );
    } else {
      return InteractiveViewer(
        // For disable while drawing mode, disable zoom/pan while drawing
        scaleEnabled: _currentMode == IntegrationMode.disableWhileDrawing
            ? !_isDrawing
            : true,
        panEnabled: _currentMode == IntegrationMode.disableWhileDrawing
            ? !_isDrawing
            : true,
        minScale: 0.5,
        maxScale: 4.0,
        child: Container(
          width: 2000,
          height: 2000,
          color: DemoColors.canvasBackground,
          child: Draw(
            strokes: _strokes,
            strokeColor: Colors.purple,
            strokeWidth: 4.0,
            backgroundColor: Colors.transparent,
            // For device-specific mode, absorb only stylus events
            shouldAbsorb: _currentMode == IntegrationMode.deviceSpecific
                ? (event) =>
                    event.kind == PointerDeviceKind.stylus ||
                    event.kind == PointerDeviceKind.invertedStylus
                : null,
            onStrokeStarted: _onStrokeStarted,
            onStrokeDrawn: _onStrokeDrawn,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Zoom & Pan Integration'),
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
            color: Colors.purple.shade50,
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
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _getHintText(),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          // Canvas
          Expanded(
            child: _buildContent(),
          ),
          // Mode selection
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: DemoColors.toolbarBackground,
              border: Border(
                top: BorderSide(color: Colors.grey, width: 0.5),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Integration Mode:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: IntegrationMode.values.map((mode) {
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
