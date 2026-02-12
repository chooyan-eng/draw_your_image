import 'package:flutter/material.dart';

/// Tool Button Widget
///
/// A toggleable icon button.
/// Background color changes when selected for better visibility.
class ToolButton extends StatelessWidget {
  /// Icon to display
  final IconData icon;

  /// Whether selected or not
  final bool isSelected;

  /// Callback when tapped
  final VoidCallback onTap;

  /// Tooltip (description shown on hover)
  final String? tooltip;

  const ToolButton({
    super.key,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final button = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor.withValues(alpha: 0.2)
              : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: isSelected ? Theme.of(context).primaryColor : null,
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: button);
    }

    return button;
  }
}
