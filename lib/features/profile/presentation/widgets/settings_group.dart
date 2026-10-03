import 'package:flutter/cupertino.dart';

import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/hairline_divider.dart';
import '../../../../core/widgets/pressable.dart';

/// iOS 的 inset grouped 列表容器。
///
/// 「分组 + 缩进 + 卡片圆角」是设置页的 HIG 标准结构。手写它的价值在于：
/// 分割线只出现在**卡片内部**（最后一行不加），且缩进到文字起始位置。
class InsetGroup extends StatelessWidget {
  const InsetGroup({
    super.key,
    required this.children,
    this.title,
    this.footer,
  });

  final List<Widget> children;

  /// 分组标题（卡片上方的小灰字）。
  final String? title;

  /// 分组说明（卡片下方的小灰字）。
  final String? footer;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenH + AppSpacing.xs,
                0,
                AppSpacing.screenH,
                AppSpacing.sm,
              ),
              child: Text(
                title!,
                style: AppTypography.footnote.copyWith(
                  color: palette.labelSecondary,
                ),
              ),
            ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: AppRadius.cardAll,
              boxShadow: AppShadows.cardFor(palette.brightness),
            ),
            // 圆角裁剪，避免第一/最后一行的点击高亮溢出圆角。
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: _withDividers(children),
            ),
          ),
          if (footer != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenH + AppSpacing.xs,
                AppSpacing.sm,
                AppSpacing.screenH,
                AppSpacing.sm,
              ),
              child: Text(
                footer!,
                style: AppTypography.footnote.copyWith(
                  color: palette.labelSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 在行之间插入 hairline，但**不在最后一行之后**插入。
  static List<Widget> _withDividers(List<Widget> rows) {
    final List<Widget> result = <Widget>[];
    for (int i = 0; i < rows.length; i++) {
      result.add(rows[i]);
      if (i != rows.length - 1) {
        result.add(
          const HairlineDivider(indent: AppSpacing.cardPadding + 28 + AppSpacing.md),
        );
      }
    }
    return result;
  }
}

/// inset grouped 列表里的一行。
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.label,
    this.icon,
    this.value,
    this.trailing,
    this.onTap,
    this.danger = false,
  });

  final String label;

  final IconData? icon;

  /// 右侧的当前值（灰色小字）。
  final String? value;

  /// 完全自定义右侧内容。给了它就不画箭头。
  final Widget? trailing;

  final VoidCallback? onTap;

  /// 危险操作（退出登录）：文字与图标都用 danger 色。
  final bool danger;

  static const double height = 50;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final Color labelColor = danger ? palette.danger : palette.label;
    final Color iconColor = danger ? palette.danger : palette.labelSecondary;

    return Pressable(
      onTap: onTap == null
          ? null
          : () {
              AppHaptics.light();
              onTap!();
            },
      // 列表行只做极轻微的回弹，否则整块卡片看起来像在"抖"。
      scale: 0.99,
      child: SizedBox(
        height: height,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.cardPadding),
          child: Row(
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Icon(icon, size: 20, color: iconColor),
                const SizedBox(width: AppSpacing.md),
              ],
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.body.copyWith(color: labelColor),
                ),
              ),
              if (value != null) ...<Widget>[
                Text(
                  value!,
                  style: AppTypography.subheadline.copyWith(
                    color: palette.labelSecondary,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              if (trailing != null)
                trailing!
              else if (onTap != null && !danger)
                Icon(
                  CupertinoIcons.chevron_forward,
                  size: 14,
                  color: palette.labelTertiary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
