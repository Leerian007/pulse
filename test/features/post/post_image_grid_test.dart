import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learning_flutter/core/theme/app_theme.dart';
import 'package:learning_flutter/features/post/presentation/widgets/post_image_grid.dart';

/// 九宫格的排布测试。
///
/// 为什么这类布局值得专门写测试：它的错误症状是**"看着有点怪"**而不是崩溃。
/// 列数映射错一档、末行把格子拉宽、浮点误差让最后一格换行 —— 这三种都不会
/// 报错，但会让截图立刻显得廉价，而且极难在 code review 里看出来。
void main() {
  List<String> urls(int count) => <String>[
        for (int i = 0; i < count; i++) 'https://picsum.photos/seed/g$i/900/900',
      ];

  Widget host({
    required List<String> images,
    String? caption,
    double width = 300,
  }) {
    return MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: width,
            child: PostImageGrid(images: images, caption: caption),
          ),
        ),
      ),
    );
  }

  group('imageGridColumns', () {
    test('张数 → 列数的档位是固定契约', () {
      // 这些数字一旦漂移，整条信息流的配图观感就变了，
      // 所以把它们写死在这里当契约。
      expect(imageGridColumns(0), 1);
      expect(imageGridColumns(1), 1);
      expect(imageGridColumns(2), 2);
      expect(imageGridColumns(3), 3);
      expect(imageGridColumns(4), 2, reason: '4 张用 3 列会留一个尴尬的空位');
      expect(imageGridColumns(5), 3);
      expect(imageGridColumns(6), 3);
      expect(imageGridColumns(7), 3);
      expect(imageGridColumns(8), 3);
      expect(imageGridColumns(9), 3);
    });
  });

  group('渲染', () {
    testWidgets('没有图片时是空盒子，不占任何高度', (WidgetTester tester) async {
      await tester.pumpWidget(host(images: const <String>[]));
      expect(find.byType(AspectRatio), findsNothing);
    });

    testWidgets('单图是 16:10 通栏大图，不是方块', (WidgetTester tester) async {
      await tester.pumpWidget(host(images: urls(1)));
      final Finder tile = find.byType(AspectRatio);

      expect(tile, findsOneWidget);
      final Size size = tester.getSize(tile);
      expect(size.width, 300);
      expect(size.height, moreOrLessEquals(300 * 10 / 16, epsilon: 0.5));
    });

    testWidgets('2 张并排成两个正方形', (WidgetTester tester) async {
      await tester.pumpWidget(host(images: urls(2)));
      final Finder tiles = find.byType(AspectRatio);

      expect(tiles, findsNWidgets(2));
      final double expected = (300 - AppSpacing.xs) / 2;
      for (int i = 0; i < 2; i++) {
        final Size size = tester.getSize(tiles.at(i));
        expect(size.width, moreOrLessEquals(expected, epsilon: 0.5));
        expect(size.width, moreOrLessEquals(size.height, epsilon: 0.01));
      }
      // 两个格子在同一行 → 顶边对齐。
      expect(
        tester.getTopLeft(tiles.at(0)).dy,
        moreOrLessEquals(tester.getTopLeft(tiles.at(1)).dy, epsilon: 0.01),
      );
    });

    testWidgets('5 张走 3 列换行，末行两张与前一行等宽', (WidgetTester tester) async {
      await tester.pumpWidget(host(images: urls(5)));
      final Finder tiles = find.byType(AspectRatio);

      expect(tiles, findsNWidgets(5));
      final double expected = (300 - AppSpacing.xs * 2) / 3;
      for (int i = 0; i < 5; i++) {
        final Size size = tester.getSize(tiles.at(i));
        expect(size.width, moreOrLessEquals(expected, epsilon: 0.5),
            reason: '第 $i 格宽度不对');
        expect(size.width, moreOrLessEquals(size.height, epsilon: 0.01),
            reason: '第 $i 格不是正方形');
      }

      // 第 4、5 张（下标 3、4）必须落在第二行，而且不能被拉宽。
      final double firstRowTop = tester.getTopLeft(tiles.at(0)).dy;
      final double secondRowTop = tester.getTopLeft(tiles.at(3)).dy;
      expect(secondRowTop, greaterThan(firstRowTop));
      expect(
        tester.getTopLeft(tiles.at(3)).dy,
        moreOrLessEquals(tester.getTopLeft(tiles.at(4)).dy, epsilon: 0.01),
      );
    });

    testWidgets('4 张排成 2×2，而不是 3+1', (WidgetTester tester) async {
      await tester.pumpWidget(host(images: urls(4)));
      final Finder tiles = find.byType(AspectRatio);

      expect(tiles, findsNWidgets(4));
      final double row1 = tester.getTopLeft(tiles.at(0)).dy;
      final double row2 = tester.getTopLeft(tiles.at(2)).dy;
      expect(row2, greaterThan(row1));
      // 第 3 张和第 1 张左对齐（同一列），说明只有 2 列。
      expect(
        tester.getTopLeft(tiles.at(2)).dx,
        moreOrLessEquals(tester.getTopLeft(tiles.at(0)).dx, epsilon: 0.01),
      );
    });

    testWidgets('超过 9 张只渲染 9 格，并在最后一格叠 +N', (WidgetTester tester) async {
      await tester.pumpWidget(host(images: urls(12)));

      expect(find.byType(AspectRatio), findsNWidgets(9));
      // 12 - 9 = 3，不能静默丢弃 —— 用户得知道"还有更多"。
      expect(find.text('+3'), findsOneWidget);
    });

    testWidgets('正好 9 张时不出现 +N 蒙层', (WidgetTester tester) async {
      await tester.pumpWidget(host(images: urls(9)));

      expect(find.byType(AspectRatio), findsNWidgets(9));
      expect(find.textContaining('+'), findsNothing);
    });

    testWidgets('很窄的宽度下不溢出', (WidgetTester tester) async {
      // 溢出在 widget 测试里会升级成失败，所以这条用例本身就是断言：
      // 它保证 `(W - gap*(n-1)) / n` 那套浮点误差没有把布局挤爆。
      await tester.pumpWidget(host(images: urls(5), width: 160));
      expect(find.byType(AspectRatio), findsNWidgets(5));
    });

    testWidgets('配图说明渲染在图下方', (WidgetTester tester) async {
      await tester.pumpWidget(
        host(images: urls(1), caption: '清空后的桌面'),
      );

      final Finder caption = find.text('清空后的桌面');
      expect(caption, findsOneWidget);
      expect(
        tester.getTopLeft(caption).dy,
        greaterThan(tester.getBottomLeft(find.byType(AspectRatio)).dy),
      );
    });
  });
}
