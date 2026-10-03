import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_mode_provider.dart';

/// 外观模式切换（浅色 / 深色 / 跟随系统）。
///
/// 这不是一个"演示控件"——它验证的是整套主题架构是否真的成立：
///  - 两个 `AppPalette` 都挂在 `ThemeData.extensions` 上；
///  - 业务代码一律读 `context.palette`，没有任何 `isDark ? a : b`；
///  - 于是切换时**零改动**、零遗漏，所有页面一起变。
///
/// 如果哪个页面在深色模式下出现白底黑字，说明它硬编码了颜色 ——
/// 这个小控件就是最省事的一致性测试。
class ThemeModeSelector extends ConsumerWidget {
  const ThemeModeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppPalette palette = context.palette;
    final ThemeMode mode = ref.watch(themeModeProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.cardPadding),
      child: SizedBox(
        height: 48,
        child: Center(
          child: CupertinoSlidingSegmentedControl<ThemeMode>(
            groupValue: mode,
            // 深色模式下 thumb 要用更亮的浮起面，否则在纯黑底上"选中"看不出来。
            thumbColor: palette.isDark
                ? AppColors.surfaceRaisedDark
                : palette.surface,
            backgroundColor: palette.fill,
            children: <ThemeMode, Widget>{
              for (final ThemeMode item in ThemeMode.values)
                item: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Text(
                    item.label,
                    style: AppTypography.subheadline.copyWith(
                      color: item == mode ? palette.label : palette.labelSecondary,
                      fontWeight:
                          item == mode ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
            },
            onValueChanged: (ThemeMode? value) {
              if (value == null || value == mode) {
                return;
              }
              AppHaptics.selection();
              ref.read(themeModeProvider.notifier).setMode(value);
            },
          ),
        ),
      ),
    );
  }
}
