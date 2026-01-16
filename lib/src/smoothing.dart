part of draw_your_image;

/// Path スムーズ化モード
enum SmoothingMode {
  /// スムーズ化なし（直線補間）
  none,

  /// Catmull-Rom スプライン補間
  catmullRom,
}

/// SmoothingMode の拡張
extension SmoothingModeExtension on SmoothingMode {
  /// このモードに対応する変換関数を取得
  Path Function(Stroke) toConverter() {
    switch (this) {
      case SmoothingMode.none:
        return generateLinearPath;
      case SmoothingMode.catmullRom:
        return generateCatmullRomPath;
    }
  }
}

/// 直線補間で Path を生成
///
/// ストロークの点群を順番に線で結んで Path を作成する。
Path generateLinearPath(Stroke stroke) {
  final path = Path();
  final points = stroke.points;

  if (points.isEmpty) return path;

  if (points.length == 1) {
    // 単一点の場合は小さな円を描画
    path.addOval(Rect.fromCircle(center: points[0], radius: 0.5));
    return path;
  }

  path.moveTo(points[0].dx, points[0].dy);
  for (int i = 1; i < points.length; i++) {
    path.lineTo(points[i].dx, points[i].dy);
  }

  return path;
}

/// Catmull-Rom スプライン補間で Path を生成
///
/// ストロークの点群を Catmull-Rom スプライン曲線でスムーズに結んで Path を作成する。
/// [tension] パラメータで曲線の張力を調整できる（デフォルト: 0.5）。
Path generateCatmullRomPath(Stroke stroke, {double tension = 0.5}) {
  final path = Path();
  final points = stroke.points;

  if (points.isEmpty) return path;

  if (points.length == 1) {
    // 単一点の場合は小さな円を描画
    path.addOval(Rect.fromCircle(center: points[0], radius: 0.5));
    return path;
  }

  path.moveTo(points[0].dx, points[0].dy);

  if (points.length == 2) {
    path.lineTo(points[1].dx, points[1].dy);
    return path;
  }

  // Catmull-Rom スプライン補間
  for (int i = 0; i < points.length - 1; i++) {
    final p0 = i > 0 ? points[i - 1] : points[i];
    final p1 = points[i];
    final p2 = points[i + 1];
    final p3 = i < points.length - 2 ? points[i + 2] : p2;

    // Catmull-Rom の制御点計算
    final cp1x = p1.dx + (p2.dx - p0.dx) / 6 * tension;
    final cp1y = p1.dy + (p2.dy - p0.dy) / 6 * tension;
    final cp2x = p2.dx - (p3.dx - p1.dx) / 6 * tension;
    final cp2y = p2.dy - (p3.dy - p1.dy) / 6 * tension;

    path.cubicTo(cp1x, cp1y, cp2x, cp2y, p2.dx, p2.dy);
  }

  return path;
}
