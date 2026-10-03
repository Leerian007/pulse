import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/riverpod/async_value_ext.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_status_view.dart';
import '../../../../core/widgets/pressable.dart';
import '../../domain/entities/post.dart';
import '../providers/feed_providers.dart';
import '../widgets/post_card.dart';
import '../widgets/post_card_skeleton.dart';
import '../widgets/post_composer_sheet.dart';

/// 动态流（Tab 1）。
///
/// 结构选择：[CustomScrollView] + `CupertinoSliverNavigationBar`，
/// 而不是 `Scaffold(appBar: ...)` + `ListView`。原因是大标题的
/// **"滚动时收起 + 收起后毛玻璃渐显"** 是 iOS 信息流的标志性行为，
/// 用 Cupertino 的 sliver 组件是唯一能免费拿到这个效果的方式 ——
/// 手写要维护两条 AnimationController，性价比极低。
class FeedPage extends ConsumerWidget {
  const FeedPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Post>> feed = ref.watch(feedProvider);
    final FeedNotifier notifier = ref.read(feedProvider.notifier);
    final AppPalette palette = context.palette;

    // 统一取成非空列表，后续分支就不用再做空安全判断。
    final List<Post> posts = feed.dataOrNull ?? const <Post>[];

    return ColoredBox(
      color: palette.canvas,
      child: CustomScrollView(
        slivers: <Widget>[
          CupertinoSliverNavigationBar(
            largeTitle: const Text('动态'),
            // 半透明背景 → Cupertino 组件会自动加高斯模糊，
            // 内容滚到标题下面时会透出来（这是 HIG 的核心观感之一）。
            backgroundColor: palette.glass,
            trailing: Pressable(
              onTap: () {
                AppHaptics.light();
                showPostComposer(context);
              },
              scale: 0.88,
              borderRadius: AppRadius.pillAll,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xs),
                child: Icon(
                  CupertinoIcons.pencil,
                  size: 22,
                  color: palette.accent,
                ),
              ),
            ),
          ),

          // iOS 的原生下拉刷新（松手即触发 + 橡皮筋回弹）。
          // 不传 builder，直接用系统默认指示器 —— 它已经是最正宗的观感，
          // 而且它的颜色会自动跟随 CupertinoTheme 的 primaryColor。
          CupertinoSliverRefreshControl(
            onRefresh: notifier.refresh,
          ),

          ..._buildBodySlivers(
            context: context,
            ref: ref,
            notifier: notifier,
            feed: feed,
            posts: posts,
          ),
        ],
      ),
    );
  }

  /// 按状态分派正文：骨架屏 / 错误 / 空 / 列表。
  ///
  /// 注意"首次加载"与"刷新中"的区别（见 `isInitialLoading` 的实现）：
  /// 后者旧数据还在，绝不能再显示骨架屏，否则每次下拉都闪一下。
  List<Widget> _buildBodySlivers({
    required BuildContext context,
    required WidgetRef ref,
    required FeedNotifier notifier,
    required AsyncValue<List<Post>> feed,
    required List<Post> posts,
  }) {
    if (feed.isInitialLoading) {
      return <Widget>[_skeletonSliver()];
    }

    if (feed.isInitialError) {
      return <Widget>[
        SliverFillRemaining(
          hasScrollBody: false,
          child: AppStatusView(
            icon: CupertinoIcons.exclamationmark_circle,
            title: '没能加载动态',
            message: '网络似乎不太稳定，稍后可以再试一次。',
            actionLabel: '重试',
            // invalidate 会丢弃当前状态并重新执行 build()，
            // 于是又会走一遍 loading → data 的完整流程。
            onAction: () => ref.invalidate(feedProvider),
          ),
        ),
      ];
    }

    if (posts.isEmpty) {
      return <Widget>[
        SliverFillRemaining(
          hasScrollBody: false,
          child: AppStatusView(
            icon: CupertinoIcons.tray,
            title: '还没有动态',
            message: '成为第一个在这里留下痕迹的人。',
            actionLabel: '写一条',
            onAction: () => showPostComposer(context),
          ),
        ),
      ];
    }

    return <Widget>[
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenH,
          AppSpacing.md,
          AppSpacing.screenH,
          AppSpacing.xxl,
        ),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (BuildContext context, int index) {
              final Post post = posts[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.listGap),
                child: PostCard(
                  post: post,
                  // 详情页尚未实现，先留空：Pressable 在 onTap 为 null 时
                  // 自动退化为"不可点击"，不会出现点了没反应的假按钮。
                  onTap: null,
                  onLike: () => notifier.toggleLike(post.id),
                  onComment: () => AppHaptics.light(),
                  onRepost: () => AppHaptics.light(),
                  onShare: () => AppHaptics.light(),
                ),
              );
            },
            childCount: posts.length,
          ),
        ),
      ),
    ];
  }

  /// 骨架屏：4 张卡片，其中第 2、4 张带配图占位，和真实数据的图文混排一致。
  Widget _skeletonSliver() {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenH,
        AppSpacing.md,
        AppSpacing.screenH,
        AppSpacing.xxl,
      ),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (BuildContext context, int index) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.listGap),
            child: PostCardSkeleton(
              withCover: index.isOdd,
              // 每张错开 0.22 个相位，高光带不会整齐划一地一起走。
              phase: (index * 0.22) % 1,
            ),
          ),
          childCount: 4,
        ),
      ),
    );
  }
}
