import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learning_flutter/core/theme/app_theme.dart';
import 'package:learning_flutter/features/post/domain/entities/author.dart';
import 'package:learning_flutter/features/post/domain/entities/post.dart';
import 'package:learning_flutter/features/post/presentation/widgets/post_card.dart';
import 'package:learning_flutter/features/post/presentation/widgets/post_image_grid.dart';

/// `PostCard` 的交互测试。
///
/// 重点守两件事：
///  1. **点赞的即时反馈** —— 计数必须"点完立刻变"，这是乐观更新在 UI 上的表现；
///  2. **配图的两条分支都还在** —— 有真图走九宫格，没真图走 emoji 占位。
///     分支被删掉时不会报错，只会让某条路悄悄烂掉。
void main() {
  const Author author = Author(id: 'u_test', name: '测试用户', handle: 'tester');

  Post buildPost({
    bool liked = false,
    int likeCount = 12,
    int commentCount = 3,
    int repostCount = 1,
    List<String> images = const <String>[],
    String? coverEmoji,
  }) {
    return Post(
      id: 'p_test',
      author: author,
      content: '一条测试动态',
      createdAt: DateTime(2026, 10, 4, 12),
      images: images,
      coverEmoji: coverEmoji,
      likeCount: likeCount,
      likedByMe: liked,
      commentCount: commentCount,
      repostCount: repostCount,
    );
  }

  Widget host(Widget child) {
    return MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        // 卡片在信息流里本来就是可以撑得比屏幕高的，套一层滚动容器
        // 免得测试里的溢出报错干扰断言。
        body: SingleChildScrollView(child: child),
      ),
    );
  }

  testWidgets('未点赞时是空心，已点赞时是实心', (WidgetTester tester) async {
    await tester.pumpWidget(host(PostCard(post: buildPost())));
    expect(find.byIcon(CupertinoIcons.heart), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.heart_fill), findsNothing);

    await tester.pumpWidget(host(PostCard(post: buildPost(liked: true))));
    // 等图标切换的过渡（AnimatedSwitcher 期间新旧两个图标会同时在树上）。
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byIcon(CupertinoIcons.heart_fill), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.heart), findsNothing);
  });

  testWidgets('点赞后计数立刻 +1（乐观更新的 UI 表现）', (WidgetTester tester) async {
    final Post post = buildPost(likeCount: 12);
    await tester.pumpWidget(host(_LikeHost(post: post)));

    expect(find.text('12'), findsOneWidget);

    await tester.tap(find.byIcon(CupertinoIcons.heart));
    // 只推进一帧：这里要证明的正是"不用等网络，数字已经变了"。
    await tester.pump();
    expect(find.text('13'), findsOneWidget);

    // 再等动效跑完，心形应该已经变成实心。
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byIcon(CupertinoIcons.heart_fill), findsOneWidget);
  });

  testWidgets('再点一次可以取消点赞，计数退回', (WidgetTester tester) async {
    await tester.pumpWidget(host(_LikeHost(post: buildPost(liked: true, likeCount: 13))));
    expect(find.text('13'), findsOneWidget);

    await tester.tap(find.byIcon(CupertinoIcons.heart_fill));
    await tester.pump();
    expect(find.text('12'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byIcon(CupertinoIcons.heart), findsOneWidget);
  });

  /// 树上所有 `ScaleTransition` 里最大的缩放值。
  ///
  /// 不要直接取 `.first`：`Pressable` 的按下反馈也是一层 `AnimatedScale`
  /// （内部同样是 `ScaleTransition`），它缩到 0.88，取第一个会拿到它，
  /// 于是心跳永远"看起来没发生"。
  double biggestScale(WidgetTester tester) => tester
      .widgetList<ScaleTransition>(find.byType(ScaleTransition))
      .map((ScaleTransition transition) => transition.scale.value)
      .fold<double>(0, (double a, double b) => a > b ? a : b);

  testWidgets('点赞会播一次心跳：先放大到峰值，再归位', (WidgetTester tester) async {
    await tester.pumpWidget(host(_LikeHost(post: buildPost())));

    await tester.tap(find.byIcon(CupertinoIcons.heart));
    await tester.pump();
    // 推进到第一段"猛地放大"的中段（总 420ms，第一段占 20%）。
    await tester.pump(const Duration(milliseconds: 60));

    expect(biggestScale(tester), greaterThan(1.0), reason: '心跳的峰值必须超过 1');

    await tester.pump(const Duration(milliseconds: 600));
    expect(
      biggestScale(tester),
      moreOrLessEquals(1.0, epsilon: 0.0001),
      reason: '跳完必须归位，否则会永远停在放大状态',
    );
  });

  testWidgets('取消点赞不播心跳（撤销一个动作不该有庆祝感）', (WidgetTester tester) async {
    await tester.pumpWidget(
      host(_LikeHost(post: buildPost(liked: true, likeCount: 13))),
    );

    await tester.tap(find.byIcon(CupertinoIcons.heart_fill));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));

    expect(
      biggestScale(tester),
      lessThanOrEqualTo(1.0),
      reason: '取消点赞时不应该放大',
    );
  });

  testWidgets('操作栏的评论 / 转发 / 分享各自回调', (WidgetTester tester) async {
    int comments = 0;
    int reposts = 0;
    int shares = 0;

    await tester.pumpWidget(host(PostCard(
      post: buildPost(),
      onComment: () => comments++,
      onRepost: () => reposts++,
      onShare: () => shares++,
    )));

    await tester.tap(find.byIcon(CupertinoIcons.chat_bubble));
    await tester.pump();
    await tester.tap(find.byIcon(CupertinoIcons.arrow_2_squarepath));
    await tester.pump();
    await tester.tap(find.byIcon(CupertinoIcons.share));
    await tester.pump();

    expect(comments, 1);
    expect(reposts, 1);
    expect(shares, 1);
  });

  testWidgets('有真图时走九宫格', (WidgetTester tester) async {
    await tester.pumpWidget(host(PostCard(
      post: buildPost(images: <String>[
        'https://picsum.photos/seed/a/900/900',
        'https://picsum.photos/seed/b/900/900',
      ]),
    )));

    expect(find.byType(PostImageGrid), findsOneWidget);
    // 2 张 → 2 个方格子。
    expect(find.byType(AspectRatio), findsNWidgets(2));
  });

  testWidgets('没有真图时回落到 emoji 占位', (WidgetTester tester) async {
    // 这条分支的"守门人"是种子数据（见 mock_seed_data_test），
    // 这里再从卡片这一层确认它确实被渲染出来。
    await tester.pumpWidget(host(PostCard(post: buildPost(coverEmoji: '🌆'))));

    expect(find.byType(PostImageGrid), findsNothing);
    expect(find.text('🌆'), findsOneWidget);
  });

  testWidgets('计数为 0 时不显示数字', (WidgetTester tester) async {
    await tester.pumpWidget(host(PostCard(
      post: buildPost(likeCount: 0, commentCount: 0, repostCount: 0),
    )));

    expect(find.text('0'), findsNothing);
  });
}

/// 最小宿主：点一下翻转点赞状态。
///
/// 用它而不是反复 `pumpWidget` 一个新卡片，是因为这样才能验证
/// `didUpdateWidget` 那条路径 —— 心跳动画正是挂在那里的。
class _LikeHost extends StatefulWidget {
  const _LikeHost({required this.post});

  final Post post;

  @override
  State<_LikeHost> createState() => _LikeHostState();
}

class _LikeHostState extends State<_LikeHost> {
  late Post _post = widget.post;

  @override
  Widget build(BuildContext context) {
    return PostCard(
      post: _post,
      onLike: () => setState(() => _post = _post.toggleLike()),
    );
  }
}
