part of draw_your_image;

/// A controller for actions of drawing
class DrawController {
  late _DrawControllerDelegate _delegate;

  /// Convert current [Canvas] into image data with png format.
  /// This method returns immediately without waiting for convert.
  /// You can obtain converted image data via [onConvert] property of [Crop].
  void convertToImage() => _delegate.onConvertToImage();

  /// Undo last stroke
  /// Return [false] if there is no stroke to undo, otherwise return [true].
  bool undo() => _delegate.onUndo();

  /// Redo last undo stroke
  /// Return [false] if there is no stroke to redo, otherwise return [true].
  bool redo() => _delegate.onRedo();

  /// Clear all the strokes
  void clear() => _delegate.onClear();
}

class _DrawControllerDelegate {
  late VoidCallback onConvertToImage;

  late bool Function() onUndo;

  late bool Function() onRedo;

  late VoidCallback onClear;
}
