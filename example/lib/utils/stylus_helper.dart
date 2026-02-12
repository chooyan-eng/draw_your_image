import 'package:flutter/gestures.dart';

/// Extension method to simplify stylus device detection
extension StylusHelper on PointerDeviceKind {
  /// Determines whether this device is a stylus (pen)
  ///
  /// Includes both normal stylus (PointerDeviceKind.stylus) and
  /// inverted stylus (PointerDeviceKind.invertedStylus)
  bool get isStylus =>
      this == PointerDeviceKind.stylus ||
      this == PointerDeviceKind.invertedStylus;
}
