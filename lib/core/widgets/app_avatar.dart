import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 头像。
///
/// 现阶段没有真实的图片资源，所以用「**稳定派生渐变 + Emoji**」作为占位：
///  - 不需要任何 assets，Mock 数据里只存一个 emoji 字符串；
///  - 同一个 [seed] 永远得到同一组渐变色，视觉上像"有真实头像"；
///  - 比灰色方块 / 首字母圆形更不像"加载失败"。
///
/// 将来接真实图片时，只需要在这里加一个 `CachedNetworkImage` 分支，
/// 所有用到头像的页面（动态流、会话列表、个人主页）自动生效。
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    required this.seed,
    this.emoji,
    this.size = 44,
    this.showOnlineDot = false,
    this.isOnline = false,
  });

  /// 稳定的派生种子，通常传用户 id。
  final String seed;

  /// 头像主体字符。为空时按 [seed] 从内置表情池里取一个。
  final String? emoji;

  final double size;

  /// 是否在右下角显示在线状态点。
  final bool showOnlineDot;

  final bool isOnline;

  /// 内置渐变池。都是低饱和、偏灰调的组合，避免头像抢走正文的注意力。
  static const List<List<Color>> _gradients = <List<Color>>[
    <Color>[Color(0xFFB8C6DB), Color(0xFF8FA3BF)],
    <Color>[Color(0xFFF5D9C8), Color(0xFFE0A98A)],
    <Color>[Color(0xFFC9E4DE), Color(0xFF8FC4B8)],
    <Color>[Color(0xFFE3D5F1), Color(0xFFB79ED4)],
    <Color>[Color(0xFFF7E0A3), Color(0xFFDDBA5E)],
    <Color>[Color(0xFFD6E4F0), Color(0xFF9CB8D4)],
    <Color>[Color(0xFFF2CFD8), Color(0xFFD99AAB)],
    <Color>[Color(0xFFD8E2C6), Color(0xFFA8BE8C)],
  ];

  static const List<String> _emojiPool = <String>[
    '🦊', '🐳', '🌿', '🍊', '🌙', '🐧', '🪴', '🛰️', '☕️', '🎧',
    '🧊', '🪐', '🍜', '🐢', '🎈', '🧭', '📮', '🪵',
  ];

  /// 稳定哈希。
  ///
  /// 刻意不用 `String.hashCode` —— 它在不同 Dart 进程间不保证一致，
  /// 会导致"重启 App 后头像颜色变了"这种玄学 bug。
  static int _stableHash(String value) {
    int hash = 7;
    for (int i = 0; i < value.length; i++) {
      hash = (hash * 31 + value.codeUnitAt(i)) & 0x7FFFFFFF;
    }
    return hash;
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final int hash = _stableHash(seed);
    final List<Color> gradient = _gradients[hash % _gradients.length];
    final String glyph = emoji ?? _emojiPool[hash % _emojiPool.length];

    final Widget avatar = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
      ),
      child: Text(
        glyph,
        // Emoji 的视觉重心比字号小，0.5 是经验上比较稳的比例。
        style: TextStyle(fontSize: size * 0.5, height: 1),
      ),
    );

    if (!showOnlineDot) {
      return avatar;
    }

    final double dotSize = size * 0.28;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          avatar,
          Positioned(
            right: -1,
            bottom: -1,
            child: Container(
              width: dotSize,
              height: dotSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isOnline ? AppColors.online : palette.labelTertiary,
                // 用页面底色描一圈，让状态点从头像上"浮"起来。
                border: Border.all(color: palette.canvas, width: dotSize * 0.18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 未读角标。
///
/// iOS 的角标是**实心圆角胶囊 + 白字**，超过两位就显示 `99+`。
/// 这里单独抽出来，是因为它同时出现在 Tab Bar、会话列表、消息按钮三处。
class UnreadBadge extends StatelessWidget {
  const UnreadBadge({super.key, required this.count, this.mini = false});

  final int count;

  /// 迷你尺寸：用于 Tab Bar 的图标右上角。
  final bool mini;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) {
      return const SizedBox.shrink();
    }

    final AppPalette palette = context.palette;
    final String text = count > 99 ? '99+' : '$count';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: mini ? 4 : 6, vertical: mini ? 0.5 : 1.5),
      constraints: BoxConstraints(minWidth: mini ? 14 : 18),
      decoration: BoxDecoration(
        color: palette.danger,
        borderRadius: BorderRadius.circular(mini ? 7 : 9),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: AppTypography.tabLabel.copyWith(
          color: Colors.white,
          fontSize: mini ? 9.5 : 11,
          height: 1.2,
        ),
      ),
    );
  }
}
