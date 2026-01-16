part of draw_your_image;

/// 点群を等間隔にリサンプリング
///
/// ストロークの点群を指定された [spacing] の間隔で再サンプリングする。
/// これにより、点の密度を均一化したり、点数を削減したりできる。
///
/// [points] - リサンプリングする点群
/// [spacing] - 点と点の間隔（ピクセル単位）
///
/// 返り値: リサンプリングされた点群
List<Offset> resamplePoints(List<Offset> points, double spacing) {
  if (points.length < 2) return List.from(points);

  final resampled = <Offset>[points.first];
  double accumulatedDistance = 0;

  for (int i = 1; i < points.length; i++) {
    final distance = (points[i] - points[i - 1]).distance;
    accumulatedDistance += distance;

    while (accumulatedDistance >= spacing) {
      final ratio = (accumulatedDistance - spacing) / distance;
      final interpolated = Offset.lerp(points[i], points[i - 1], ratio)!;
      resampled.add(interpolated);
      accumulatedDistance -= spacing;
    }
  }

  // 最後の点を追加
  if ((resampled.last - points.last).distance > spacing / 2) {
    resampled.add(points.last);
  }

  return resampled;
}
