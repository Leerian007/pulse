import 'package:flutter/cupertino.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/date_format.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/pressable.dart';
import '../../domain/entities/post.dart';
import 'post_image_grid.dart';

/// 动态卡片。
///
/// 视觉拆解（自上而下）：
///  1. 作者行：头像 + 昵称（含认证标记）+ `@handle · 时间`；
///  2. 正文：17pt / 行高 1.29，这是 Apple 正文的标准观感；
///  3. 配图：真图走 [PostImageGrid]（见那里的九宫格排布说明），
///     没有真图时回落到 emoji 渐变占位；
///  4. 话题胶囊：accentSoft 底 + accent 字，11pt；
///  5. 操作栏：点赞（心跳动画）/ 评论 / 转发 / 分享。
///
/// 交互上做了两件事：**整卡可按下** + **点赞即时变色并跳一下**。
/// 卡片的 `onTap` 预留给了详情页路由。
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
              PostImageGrid(images: post.images, caption: post.coverCaption),
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
///
/// 点赞单独拆成 [_LikeButton]，因为它是唯一一个**带状态动效**的按钮；
/// 其余三个共用通用的 [_ActionButton]。把动效塞进通用按钮会让每个按钮都背上
/// 一个用不到的 AnimationController。
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
            _LikeButton(
              liked: post.likedByMe,
              count: post.likeCount,
              color: palette.like,
              onTap: onLike,
            ),
            _ActionButton(
              icon: CupertinoIcons.chat_bubble,
              count: post.commentCount,
              onTap: onComment,
            ),
            _ActionButton(
              icon: CupertinoIcons.arrow_2_squarepath,
              count: post.repostCount,
              onTap: onRepost,
            ),
            const Spacer(),
            _ActionButton(
              icon: CupertinoIcons.share,
              onTap: onShare,
            ),
          ],
        ),
      ],
    );
  }
}

/// 「图标 + 计数」。
///
/// 抽出来是为了让点赞按钮和普通按钮**共用同一套排版**：点赞多出来的只是
/// 外面那层心跳缩放，排版本身不该有第二份实现 —— 否则两个按钮的
/// 图标尺寸、间距会慢慢漂移。
class _ActionLabel extends StatelessWidget {
  const _ActionLabel({
    required this.color,
    this.icon,
    this.count,
    this.leading,
  }) : assert(
          icon != null || leading != null,
          '_ActionLabel 至少要有一个图标：要么给 icon，要么给 leading。',
        );

  final Color color;

  /// 默认图标。用 [leading] 自定义渲染时可以不传。
  final IconData? icon;

  /// 为 `null` 或 0 时不显示数字（分享按钮就永远不显示）。
  final int? count;

  /// 替换默认图标的自定义内容。点赞用它把 `AnimatedSwitcher` 塞进来。
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        leading ?? Icon(icon, size: 18, color: color),
        if (count != null && count! > 0) ...<Widget>[
          const SizedBox(width: AppSpacing.xs),
          Text(
            formatCount(count!),
            // 等宽数字：计数从 9 → 10 时不会把整行挤动。
            style: AppTypography.tabularNumber.copyWith(color: color),
          ),
        ],
      ],
    );
  }
}

/// 通用操作按钮（评论 / 转发 / 分享）。
///
/// 它**没有**配色参数：这三个按钮都没有"激活"态，永远用三级灰。
/// 留着 `color` 参数只会让人以为可以给按钮上色，而实际上传进来的值
/// 在任何分支里都用不到 —— 那种"参数只是装饰"的接口比没有参数更糟。
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    this.count,
    this.onTap,
  });

  final IconData icon;
  final int? count;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return Pressable(
      onTap: onTap,
      scale: 0.88,
      borderRadius: AppRadius.pillAll,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: _ActionLabel(
          icon: icon,
          count: count,
          color: palette.labelTertiary,
        ),
      ),
    );
  }
}

/// 点赞按钮：**心跳动画**。
///
/// ## 为什么值得为它单独写一个 StatefulWidget
///
/// 点赞是整个 App 里情绪最强的动作，也是唯一一个"做对了会被夸"的细节。
/// 空心 → 实心的图标切换（`AnimatedSwitcher`）只是及格线；真正让人觉得
/// "这 App 好用"的是那一下心跳。
///
/// ## 曲线为什么是四段而不是 `Curves.elasticOut`
///
/// `elasticOut` 是**连续振荡**，观感像橡皮筋；真实的心跳是"咚、咚"两下：
/// 猛地放大 → 回落过头 → 再弹一点 → 归位。所以用 `TweenSequence` 手写。
///
/// ## 只在"没赞 → 赞"时跳
///
/// 取消点赞不播动画 —— 撤销一个动作不该有庆祝感。而且乐观更新失败回滚时
/// 走的也是"已赞 → 没赞"这条路径，如果这里也播，用户会看到心莫名其妙地
/// 跳一下然后变灰。
class _LikeButton extends StatefulWidget {
  const _LikeButton({
    required this.liked,
    required this.count,
    required this.color,
    this.onTap,
  });

  final bool liked;
  final int count;
  final Color color;
  final VoidCallback? onTap;

  @override
  State<_LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends State<_LikeButton>
    with SingleTickerProviderStateMixin {
  /// 心跳总时长。再长一点就"拖沓"了 —— 高频动作的动效必须收得干脆。
  static const Duration _pulseDuration = Duration(milliseconds: 420);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _pulseDuration,
  );

  /// 四段心跳曲线，`weight` 之和为 100。
  late final Animation<double> _pulse = TweenSequence<double>(
    <TweenSequenceItem<double>>[
      // 猛地放大
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 1, end: 1.3)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 20,
      ),
      // 回落并缩过头
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 1.3, end: 0.92)
            .chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 26,
      ),
      // 回弹
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0.92, end: 1.06)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 28,
      ),
      // 归位
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 1.06, end: 1)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 26,
      ),
    ],
  ).animate(_controller);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _LikeButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.liked && widget.liked) {
      _controller.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final Color color = widget.liked ? widget.color : palette.labelTertiary;

    return Pressable(
      onTap: widget.onTap,
      scale: 0.88,
      borderRadius: AppRadius.pillAll,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        // 整个"心 + 计数"一起缩放：心脏带动数字一起跳，比只缩图标更有整体感。
        child: ScaleTransition(
          scale: _pulse,
          child: _ActionLabel(
            count: widget.count,
            color: color,
            leading: AnimatedSwitcher(
              duration: AppDuration.fast,
              switchInCurve: AppCurves.spring,
              transitionBuilder: (Widget child, Animation<double> animation) {
                return ScaleTransition(
                  scale: animation,
                  child: FadeTransition(opacity: animation, child: child),
                );
              },
              child: Icon(
                widget.liked ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
                // key 必须跟着状态变，否则 AnimatedSwitcher 认为"还是同一个
                // widget"，不会播过渡 —— 图标会瞬间替换。
                key: ValueKey<bool>(widget.liked),
                size: 18,
                color: color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
