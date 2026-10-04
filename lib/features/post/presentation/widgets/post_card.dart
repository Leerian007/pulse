import 'package:flutter/cupertino.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/date_format.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/pressable.dart';
import '../../domain/entities/post.dart';

/// 动态卡片。
///
/// 视觉拆解（自上而下）：
///  1. 作者行：头像 + 昵称（含认证标记）+ `@handle · 时间`；
///  2. 正文：17pt / 行高 1.29，这是 Apple 正文的标准观感；
///  3. 配图占位：16:10 圆角块 + Emoji + 说明文字；
///  4. 话题胶囊：accentSoft 底 + accent 字，11pt；
///  5. 操作栏：点赞（乐观更新）/ 评论 / 转发 / 分享。
///
/// 交互上只做了一件事：**整卡可按下 + 点赞即时变色**。
/// 卡片的 `onTap` 预留给了下一阶段的详情页路由。
class PostCard extends StatelessWidget {
  const PostCard({
    super.key,
    required this.post,
    this.onTap,
    this.onLike,
    this.onComment,
    this.onRepost,
    this.onShare,
  });

  final Post post;

  /// 进入详情页。当前阶段传 `null`（详情页尚未实现）。
  final VoidCallback? onTap;

  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onRepost;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return Pressable(
      onTap: onTap,
      // 大卡片只缩 1.5%。缩太多会显得"廉价"，这是 iOS 与 Android 的审美差别之一。
      scale: 0.985,
      borderRadius: AppRadius.cardAll,
      child: Container(
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: AppRadius.cardAll,
          // 微渐变投影：两层叠加 + 负 spread，见 AppShadows 的说明。
          boxShadow: AppShadows.cardFor(palette.brightness),
        ),
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _AuthorRow(post: post),
            const SizedBox(height: AppSpacing.md),
            Text(
              post.content,
              style: AppTypography.body.copyWith(color: palette.label),
            ),
            // 两条配图路径：有真图走真图，否则回落到 emoji 占位。
            // 顺序不能反 —— 有真图时 emoji 只作为加载兜底，不再单独占一块。
            if (post.hasImages) ...<Widget>[
              const SizedBox(height: AppSpacing.md),
              _PostImages(images: post.images, caption: post.coverCaption),
            ] else if (post.hasCover) ...<Widget>[
              const SizedBox(height: AppSpacing.md),
              _CoverPlaceholder(
                emoji: post.coverEmoji!,
                caption: post.coverCaption,
              ),
            ],
            if (post.topics.isNotEmpty) ...<Widget>[
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: <Widget>[
                  for (final String topic in post.topics) _TopicChip(label: topic),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            _ActionBar(
              post: post,
              onLike: onLike,
              onComment: onComment,
              onRepost: onRepost,
              onShare: onShare,
            ),
          ],
        ),
      ),
    );
  }
}

