import 'package:draw_your_image/draw_your_image.dart';
import 'package:flutter/material.dart';

/// A function that takes a [Stroke] and returns a
/// list of [Paint] objects to be used for rendering the stroke.
typedef StrokePainter = List<Paint> Function(Stroke stroke);

/// The default implementation of [StrokePainter].
List<Paint> defaultStrokePainter(Stroke stroke) => [paintWithDefault(stroke)];

/// A utility function to create a [Paint] object with default stroke properties.
Paint paintWithDefault(Stroke stroke) {
  return _paint(
    strokeColor: stroke.color,
    strokeWidth: stroke.width,
    strokeCap: StrokeCap.round,
    style: PaintingStyle.stroke,
    blendMode: BlendMode.srcOver,
  );
}

/// A utility function to create a [Paint] object with overridden stroke properties.
Paint paintWithOverride(
  Stroke stroke, {
  Color? strokeColor,
  double? strokeWidth,
  StrokeCap? strokeCap,
  PaintingStyle? style,
}) {
  return _paint(
    strokeColor: strokeColor ?? stroke.color,
    strokeWidth: strokeWidth ?? stroke.width,
    strokeCap: strokeCap ?? StrokeCap.round,
    style: style ?? PaintingStyle.stroke,
    blendMode: BlendMode.srcOver,
  );
}

/// A utility function to create a [Paint] object for an erasing stroke with default stroke properties.
Paint eraseWithDefault(Stroke stroke) {
  return _paint(
    strokeColor: Colors.transparent,
    strokeWidth: stroke.width,
    strokeCap: StrokeCap.round,
    style: PaintingStyle.stroke,
    blendMode: BlendMode.clear,
  );
}

/// A utility function to create a [Paint] object for an erasing stroke with overridden stroke properties.
Paint eraseWithOverride(
  Stroke stroke, {
  Color? strokeColor,
  double? strokeWidth,
  StrokeCap? strokeCap,
  PaintingStyle? style,
}) {
  return _paint(
    strokeColor: strokeColor ?? stroke.color,
    strokeWidth: strokeWidth ?? stroke.width,
    strokeCap: strokeCap ?? StrokeCap.round,
    style: style ?? PaintingStyle.stroke,
    blendMode: BlendMode.clear,
  );
}

Paint _paint({
  required Color strokeColor,
  required double strokeWidth,
  required StrokeCap strokeCap,
  required PaintingStyle style,
  required BlendMode blendMode,
}) {
  final paint = Paint()
    ..strokeWidth = strokeWidth
    ..color = strokeColor
    ..strokeCap = strokeCap
    ..style = style
    ..blendMode = blendMode;

  return paint;
}
