import 'package:flutter/material.dart';

import 'app_colors.dart';

/// 语义化调色板。
///
/// 它被挂进 `ThemeData.extensions`，因此：
///  - 亮/暗模式切换时**自动**跟着换，业务代码里不需要写 `isDark ? a : b`；
///  - 主题切换过程可以平滑插值（[lerp]），不会出现"闪一下"的硬切。
///
/// 使用方式（见 [AppPaletteContext]）：
/// ```dart
/// final palette = context.palette;
/// Text('副标题', style: TextStyle(color: palette.labelSecondary));
/// ```
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.brightness,
    required this.accent,
    required this.accentSoft,
    required this.canvas,
    required this.surface,
    required this.surfaceRaised,
    required this.label,
    required this.labelSecondary,
    required this.labelTertiary,
    required this.separator,
    required this.fill,
    required this.glass,
    required this.like,
    required this.danger,
    required this.success,
    required this.shadow,
    required this.shadowSoft,
  });

  /// 当前亮度。[lerp] 对它取阶跃（不做插值）。
  final Brightness brightness;

  /// 强调色 / 可点击的链接色。
  final Color accent;

  /// 强调色的淡化底，用于选中的胶囊、标签背景。
  final Color accentSoft;

  /// 页面底色（iOS `systemGroupedBackground`）。
  final Color canvas;

  /// 卡片 / 内容块底色。
  final Color surface;

  /// 浮起面：输入框、分组列表、弹层。
  final Color surfaceRaised;

  /// 主文字。
  final Color label;

  /// 副文字（60%）。
  final Color labelSecondary;

  /// 三级文字（30%）。
  final Color labelTertiary;

  /// 细分割线。配合 `HairlineDivider` 使用。
  final Color separator;

  /// 填充色（12%）：输入框底、未选中胶囊。
  final Color fill;

  /// 毛玻璃面的着色层。配合 `GlassSurface` / `CupertinoTabBar` 的半透明背景。
  final Color glass;

  /// 点赞红。
  final Color like;

  /// 危险 / 错误。
  final Color danger;

  /// 成功。
  final Color success;

  /// 投影基色（重）。
  final Color shadow;

  /// 投影基色（轻）。
  final Color shadowSoft;

  /// 是否深色。业务里可以用它做少数无法用 token 表达的分支
  /// （比如 `Image.asset` 的二套配图），但**优先**用上面的语义色。
  bool get isDark => brightness == Brightness.dark;

  /// 亮色模式。
  static const AppPalette light = AppPalette(
    brightness: Brightness.light,
    accent: AppColors.accentLight,
    accentSoft: AppColors.accentSoftLight,
    canvas: AppColors.backgroundLight,
    surface: AppColors.surfaceLight,
    surfaceRaised: AppColors.surfaceRaisedLight,
    label: AppColors.labelLight,
    labelSecondary: AppColors.labelSecondaryLight,
    labelTertiary: AppColors.labelTertiaryLight,
    separator: AppColors.separatorLight,
    fill: AppColors.fillLight,
    glass: AppColors.glassTintLight,
    like: AppColors.like,
    danger: AppColors.danger,
    success: AppColors.success,
    shadow: AppColors.shadowLight,
    shadowSoft: AppColors.shadowSoftLight,
  );

  /// 深色模式。
  static const AppPalette dark = AppPalette(
    brightness: Brightness.dark,
    accent: AppColors.accentDark,
    accentSoft: AppColors.accentSoftDark,
    canvas: AppColors.backgroundDark,
    surface: AppColors.surfaceDark,
    surfaceRaised: AppColors.surfaceRaisedDark,
    label: AppColors.labelDark,
    labelSecondary: AppColors.labelSecondaryDark,
    labelTertiary: AppColors.labelTertiaryDark,
    separator: AppColors.separatorDark,
    fill: AppColors.fillDark,
    glass: AppColors.glassTintDark,
    like: AppColors.like,
    danger: AppColors.danger,
    success: AppColors.success,
    shadow: AppColors.shadowDark,
    shadowSoft: AppColors.shadowSoftDark,
  );

  @override
  AppPalette copyWith({
    Brightness? brightness,
    Color? accent,
    Color? accentSoft,
    Color? canvas,
    Color? surface,
    Color? surfaceRaised,
    Color? label,
    Color? labelSecondary,
    Color? labelTertiary,
    Color? separator,
    Color? fill,
    Color? glass,
    Color? like,
    Color? danger,
    Color? success,
    Color? shadow,
    Color? shadowSoft,
  }) {
    return AppPalette(
      brightness: brightness ?? this.brightness,
      accent: accent ?? this.accent,
      accentSoft: accentSoft ?? this.accentSoft,
      canvas: canvas ?? this.canvas,
      surface: surface ?? this.surface,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      label: label ?? this.label,
      labelSecondary: labelSecondary ?? this.labelSecondary,
      labelTertiary: labelTertiary ?? this.labelTertiary,
      separator: separator ?? this.separator,
      fill: fill ?? this.fill,
      glass: glass ?? this.glass,
      like: like ?? this.like,
      danger: danger ?? this.danger,
      success: success ?? this.success,
      shadow: shadow ?? this.shadow,
      shadowSoft: shadowSoft ?? this.shadowSoft,
    );
  }

  @override
  AppPalette lerp(covariant ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) {
      return this;
    }
    return AppPalette(
      // 亮度是离散值，插值到一半时直接切换，避免出现"半个深色主题"。
      brightness: t < 0.5 ? brightness : other.brightness,
      accent: Color.lerp(accent, other.accent, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      canvas: Color.lerp(canvas, other.canvas, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      label: Color.lerp(label, other.label, t)!,
      labelSecondary: Color.lerp(labelSecondary, other.labelSecondary, t)!,
      labelTertiary: Color.lerp(labelTertiary, other.labelTertiary, t)!,
      separator: Color.lerp(separator, other.separator, t)!,
      fill: Color.lerp(fill, other.fill, t)!,
      glass: Color.lerp(glass, other.glass, t)!,
      like: Color.lerp(like, other.like, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      success: Color.lerp(success, other.success, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
      shadowSoft: Color.lerp(shadowSoft, other.shadowSoft, t)!,
    );
  }
}

/// 一行拿到当前主题的调色板。
extension AppPaletteContext on BuildContext {
  /// 当前 [AppPalette]。
  ///
  /// 兜底返回亮色，保证在极少数（测试 / 未挂 extensions 的）场景下不会崩。
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.light;

  /// 当前亮度，等价于 `Theme.of(this).brightness`，但读起来更顺。
  Brightness get brightness => Theme.of(this).brightness;
}
