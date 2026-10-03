import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// iOS 的"1 物理像素"分割线。
///
/// 直接用 `Divider(thickness: 1)` 在 3x 屏上会得到**3 物理像素**的粗线，
/// 和 iOS 的观感差了整整一个量级 —— 这是"看起来不像 iOS"的高频原因之一。
/// 这里按设备像素比把逻辑高度换算成真正的 hairline。
///
/// 分割线的颜色语义：
///  - 列表之间用 [AppPalette.separator]（29% 灰，能看见但很轻）；
///  - 若分割线需要"更实"，用 [AppPalette.labelTertiary]。
class HairlineDivider extends StatelessWidget {
  const HairlineDivider({
    super.key,
    this.indent = 0,
    this.endIndent = 0,
    this.color,
    this.axis = Axis.horizontal,
  });

  /// 左缩进。iOS 列表的经典做法是缩进到"文字起始位置"（头像宽度 + 间距），
  /// 让分割线与文字左对齐而不是与整行左对齐。
  final double indent;

  final double endIndent;

  final Color? color;

  final Axis axis;

  @override
  Widget build(BuildContext context) {
    final double ratio = MediaQuery.devicePixelRatioOf(context);
    final double thickness = 1 / ratio;
    final Color lineColor = color ?? context.palette.separator;

    if (axis == Axis.vertical) {
      return Padding(
        padding: EdgeInsetsDirectional.only(top: indent, bottom: endIndent),
        child: SizedBox(
          width: thickness,
          child: ColoredBox(color: lineColor),
        ),
      );
    }

    return Padding(
      padding: EdgeInsetsDirectional.only(start: indent, end: endIndent),
      child: SizedBox(
        height: thickness,
        child: ColoredBox(color: lineColor),
      ),
    );
  }
}
