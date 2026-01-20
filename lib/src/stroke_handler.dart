import 'dart:ui';

import 'package:draw_your_image/draw_your_image.dart';

/// A stroke handler that gives priority to stylus input over other input types.
Stroke? stylusPriorHandler(Stroke newStroke, Stroke? currentStroke) {
  return switch (currentStroke?.deviceKind.isStylus) {
    true => currentStroke,
    false => newStroke.deviceKind.isStylus ? newStroke : currentStroke,
    null => newStroke,
  };
}

/// A stroke handler that only accepts stylus input.
/// If the input is from an inverted stylus, it automatically sets the stroke to erasing mode.
Stroke? stylusOnlyHandler(Stroke newStroke, Stroke? currentStroke) {
  // accept only stylus input
  if (!newStroke.deviceKind.isStylus) {
    return currentStroke;
  }

  // if invertedStylus is used, set isErasing to true
  return currentStroke ??
      newStroke.copyWith(
        isErasing: newStroke.deviceKind == PointerDeviceKind.invertedStylus,
      );
}

/// Extension to check if PointerDeviceKind is stylus
extension on PointerDeviceKind {
  bool get isStylus =>
      this == PointerDeviceKind.stylus ||
      this == PointerDeviceKind.invertedStylus;
}
