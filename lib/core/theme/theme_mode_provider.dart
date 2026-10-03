import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 全局外观模式（浅色 / 深色 / 跟随系统）。
///
/// 这里刻意用 `Notifier` 而不是 `StateProvider`：后者在 Riverpod 3 里已经被
/// 归入 `legacy`，需要额外 import `package:flutter_riverpod/legacy.dart`。
///
/// 现阶段只存在内存里。将来接 `shared_preferences` 时，把读写放进
/// `build()` 与 [setMode] 即可，UI 层一行都不用改。
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.system;

  /// 切换外观模式。
  void setMode(ThemeMode mode) {
    if (state == mode) {
      return;
    }
    state = mode;
  }

  /// 在「跟随系统 → 浅色 → 深色」之间循环（供长按快捷切换用）。
  void cycle() {
    state = switch (state) {
      ThemeMode.system => ThemeMode.light,
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
    };
  }
}

/// 全局外观模式。
///
/// 在 `PulseApp` 里 `ref.watch` 它并交给 `MaterialApp.themeMode`；
/// 注意 `ThemeMode.system` 不需要我们自己去读平台亮度，
/// `MaterialApp` 会根据 `darkTheme` + `mediaQueryData.platformBrightness` 自行解析。
final NotifierProvider<ThemeModeNotifier, ThemeMode> themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

/// 外观模式的中文名，供设置页展示。
extension ThemeModeLabel on ThemeMode {
  String get label => switch (this) {
        ThemeMode.system => '跟随系统',
        ThemeMode.light => '浅色',
        ThemeMode.dark => '深色',
      };

  /// 简短符号，用于分段控件的极小屏适配。
  String get symbol => switch (this) {
        ThemeMode.system => 'A',
        ThemeMode.light => '☀',
        ThemeMode.dark => '☾',
      };
}
