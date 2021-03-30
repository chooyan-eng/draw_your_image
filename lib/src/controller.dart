part of draw_your_image;

/// A controller for actions of drawing
class DrawController {
  late _DrawControllerDelegate _delegate;

  /// Convert current [Canvas] into png image data.
  /// This method returns immediately without waiting for convert.
  /// You can obtain converted image data via [onConvert] property of [Crop].
  void convertToPng() => _delegate.onConvertToPng();

  /// Undo last stroke
  /// Return [false] if there is no stroke to undo, otherwise return [true].
  bool undo() => _delegate.onUndo();

  /// Redo last undo stroke
  /// Return [false] if there is no stroke to redo, otherwise return [true].
  bool redo() => _delegate.onRedo();
}

class _DrawControllerDelegate {
  late VoidCallback onConvertToPng;

  late bool Function() onUndo;

  late bool Function() onRedo;
}
