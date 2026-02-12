import 'package:flutter/material.dart';

/// Demo Page Common Toolbar
///
/// Provides common operations such as Undo/Redo/Clear buttons.
class DemoToolbar extends StatelessWidget {
  /// Clear button callback
  final VoidCallback? onClear;

  /// Undo button callback
  final VoidCallback? onUndo;

  /// Redo button callback
  final VoidCallback? onRedo;

  /// Whether Undo is available
  final bool canUndo;

  /// Whether Redo is available
  final bool canRedo;

  /// Additional custom widget (displayed on the right side)
  final Widget? extraWidget;

  const DemoToolbar({
    super.key,
    this.onClear,
    this.onUndo,
    this.onRedo,
    this.canUndo = false,
    this.canRedo = false,
    this.extraWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (onUndo != null)
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: canUndo ? onUndo : null,
            tooltip: 'Undo',
          ),
        if (onRedo != null)
          IconButton(
            icon: const Icon(Icons.redo),
            onPressed: canRedo ? onRedo : null,
            tooltip: 'Redo',
          ),
        if (onClear != null)
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: onClear,
            tooltip: 'Clear All',
          ),
        if (extraWidget != null) ...[const Spacer(), extraWidget!],
      ],
    );
  }
}
