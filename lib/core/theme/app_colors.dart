import 'package:flutter/widgets.dart';

/// Pulse 的原始色板（Design Tokens 的最底层）。
///
/// 全部以 Apple HIG 的 System Colors 为基准，alpha 值刻意写成 16 进制，
/// 以便和 iOS 系统色的语义一一对应：
///
/// | iOS 语义色                    | 不透明度 | 这里的常量                |
/// |------------------------------|---------|--------------------------|
/// | `secondaryLabel`             | 60%     | `labelSecondaryLight`    |
/// | `tertiaryLabel`              | 30%     | `labelTertiaryLight`     |
/// | `separator`                  | 29%     | `separatorLight`         |
/// | `systemFill`                 | 12%     | `fillLight`              |
/// | `systemGroupedBackground`    | 100%    | `backgroundLight`        |
///
/// 注意：这一层只放"颜色值"，不做语义映射。语义映射在 `AppPalette` 里完成，
/// 这样以后换皮（比如出一个 AMOLED 纯黑主题）只需要新增一个 Palette。
abstract final class AppColors {
  // MARK: - Accent（iOS systemBlue）

  /// 浅色模式强调色。经典 iOS 蓝，饱和度刻意不拉满，避免"Android 味"。
  static const Color accentLight = Color(0xFF007AFF);

  /// 深色模式强调色。深色底上必须提亮，否则对比度不达 WCAG AA。
  static const Color accentDark = Color(0xFF0A84FF);

  /// 强调色的淡化底（用于选中的胶囊、标签背景）。
  static const Color accentSoftLight = Color(0x1A007AFF); // 10%
  static const Color accentSoftDark = Color(0x290A84FF); // 16%

  // MARK: - Light

  /// 页面底色：`systemGroupedBackground`，冷调灰白，是 iOS "大量留白"的底。
  static const Color backgroundLight = Color(0xFFF2F2F7);

  /// 卡片 / 内容块底色。
  static const Color surfaceLight = Color(0xFFFFFFFF);

  /// 浮起面（输入框、弹出面板、分组列表）。
  static const Color surfaceRaisedLight = Color(0xFFFFFFFF);

  /// 主文字：近黑深灰，而不是纯黑——纯黑在白底上过于生硬。
  static const Color labelLight = Color(0xFF1C1C1E);

  /// 副文字（60%）：`secondaryLabel`，用于 handle、时间戳、说明文案。
  static const Color labelSecondaryLight = Color(0x993C3C43);

  /// 三级文字（30%）：极淡的提示、占位符。
  static const Color labelTertiaryLight = Color(0x4D3C3C43);

  /// 细分割线（29%）。
  static const Color separatorLight = Color(0x4A3C3C43);

  /// 填充色（12%）：输入框底、未选中的胶囊。
  static const Color fillLight = Color(0x1F767680);

  /// 毛玻璃面的着色层（72% 白）。配合高斯模糊即为 iOS 的 bar 观感。
  static const Color glassTintLight = Color(0xB8FFFFFF);

  /// 投影基色（8%）。
  static const Color shadowLight = Color(0x14000000);
  static const Color shadowSoftLight = Color(0x0A000000);

  // MARK: - Dark

  static const Color backgroundDark = Color(0xFF000000);
  static const Color surfaceDark = Color(0xFF1C1C1E);
  static const Color surfaceRaisedDark = Color(0xFF2C2C2E);
  static const Color labelDark = Color(0xFFFFFFFF);
  static const Color labelSecondaryDark = Color(0x99EBEBF5);
  static const Color labelTertiaryDark = Color(0x4DEBEBF5);
  static const Color separatorDark = Color(0xA6545458);
  static const Color fillDark = Color(0x33767680);
  static const Color glassTintDark = Color(0xC71C1C1E);
  static const Color shadowDark = Color(0x66000000);
  static const Color shadowSoftDark = Color(0x40000000);

  // MARK: - Semantic

  /// 点赞。比 `systemRed` 更偏玫红，在浅色卡片上更跳。
  static const Color like = Color(0xFFFF375F);

  /// 危险 / 错误：`systemRed`。
  static const Color danger = Color(0xFFFF3B30);

  /// 成功：`systemGreen`。
  static const Color success = Color(0xFF34C759);

  /// 警告：`systemOrange`。
  static const Color warning = Color(0xFFFF9500);

  /// 在线状态点：`systemGreen` 提亮版，在深色底上也够亮。
  static const Color online = Color(0xFF30D158);
}