/// 作者行。
class _AuthorRow extends StatelessWidget {
  const _AuthorRow({required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        AppAvatar(
          seed: post.author.id,
          imageUrl: post.author.avatarUrl,
          emoji: post.author.emoji,
          size: 42,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Flexible(
                    child: Text(
                      post.author.name,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.headline.copyWith(color: palette.label),
                    ),
                  ),
                  if (post.author.isVerified) ...<Widget>[
                    const SizedBox(width: AppSpacing.xs),
                    Icon(
                      CupertinoIcons.checkmark_seal_fill,
                      size: 14,
                      color: palette.accent,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                '@${post.author.handle} · ${formatRelativeTime(post.createdAt)}',
                overflow: TextOverflow.ellipsis,
                // 副标题用 60% 灰 —— 层级靠"颜色"而不是"字号"拉开，
                // 这是 Apple 最典型的排版手法。
                style: AppTypography.subheadline.copyWith(
                  color: palette.labelSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 真实配图（1~N 张）。
///
/// 布局按张数分档，不是简单等宽排开 —— 这是信息流配图的通用做法：
///  - **1 张** → 16:10 通栏。单图给足面积，是内容的主角；
///  - **2 张以上** → 1:1 方阵平铺，最多显示 [_maxVisible] 张。
///
/// 超出部分叠一个 `+N` 蒙层而不是静默截断：用户需要知道"还有更多"，
/// 否则会误以为这条动态只有三张图。
class _PostImages extends StatelessWidget {
  const _PostImages({required this.images, this.caption});

  final List<String> images;
  final String? caption;

  /// 最多同时显示几张。3 张是"一行放得下又不至于太窄"的上限，
  /// 再多了单张宽度会低于可用点击区域的最小尺寸。
  static const int _maxVisible = 3;

  /// 图片蒙层色。刻意**不**走 `palette`：这是一层盖在照片上的遮罩，
  /// 语义与主题无关（Apple 自家的照片叠层也是恒定黑），
  /// 跟着亮暗模式变幻会让深色主题下的白底照片失去可读性。
  static const Color _scrim = Color(0x8C000000);

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    final int visibleCount =
        images.length > _maxVisible ? _maxVisible : images.length;
    final int hiddenCount = images.length - visibleCount;

    final Widget grid = visibleCount == 1
        ? AspectRatio(
            aspectRatio: 16 / 10,
            child: _tile(context, 0, hiddenCount),
          )
        : Row(
            children: <Widget>[
              for (int i = 0; i < visibleCount; i++) ...<Widget>[
                if (i > 0) const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: _tile(
                      context,
                      i,
                      // 只有最后一张盖蒙层，否则每张都写 +N 会重复。
                      i == visibleCount - 1 ? hiddenCount : 0,
                    ),
                  ),
                ),
              ],
            ],
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ClipRRect(
          borderRadius: AppRadius.mdAll,
          child: grid,
        ),
        if (caption != null) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          Text(
            caption!,
            style: AppTypography.footnote.copyWith(color: palette.labelSecondary),
          ),
        ],
      ],
    );
  }

  /// 单块图。[hiddenCount] > 0 时叠 `+N` 蒙层。
  Widget _tile(BuildContext context, int index, int hiddenCount) {
    final AppPalette palette = context.palette;

    final Widget image = AppNetworkImage(
      url: images[index],
      width: double.infinity,
      height: double.infinity,
      // 图片挂了也要占住位置，不能塌成 0 高度导致列表跳动。
      fallback: ColoredBox(
        color: palette.surfaceRaised,
        child: Center(
          child: Icon(
            CupertinoIcons.photo,
            size: 22,
            color: palette.labelTertiary,
          ),
        ),
      ),
    );

    if (hiddenCount <= 0) {
      return image;
    }

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        image,
        ColoredBox(
          color: _scrim,
          child: Center(
            child: Text(
              '+$hiddenCount',
              style: AppTypography.title2.copyWith(color: CupertinoColors.white),
            ),
          ),
        ),
      ],
    );
  }
}

/// 配图占位。
///
/// 现阶段不引入任何图片资源，用「稳定派生渐变 + Emoji」模拟一张照片。
/// 换成真实图片时，把 [DecoratedBox] + [Center] 换成 `CachedNetworkImage` 即可。
class _CoverPlaceholder extends StatelessWidget {
  const _CoverPlaceholder({required this.emoji, this.caption});

  final String emoji;
  final String? caption;

  static const List<List<Color>> _gradients = <List<Color>>[
    <Color>[Color(0xFFE8EDF5), Color(0xFFC9D6E8)],
    <Color>[Color(0xFFFBEDE3), Color(0xFFEBD0B8)],
    <Color>[Color(0xFFE6F1EE), Color(0xFFC2DCD4)],
    <Color>[Color(0xFFEFE9F7), Color(0xFFD4C7E8)],
    <Color>[Color(0xFFF8F1DC), Color(0xFFE8D9B0)],
  ];

