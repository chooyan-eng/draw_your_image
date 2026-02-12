import 'package:draw_your_image/draw_your_image.dart';

/// Class for managing Undo/Redo functionality
///
/// Adopts a complete state snapshot approach based on AI_GUIDE.md.
/// Saves the current state before each action and restores states with Undo/Redo.
///
/// This implementation may be memory-inefficient for large canvases with
/// thousands of strokes, but is sufficient for demo apps.
class UndoRedoManager {
  /// Undo stack: Stores past states
  final List<List<Stroke>> _undoStack = [];

  /// Redo stack: Stores states for moving forward after Undo
  final List<List<Stroke>> _redoStack = [];

  /// Whether Undo is available
  bool get canUndo => _undoStack.isNotEmpty;

  /// Whether Redo is available
  bool get canRedo => _redoStack.isNotEmpty;

  /// Save the current state
  ///
  /// Call before executing a new action (stroke addition, deletion, etc.).
  /// The Redo stack is cleared (since a new action creates a branch).
  void saveState(List<Stroke> currentState) {
    _undoStack.add(List.from(currentState));
    _redoStack.clear();
  }

  /// Go back to the previous state
  ///
  /// [currentState]: Current state (saved to Redo stack)
  /// Returns: The previous state. Returns current state if Undo is not available.
  List<Stroke> undo(List<Stroke> currentState) {
    if (!canUndo) {
      return currentState;
    }

    // Save current state to Redo stack
    _redoStack.add(List.from(currentState));

    // Get previous state from Undo stack
    return _undoStack.removeLast();
  }

  /// Move forward to the next state
  ///
  /// [currentState]: Current state (saved to Undo stack)
  /// Returns: The next state. Returns current state if Redo is not available.
  List<Stroke> redo(List<Stroke> currentState) {
    if (!canRedo) {
      return currentState;
    }

    // Save current state to Undo stack
    _undoStack.add(List.from(currentState));

    // Get next state from Redo stack
    return _redoStack.removeLast();
  }

  /// Clear the stacks
  ///
  /// Typically called when completely clearing the canvas.
  void clear() {
    _undoStack.clear();
    _redoStack.clear();
  }
}
