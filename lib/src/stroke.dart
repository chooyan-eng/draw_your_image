part of draw_your_image;

/// ストロークを表すクラス
///
/// ストロークは点群（[List<Offset>]）とメタデータ（色、幅、消しゴムフラグ）から構成される。
/// 点群データは UI とは独立したデータとして扱うことができ、
/// リサンプリングやスムーズ化などの加工を外部から行うことができる。
class Stroke {
  /// ストロークを構成する点群
  final List<Offset> points;

  /// ストロークの色
  final Color color;

  /// ストロークの幅
  final double width;

  /// 消しゴムモードかどうか
  final bool isErasing;

  /// ストロークを作成する
  Stroke({
    required this.points,
    required this.color,
    required this.width,
    this.isErasing = false,
  });

  /// 点群のコピーを返す（外部から変更されないように）
  List<Offset> getPoints() => List.unmodifiable(points);

  /// 新しい点群やメタデータで新しい Stroke を作成
  ///
  /// リサンプリングやスムーズ化などの加工を行う際に使用する。
  Stroke copyWith({
    List<Offset>? points,
    Color? color,
    double? width,
    bool? isErasing,
  }) {
    return Stroke(
      points: points ?? List.from(this.points),
      color: color ?? this.color,
      width: width ?? this.width,
      isErasing: isErasing ?? this.isErasing,
    );
  }
}