  static int _stableHash(String value) {
    int hash = 11;
    for (int i = 0; i < value.length; i++) {
      hash = (hash * 31 + value.codeUnitAt(i)) & 0x7FFFFFFF;
    }
    return hash;
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final List<Color> gradient = _gradients[_stableHash(emoji) % _gradients.length];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ClipRRect(
          borderRadius: AppRadius.mdAll,
          child: AspectRatio(
            aspectRatio: 16 / 10,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradient,
                ),
              ),
              child: Center(
                child: Text(
                  emoji,
                  // 大 Emoji 在小尺寸下会显得糊，用 56 是经验值。
                  style: const TextStyle(fontSize: 56, height: 1),
                ),
              ),
            ),
          ),
        ),
        if (caption != null) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          Text(
            caption!,
            style: AppTypography.footnote.copyWith(color: palette.labelSecondary),
          ),
        ],
      ],
    );
  }
}

/// 话题胶囊。
class _TopicChip extends StatelessWidget {
  const _TopicChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs + 1,
      ),
      decoration: BoxDecoration(
        color: palette.accentSoft,
        borderRadius: AppRadius.pillAll,
      ),
      child: Text(
        '#$label',
        style: AppTypography.caption1.copyWith(
          color: palette.accent,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// 操作栏：点赞 / 评论 / 转发 / 分享。
class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.post,
    this.onLike,
    this.onComment,
    this.onRepost,
    this.onShare,
  });

  final Post post;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onRepost;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final double ratio = MediaQuery.devicePixelRatioOf(context);

    return Column(
      children: <Widget>[
        // hairline 而不是 Divider：1 物理像素，见 HairlineDivider 的说明。
        SizedBox(
          height: 1 / ratio,
          child: ColoredBox(color: palette.separator),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: <Widget>[
            _ActionButton(
              icon: CupertinoIcons.heart,
              activeIcon: CupertinoIcons.heart_fill,
              count: post.likeCount,
              active: post.likedByMe,
              activeColor: palette.like,
              onTap: onLike,
            ),
            _ActionButton(
              icon: CupertinoIcons.chat_bubble,
              count: post.commentCount,
              activeColor: palette.accent,
              onTap: onComment,
            ),
            _ActionButton(
              icon: CupertinoIcons.arrow_2_squarepath,
              count: post.repostCount,
              activeColor: palette.success,
              onTap: onRepost,
            ),
            const Spacer(),
            _ActionButton(
              icon: CupertinoIcons.share,
              activeColor: palette.accent,
              onTap: onShare,
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    this.activeIcon,
    this.count,
    this.active = false,
    required this.activeColor,
    this.onTap,
  });

  final IconData icon;
  final IconData? activeIcon;
  final int? count;
  final bool active;
  final Color activeColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final Color color = active ? activeColor : palette.labelTertiary;
    final IconData glyph = active && activeIcon != null ? activeIcon! : icon;

    return Pressable(
      onTap: onTap,
      scale: 0.88,
      borderRadius: AppRadius.pillAll,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // AnimatedSwitcher 让"空心 → 实心"有一个缩放弹跳，
            // 而不是干巴巴地换一个图标 —— 点赞是这套 UI 里最需要"情绪"的动作。
            AnimatedSwitcher(
              duration: AppDuration.fast,
              switchInCurve: AppCurves.spring,
              transitionBuilder: (Widget child, Animation<double> animation) {
                return ScaleTransition(
                  scale: animation,
                  child: FadeTransition(opacity: animation, child: child),
                );
              },
              child: Icon(
                glyph,
                key: ValueKey<bool>(active),
                size: 18,
                color: color,
              ),
            ),
            if (count != null && count! > 0) ...<Widget>[
              const SizedBox(width: AppSpacing.xs),
              Text(
                formatCount(count!),
                // 等宽数字：计数从 9 → 10 时不会把整行挤动。
                style: AppTypography.tabularNumber.copyWith(color: color),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
