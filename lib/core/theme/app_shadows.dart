import 'package:flutter/widgets.dart';

import 'app_colors.dart';

/// 微渐变投影。
///
/// Apple 的界面里几乎看不到"一片黑"的硬阴影。真实做法是**叠两到三层**
/// 极低透明度、大模糊半径、并带**负 spread** 的阴影：
///
///  - 第一层：小 blur + 贴近元素，负责勾勒"贴地感"；
///  - 第二层：大 blur + 负 spread，负责制造柔和的外扩渐隐；
///  - 负 spread 是关键，它把阴影往回收，避免元素周围出现一圈"发霉"的灰边。
///
/// 深色模式下的阴影要更黑（浅色底上 8% 的黑在深色底上根本看不见），
/// 但**不能**更亮，否则会变成发光的"浮雕感"。
abstract final class AppShadows {
  // MARK: - 卡片（动态流里的 PostCard）

  static const List<BoxShadow> card = <BoxShadow>[
    BoxShadow(color: AppColors.shadowSoftLight, blurRadius: 2, offset: Offset(0, 1)),
    BoxShadow(
      color: AppColors.shadowLight,
      blurRadius: 16,
      offset: Offset(0, 6),
      spreadRadius: -6,
    ),
  ];

  static const List<BoxShadow> cardDark = <BoxShadow>[
    BoxShadow(color: AppColors.shadowSoftDark, blurRadius: 2, offset: Offset(0, 1)),
    BoxShadow(
      color: AppColors.shadowDark,
      blurRadius: 16,
      offset: Offset(0, 6),
      spreadRadius: -6,
    ),
  ];

  // MARK: - 浮起面（悬浮按钮、下拉面板、模态卡片）

  static const List<BoxShadow> raised = <BoxShadow>[
    BoxShadow(color: AppColors.shadowSoftLight, blurRadius: 4, offset: Offset(0, 2)),
    BoxShadow(
      color: AppColors.shadowLight,
      blurRadius: 24,
      offset: Offset(0, 12),
      spreadRadius: -8,
    ),
  ];

  static const List<BoxShadow> raisedDark = <BoxShadow>[
    BoxShadow(color: AppColors.shadowSoftDark, blurRadius: 4, offset: Offset(0, 2)),
    BoxShadow(
      color: AppColors.shadowDark,
      blurRadius: 24,
      offset: Offset(0, 12),
      spreadRadius: -8,
    ),
  ];

  // MARK: - 悬浮按钮（比 raised 更集中，避免"糊一团"）

  static const List<BoxShadow> floating = <BoxShadow>[
    BoxShadow(
      color: AppColors.shadowLight,
      blurRadius: 10,
      offset: Offset(0, 4),
      spreadRadius: -2,
    ),
    BoxShadow(
      color: AppColors.shadowSoftLight,
      blurRadius: 24,
      offset: Offset(0, 10),
      spreadRadius: -4,
    ),
  ];

  static const List<BoxShadow> floatingDark = <BoxShadow>[
    BoxShadow(
      color: AppColors.shadowDark,
      blurRadius: 10,
      offset: Offset(0, 4),
      spreadRadius: -2,
    ),
    BoxShadow(
      color: AppColors.shadowSoftDark,
      blurRadius: 24,
      offset: Offset(0, 10),
      spreadRadius: -4,
    ),
  ];

  // MARK: - 顶栏 / 底栏上浮

  /// 只向上投影。用于底部 Tab Bar 之上、需要和滚动内容拉开层次的地方。
  static const List<BoxShadow> barTop = <BoxShadow>[
    BoxShadow(
      color: AppColors.shadowSoftLight,
      blurRadius: 24,
      offset: Offset(0, -6),
      spreadRadius: -12,
    ),
  ];

  static const List<BoxShadow> barTopDark = <BoxShadow>[
    BoxShadow(
      color: AppColors.shadowSoftDark,
      blurRadius: 24,
      offset: Offset(0, -6),
      spreadRadius: -12,
    ),
  ];

  /// 按亮度取"卡片阴影"。
  static List<BoxShadow> cardFor(Brightness brightness) =>
      brightness == Brightness.dark ? cardDark : card;

  /// 按亮度取"浮起面阴影"。
  static List<BoxShadow> raisedFor(Brightness brightness) =>
      brightness == Brightness.dark ? raisedDark : raised;

  /// 按亮度取"悬浮按钮阴影"。
  static List<BoxShadow> floatingFor(Brightness brightness) =>
      brightness == Brightness.dark ? floatingDark : floating;

  /// 按亮度取"上浮栏阴影"。
  static List<BoxShadow> barTopFor(Brightness brightness) =>
      brightness == Brightness.dark ? barTopDark : barTop;
}
