import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learning_flutter/core/riverpod/async_value_ext.dart';
import 'package:learning_flutter/core/theme/app_theme.dart';
import 'package:learning_flutter/core/widgets/pressable.dart';
import 'package:learning_flutter/features/post/data/repositories/mock_post_repository.dart';
import 'package:learning_flutter/features/post/domain/entities/post.dart';
import 'package:learning_flutter/features/post/domain/repositories/photo_library.dart';
import 'package:learning_flutter/features/post/presentation/providers/composer_providers.dart';
import 'package:learning_flutter/features/post/presentation/providers/feed_providers.dart';
import 'package:learning_flutter/features/post/presentation/widgets/post_composer_sheet.dart';

/// 发帖面板的测试。
///
/// 面板是这一轮改动里交互最密的地方（输入 / 选图 / 选话题 / 提交四件事），
/// 而且**每一条规则都有明确的视觉契约**：无内容置灰、有内容高亮、话题选中要有
/// 对勾……这些规则靠人眼看截图是守不住的（改一行颜色没人会发现），必须写成断言。
void main() {
  late _FakePhotoLibrary photoLibrary;

  setUp(() => photoLibrary = _FakePhotoLibrary());

  /// 极小的宿主：上面显示流里第一条动态的正文，下面一个按钮打开面板。
  ///
  /// 用真 provider 而不是假数据，于是"发布 → 面板关闭 → 流里出现新动态"
  /// 这条端到端的链路能被一次性验证。
  Widget host() {
    return ProviderScope(
      // 注意：这里**不能**写 `<Override>[...]`。
      // `flutter_riverpod` 的 `show` 白名单里没有导出 `Override` 这个类型名，
      // 省略类型参数让 Dart 从参数类型反推即可。
      overrides: [
        // 延迟归零：测试不该为 Mock 的 500ms 白等。
        postRepositoryProvider.overrideWithValue(
          MockPostRepository(latency: Duration.zero),
        ),
        photoLibraryProvider.overrideWithValue(photoLibrary),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Consumer(
            builder: (BuildContext context, WidgetRef ref, Widget? child) {
              final List<Post> posts =
                  ref.watch(feedProvider).dataOrNull ?? const <Post>[];
              final Post? first = posts.isEmpty ? null : posts.first;

              return Column(
                children: <Widget>[
                  Text('首条:${first?.content ?? "加载中"}'),
                  // 把配图张数与话题也渲染出来，这样"发布时带了图/话题"
                  // 才有地方可断言 —— 只看正文是验证不到的。
                  Text(
                    first == null
                        ? '元信息:-'
                        : '元信息:图${first.images.length} '
                            '话题${first.topics.join("/")}',
                  ),
                  TextButton(
                    onPressed: () => showPostComposer(context),
                    child: const Text('写一条'),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// 打开面板并等它弹完。
  ///
  /// 这里做了一件容易被忽略但很关键的事：**把测试视口换成一台正常手机**。
  /// `flutter_test` 默认只有 800×600，而真实手机约 390×844 ——
  /// 600 逻辑像素高会把面板压得很扁，话题区直接掉到屏幕外，
  /// 于是 `tap` 会静默地打不中（只打印一条 warning），
  /// 失败信息却是"某个断言不成立"，极难反查到真正的原因。
  Future<void> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(host());
    await tester.tap(find.text('写一条'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  /// 推进若干帧。
  ///
  /// 两个坑都在这里避开了：
  ///  1. **不能用 `pumpAndSettle()`** —— 提交中会显示一个 `repeat()` 的
  ///     转圈指示器，永远 settle 不了，直接超时；
  ///  2. **不能用一次 `pump(600ms)` 顶上** —— 一次 pump 只产生**一帧**，
  ///     而"面板收起"这类动画是在这期间才刚开始的，那一帧的进度还是 0。
  ///     必须拆成多帧推进，动画才有机会真正走完。
  Future<void> pumpFrames(
    WidgetTester tester, {
    int frames = 12,
    Duration step = const Duration(milliseconds: 50),
  }) async {
    for (int i = 0; i < frames; i++) {
      await tester.pump(step);
    }
  }

  Finder publishText() => find.text('发布');

  /// 发布按钮当前**配置**的颜色（`AnimatedContainer` 的 widget 上存的就是目标值，
  /// 所以不需要等颜色动画跑完）。
  Color publishColor(WidgetTester tester) {
    final AnimatedContainer container = tester.widget<AnimatedContainer>(
      find
          .ancestor(of: publishText(), matching: find.byType(AnimatedContainer))
          .first,
    );
    return (container.decoration! as BoxDecoration).color!;
  }

  /// 发布按钮的点击能力。
  VoidCallback? publishOnTap(WidgetTester tester) {
    return tester
        .widget<Pressable>(
          find.ancestor(of: publishText(), matching: find.byType(Pressable)).first,
        )
        .onTap;
  }

  group('发布按钮的禁用 / 高亮', () {
    testWidgets('没有内容时置灰且不可点', (WidgetTester tester) async {
      await open(tester);

      expect(publishOnTap(tester), isNull, reason: '没写字就不该能发');
      expect(publishColor(tester), AppPalette.light.fill);
    });

    testWidgets('输入内容后变成高亮且可点', (WidgetTester tester) async {
      await open(tester);

      await tester.enterText(find.byType(CupertinoTextField), '把书桌清空了');
      await tester.pump();

      expect(publishOnTap(tester), isNotNull);
      expect(publishColor(tester), AppPalette.light.accent);
    });

    testWidgets('只有空白字符时仍然禁用', (WidgetTester tester) async {
      await open(tester);

      await tester.enterText(find.byType(CupertinoTextField), '   \n  ');
      await tester.pump();

      expect(publishOnTap(tester), isNull);
      expect(publishColor(tester), AppPalette.light.fill);
    });
  });

  group('底部工具栏', () {
    testWidgets('输入框自动聚焦，且是无边框的', (WidgetTester tester) async {
      await open(tester);

      final CupertinoTextField field =
          tester.widget<CupertinoTextField>(find.byType(CupertinoTextField));
      expect(field.autofocus, isTrue);
      // 无边框 = 没有 decoration（于是没有底色、没有描边）。
      expect(field.decoration, isNull);
      expect(field.maxLines, isNull, reason: '多行输入');
    });

    testWidgets('字数计数器跟着输入走', (WidgetTester tester) async {
      await open(tester);
      expect(find.text('0 / 500'), findsOneWidget);

      // 刻意用四个汉字：验证的是"按 runes 数"，四个字就是 4。
      await tester.enterText(find.byType(CupertinoTextField), '一二三四');
      await tester.pump();

      expect(find.text('4 / 500'), findsOneWidget);
    });

    testWidgets('点「图片」加入配图，张数写进按钮标签，可以逐张删掉', (WidgetTester tester) async {
      await open(tester);
      expect(find.text('图片'), findsOneWidget);

      await tester.tap(find.text('图片'));
      await tester.pump();
      await tester.pump();

      // 假相册一次给 3 张，上限应该是"还能放几张"。
      expect(find.text('图片 3/9'), findsOneWidget);
      expect(photoLibrary.lastMaxCount, 9);
      expect(find.byIcon(CupertinoIcons.xmark), findsNWidgets(3));

      await tester.tap(find.byIcon(CupertinoIcons.xmark).first);
      await tester.pump();

      expect(find.text('图片 2/9'), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.xmark), findsNWidgets(2));
    });

    testWidgets('配图到 9 张后「图片」按钮变灰不可点', (WidgetTester tester) async {
      photoLibrary = _FakePhotoLibrary(count: 9);
      await open(tester);

      await tester.tap(find.text('图片'));
      await tester.pump();
      await tester.pump();

      expect(find.text('图片 9/9'), findsOneWidget);
      expect(
        tester
            .widget<Pressable>(
              find
                  .ancestor(
                    of: find.text('图片 9/9'),
                    matching: find.byType(Pressable),
                  )
                  .first,
            )
            .onTap,
        isNull,
      );
    });

    testWidgets('点「标签」展开推荐话题，选中后带对勾并计数', (WidgetTester tester) async {
      await open(tester);

      // 默认收起，不占正文的地方。
      expect(find.text('#效率'), findsNothing);

      await tester.tap(find.text('标签'));
      await tester.pump();

      // 推荐话题来自种子动态（p_001 的话题是「效率」「桌面」）。
      expect(find.text('#效率'), findsOneWidget);

      await tester.tap(find.text('#效率'));
      await tester.pump();

      expect(find.byIcon(CupertinoIcons.checkmark), findsOneWidget);
      expect(find.text('标签 1'), findsOneWidget);

      // 收起后已选话题仍然可见 —— 否则用户不知道自己要发什么标签。
      await tester.tap(find.text('标签 1'));
      await tester.pump();
      expect(find.text('#效率'), findsOneWidget);
      expect(find.text('#植物'), findsNothing, reason: '收起后不该再显示未选的推荐');
    });

    testWidgets('再点一次已选话题可以取消', (WidgetTester tester) async {
      await open(tester);

      await tester.tap(find.text('标签'));
      await tester.pump();
      await tester.tap(find.text('#效率'));
      await tester.pump();
      expect(find.text('标签 1'), findsOneWidget);

      await tester.tap(find.text('#效率'));
      await tester.pump();

      expect(find.text('标签'), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.checkmark), findsNothing);
    });
  });

  group('发布', () {
    testWidgets('发布成功后面板关闭，新动态出现在流的最前面', (WidgetTester tester) async {
      await open(tester);

      await tester.enterText(find.byType(CupertinoTextField), '一条新动态');
      await tester.pump();

      await tester.tap(publishText());
      await tester.pump(); // 让这一次点击生效
      await pumpFrames(tester); // 零延迟的仓库完成 + 面板收起动画

      // 面板走了。
      expect(find.byType(CupertinoTextField), findsNothing);
      // 流里的第一条就是刚发的，而且是**内容逐字一致**。
      expect(find.text('首条:一条新动态'), findsOneWidget);
    });

    testWidgets('发布时把选中的配图与话题一起带上', (WidgetTester tester) async {
      await open(tester);

      // 发之前先确认流里第一条是种子数据（2 张图、效率/桌面）。
      expect(find.text('元信息:图2 话题效率/桌面'), findsOneWidget);

      await tester.enterText(find.byType(CupertinoTextField), '带图带话题');
      await tester.pump();
      await tester.tap(find.text('图片'));
      await tester.pump();
      await tester.pump();
      await tester.tap(find.text('标签'));
      await tester.pump();
      await tester.tap(find.text('#效率'));
      await tester.pump();

      await tester.tap(publishText());
      await tester.pump();
      await pumpFrames(tester);

      // 新动态排在队首，且配图与话题都跟着来了 —— 不是"发出去才发现图丢了"。
      expect(find.text('首条:带图带话题'), findsOneWidget);
      expect(find.text('元信息:图3 话题效率'), findsOneWidget);
    });
  });
}

/// 假的相册：立刻返回一批固定地址，并记录调用参数。
///
/// 用假实现而不是真的 `MockPhotoLibrary`：后者每次生成的 seed 都带时间戳
/// （那是它的设计目标），断言就没法写死了。
class _FakePhotoLibrary implements PhotoLibrary {
  _FakePhotoLibrary({this.count = 3});

  /// 一次"挑"几张。
  final int count;

  /// 最近一次调用传入的上限，用来验证"还差几张"算对了。
  int? lastMaxCount;

  @override
  Future<List<String>> pickImages({required int maxCount}) async {
    lastMaxCount = maxCount;
    final int take = maxCount < count ? maxCount : count;
    return <String>[
      for (int i = 0; i < take; i++)
        'https://picsum.photos/seed/fake-$i/900/900',
    ];
  }
}
