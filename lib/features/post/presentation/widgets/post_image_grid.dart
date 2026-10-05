import 'package:flutter/cupertino.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_network_image.dart';

/// 配图张数 → 列数。
///
/// 这个映射不是"能塞几列就塞几列"，而是社区产品多年试出来的固定档位：
///
/// | 张数   | 排布                | 为什么 |
/// |-------|---------------------|--------|
/// | 1     | 单张大图（16:10）    | 单图是内容的主角，给足面积 |
/// | 2     | 2 列                | 并排比方块＋空位好看 |
/// | 3     | 3 列一行            | 微博 / 微信的经典形态，比 2+1 整齐 |
/// | 4     | 2×2                 | 3 列会留一个尴尬的空位 |
/// | 5~9   | 3 列，多的换行       | 九宫格的标准形态 |
///
/// 抽成顶层函数（而不是塞在 widget 里）是为了能被单独测试 —— 档位比像素
/// 更容易写错，而且错了之后画面"看着有点怪"却不会报错。
int imageGridColumns(int count) {
  if (count <= 1) {
    return 1;
  }
  if (count == 2) {
    return 2;
  }
  if (count == 3) {
    return 3;
  }
  if (count == 4) {
    return 2;
  }
  return 3;
}

/// 动态配图。
///
/// 两条既定的设计取舍：
///
/// **一、外轮廓圆角，内格直角。** 整块图用 `ClipRRect` 裁一次圆角，而不是每格
/// 各裁一次。这样外轮廓的圆角与"单张大图"完全一致，整块看起来是**一张组图**
/// 而不是一堆小卡片；内格之间的缝隙露出卡片底色，自然形成分隔。
///
/// **二、用 `Row` + `Expanded` 而不是 `Wrap` 或 `GridView`。**
///  - `GridView` 在信息流里必须 `shrinkWrap` + 禁滚动，每次滚动都要重算整张
///    网格的高度，代价远高于手算；
///  - `Wrap` 需要自己算格子边长，而 `(W - gap*(n-1)) / n` 的浮点误差会让
///    **最后一格换行** —— 这是最经典、也最难查的九宫格 bug。
///    `Expanded` 由布局系统精确分配剩余宽度，不存在这个风险。
class PostImageGrid extends StatelessWidget {
  const PostImageGrid({super.key, required this.images, this.caption});

  /// 配图地址，顺序即展示顺序。
  final List<String> images;

  /// 配图说明，展示在图下方。
  final String? caption;

  /// 九宫格上限。
  static const int maxImages = 9;

  /// 图片蒙层色。刻意**不**走 `palette`：这是一层盖在照片上的遮罩，
  /// 语义与主题无关（Apple 自家的照片叠层也是恒定黑），
  /// 跟着亮暗模式变幻会让深色主题下的白底照片失去可读性。
  static const Color _scrim = Color(0x8C000000);

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return const SizedBox.shrink();
    }

    final AppPalette palette = context.palette;
    final int total = images.length;
    final int visible = total > maxImages ? maxImages : total;
    // 超出 9 张的部分不静默丢弃：用户需要知道"还有更多"，
    // 否则会误以为这条动态只有九张图。
    final int hidden = total - visible;

    final Widget grid = visible == 1
        ? AspectRatio(
            aspectRatio: 16 / 10,
            child: _Tile(url: images.first, hiddenCount: 0),
          )
        : _buildRows(visible: visible, hidden: hidden);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ClipRRect(borderRadius: AppRadius.mdAll, child: grid),
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

  /// 按行铺开。末行不足时用空位补齐，保证各行的格子**等宽**。
  Widget _buildRows({required int visible, required int hidden}) {
    final int columns = imageGridColumns(visible);
    final int rows = (visible + columns - 1) ~/ columns;

    return Column(
      children: <Widget>[
        for (int row = 0; row < rows; row++)
          Padding(
            // 行间距靠"给第二行起加 padding"实现，而不是 `runSpacing`：
            // 这样不会在整块图底部多留一条缝。
            padding: EdgeInsets.only(top: row == 0 ? 0 : AppSpacing.xs),
            child: Row(
              children: <Widget>[
                for (int column = 0; column < columns; column++) ...<Widget>[
                  if (column > 0) const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: _cell(
                      index: row * columns + column,
                      visible: visible,
                      hidden: hidden,
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  /// 一格。下标越界时返回占位空盒 —— 它宽度照占，高度为 0，
  /// 于是末行只有 1 张图时，那一张的宽度仍与前几行一致（不会被拉宽）。
  Widget _cell({
    required int index,
    required int visible,
    required int hidden,
  }) {
    if (index >= visible) {
      return const SizedBox.shrink();
    }

    return AspectRatio(
      aspectRatio: 1,
      child: _Tile(
        url: images[index],
        // 只有最后一格盖蒙层，否则每格都写 +N 就重复了。
        hiddenCount: index == visible - 1 ? hidden : 0,
      ),
    );
  }
}

/// 单格图。[hiddenCount] > 0 时叠 `+N` 蒙层。
class _Tile extends StatelessWidget {
  const _Tile({required this.url, required this.hiddenCount});

  final String url;
  final int hiddenCount;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    final Widget image = AppNetworkImage(
      url: url,
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
          color: PostImageGrid._scrim,
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
