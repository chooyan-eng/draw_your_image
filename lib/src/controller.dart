part of draw_your_image;

/// A controller for actions of drawing
class DrawController {
  late _DrawControllerDelegate _delegate;

  /// Convert current [Canvas] into png image data.
  /// This method returns immediately without waiting for convert.
  /// You can obtain converted image data via [onConvert] property of [Crop].
  void convertToPng() => _delegate.onConvertToPng();
}

class _DrawControllerDelegate {
  late VoidCallback onConvertToPng;
}
