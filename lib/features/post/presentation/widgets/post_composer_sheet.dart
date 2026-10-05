import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/hairline_divider.dart';
import '../../../../core/widgets/pressable.dart';
import '../../domain/entities/author.dart';
import '../../domain/entities/post.dart';
import '../providers/composer_providers.dart';
import '../providers/feed_providers.dart';
import 'post_image_grid.dart';

/// 打开"新动态"面板。
///
/// ## 为什么是 sheet，而不是整页路由
///
/// 发动态是**从信息流里长出来的动作**，不是一次页面跳转。用模态 sheet：
///  - 上下文不丢失（背后的动态流还在原位，发完立刻能看到自己那条）；
///  - 自带"手指往下拖就是算了不发了"——这是 iOS 用户的本能，不需要教。
///
/// ## 下滑收起是怎么来的
///
/// 两件事各司其职，缺一个用户就发现不了这个手势：
///  - `enableDrag`（默认 true）负责**手势**；
///  - 主题里的 `bottomSheetTheme.showDragHandle: true` 负责把"可以拖"
///    这件事**画出来**（顶部那根小横条）。
///
/// `isScrollControlled: true` 是必须的：没有它，sheet 最高只能到屏幕的一半，
/// 键盘一弹起来输入区就没地方了。
Future<void> showPostComposer(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    enableDrag: true,
    isDismissible: true,
    // 遮罩压暗一点，让面板更"浮"。太淡会看不清焦点在哪。
    barrierColor: Colors.black.withValues(alpha: 0.32),
    builder: (BuildContext sheetContext) => const _PostComposerSheet(),
  );
}

/// 新动态面板。
///
/// ## 状态放在哪里：本地 `setState`，而不是 Riverpod
///
/// 草稿（正文 / 已选图 / 已选话题）是**这一块 UI 的临时状态**：
/// 面板一关就该消失，没有第二个页面需要看它。把它放进 Notifier 反而要额外
/// 处理"什么时候销毁"（否则下次打开会带出上次的草稿）。
///
/// 但**动作**仍然走 provider：发布走 `feedProvider.notifier`，选图走
/// `photoLibraryProvider`。判断标准很简单 —— "有没有别人要用 / 是不是副作用"。
class _PostComposerSheet extends ConsumerStatefulWidget {
  const _PostComposerSheet();

  @override
  ConsumerState<_PostComposerSheet> createState() => _PostComposerSheetState();
}

class _PostComposerSheetState extends ConsumerState<_PostComposerSheet> {
  final TextEditingController _controller = TextEditingController();

  /// 已选配图，顺序即九宫格顺序。
  final List<String> _images = <String>[];

  /// 已选话题。用 `List` 而不是 `Set`：发布时要保持用户点选的顺序，
  /// 而且 `List.contains` 在这个规模下完全够用。
  final List<String> _topics = <String>[];

  /// 推荐话题区是否展开。
  ///
  /// 默认收起：面板的空间应该先给正文，标签是可选动作，不该一上来就占地方。
  bool _topicPickerOpen = false;

  bool _pickingImages = false;
  bool _submitting = false;
  String? _error;

  static const int _maxLength = 500;

  /// 面板高度的下限。
  ///
  /// 低于这个值，输入区加上工具栏就没法看了。只在"小屏 + 大键盘"的极端组合下
  /// 才可能触发（正常情况下 [viewInsets] 会让高度自然收缩到合适的位置）。
  static const double _minHeight = 220;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 面板高度。
  ///
  /// 逻辑是"想要的"和"装得下的"取小的那个：
  ///  - **想要**：屏幕的 62%。再高就像整页了，会失去 sheet 的轻量感；
  ///  - **装得下**：屏幕高度减去键盘、再留 96 给状态栏和一点呼吸。
  ///    键盘弹起时如果不收缩，面板顶部会顶出屏幕外。
  double _sheetHeight(MediaQueryData media) {
    final double desired = media.size.height * 0.62;
    final double usable = media.size.height - media.viewInsets.bottom - 96;
    final double height = desired < usable ? desired : usable;
    return height < _minHeight ? _minHeight : height;
  }

  /// 选图。
  ///
  /// 上限由九宫格决定（[PostImageGrid.maxImages]），已经满了就不再让点 ——
  /// 按钮本身会变成禁用态，所以这里只是兜底。
  Future<void> _addImages() async {
    final int remaining = PostImageGrid.maxImages - _images.length;
    if (_pickingImages || remaining <= 0) {
      return;
    }

    setState(() {
      _pickingImages = true;
      _error = null;
    });

    // 走 provider 而不是直接用插件：换真实相册只改注入点，这里零改动。
    final List<String> picked =
        await ref.read(photoLibraryProvider).pickImages(maxCount: remaining);

    // await 之后 widget 可能已经关了（用户在这一秒里按了返回），先确认还活着。
    if (!mounted) {
      return;
    }

    setState(() {
      // 仍然按 `maxImages` 截一次：接口约定实现方会尊重 maxCount，
      // 但"约定"和"保证"是两回事，越界会把九宫格撑坏。
      _images.addAll(picked.take(PostImageGrid.maxImages - _images.length));
      _pickingImages = false;
    });

    if (picked.isNotEmpty) {
      AppHaptics.selection();
    }
  }

  void _removeImage(int index) {
    if (index < 0 || index >= _images.length) {
      return;
    }
    AppHaptics.light();
    setState(() => _images.removeAt(index));
  }

  void _toggleTopic(String topic) {
    AppHaptics.selection();
    setState(() {
      if (_topics.contains(topic)) {
        _topics.remove(topic);
      } else {
        _topics.add(topic);
      }
    });
  }

  Future<void> _submit() async {
    final String text = _controller.text.trim();
    if (text.isEmpty || _submitting) {
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    // `publish` 内部是乐观的：调用返回之前，流里**已经**有这条动态了，
    // 所以面板一关，用户看到的就是自己刚发的内容。
    final Post? created = await ref.read(feedProvider.notifier).publish(
          content: text,
          images: _images,
          topics: _topics,
        );

    if (!mounted) {
      return;
    }

    if (created == null) {
      // 失败时 `publish` 已经把占位条目撤掉了。这里只需把错误摆到用户面前，
      // 并且**保留草稿** —— 让用户重打一遍 500 字是最不可原谅的失败处理。
      setState(() {
        _submitting = false;
        _error = '发布失败，请稍后重试';
      });
      AppHaptics.heavy();
      return;
    }

    AppHaptics.medium();
    Navigator.of(context).pop();
  }

  /// 话题区要显示的内容。
  ///
  /// 已选话题**永远**显示；未选的推荐话题只在展开时才出现。
  /// 这样"收起"状态看到的正好是"我已经选了什么"，语义没有歧义。
  List<String> _chips(List<String> suggestions) {
    if (!_topicPickerOpen) {
      return _topics;
    }
    return <String>[
      ..._topics,
      for (final String topic in suggestions)
        if (!_topics.contains(topic)) topic,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final MediaQueryData media = MediaQuery.of(context);
    final Author me = ref.watch(currentAuthorProvider);
    final List<String> chips = _chips(ref.watch(suggestedTopicsProvider));

    // 用 `runes` 而不是 `length`：Emoji 在 UTF-16 下占 2 个 code unit，
    // 直接数长度会让字数比用户感知的多 1。
    final int length = _controller.text.runes.length;
    final bool canSubmit = _controller.text.trim().isNotEmpty && !_submitting;

    return Padding(
      // 键盘高度直接变成面板的底部留白，面板因此"长"在键盘上面。
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: SizedBox(
        height: _sheetHeight(media),
        child: Column(
          children: <Widget>[
            _Header(
              canSubmit: canSubmit,
              busy: _submitting,
              onSubmit: canSubmit ? _submit : null,
              onCancel: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  0,
                  AppSpacing.xl,
                  AppSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _AuthorLine(author: me),
                    const SizedBox(height: AppSpacing.md),

                    // ── 输入区：**无边框** ──
                    // 没有底色、没有描边、没有圆角框，只有一行占位符。
                    // iOS 的编辑态本来就是这样：输入区就是页面本身，
                    // 加一个灰底输入框立刻就有了"网页表单"的味道。
                    CupertinoTextField(
                      controller: _controller,
                      autofocus: true,
                      maxLines: null,
                      minLines: 6,
                      maxLength: _maxLength,
                      style: AppTypography.body.copyWith(color: palette.label),
                      placeholder: '分享点什么…',
                      placeholderStyle: AppTypography.body.copyWith(
                        color: palette.labelTertiary,
                      ),
                      cursorColor: palette.accent,
                      // 显式指定顶部对齐：带 placeholder 时 Cupertino 的
                      // 默认对齐会变，文字会垂直居中，多行输入时很怪。
                      textAlignVertical: TextAlignVertical.top,
                      padding: EdgeInsets.zero,
                      decoration: null,
                      onChanged: (_) {
                        // 这里必须重绘：字数计数器、以及"发布"按钮的可用态
                        // 都跟着正文内容变。顺手把上一次的错误提示清掉 ——
                        // 红字一直挂在那里会像一条甩不掉的警告。
                        setState(() => _error = null);
                      },
                    ),

                    if (_images.isNotEmpty) ...<Widget>[
                      const SizedBox(height: AppSpacing.md),
                      _ImageStrip(images: _images, onRemove: _removeImage),
                    ],

                    if (chips.isNotEmpty) ...<Widget>[
                      const SizedBox(height: AppSpacing.lg),
                      _TopicChips(
                        topics: chips,
                        selected: _topics,
                        onToggle: _toggleTopic,
                      ),
                    ],
                  ],
                ),
              ),
            ),

            if (_error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  0,
                  AppSpacing.xl,
                  AppSpacing.sm,
                ),
                child: Row(
                  children: <Widget>[
                    Icon(
                      CupertinoIcons.exclamationmark_circle,
                      size: 14,
                      color: palette.danger,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        _error!,
                        style: AppTypography.footnote.copyWith(
                          color: palette.danger,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const HairlineDivider(),
            _Toolbar(
              imageCount: _images.length,
              maxImages: PostImageGrid.maxImages,
              pickingImages: _pickingImages,
              topicPickerOpen: _topicPickerOpen,
              topicCount: _topics.length,
              length: length,
              maxLength: _maxLength,
              onAddImages: _addImages,
              onToggleTopics: () {
                AppHaptics.light();
                setState(() => _topicPickerOpen = !_topicPickerOpen);
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// 顶部：取消 / 标题 / 发布。
class _Header extends StatelessWidget {
  const _Header({
    required this.canSubmit,
    required this.busy,
    this.onSubmit,
    this.onCancel,
  });

  final bool canSubmit;
  final bool busy;
  final VoidCallback? onSubmit;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xs,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Row(
        children: <Widget>[
          Pressable(
            onTap: onCancel,
            scale: 0.94,
            borderRadius: AppRadius.pillAll,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: AppSpacing.sm,
              ),
              child: Text(
                '取消',
                style: AppTypography.callout.copyWith(
                  color: palette.labelSecondary,
                ),
              ),
            ),
          ),
          Expanded(
            child: Text(
              '新动态',
              textAlign: TextAlign.center,
              style: AppTypography.headline.copyWith(color: palette.label),
            ),
          ),
          _PublishPill(enabled: canSubmit, busy: busy, onTap: onSubmit),
        ],
      ),
    );
  }
}

/// 发布按钮（胶囊）。
///
/// 三种状态，视觉上必须一眼可辨：
///  - **无内容** → 灰底灰字，`onTap` 为 `null`，按下去连缩放和触觉都没有；
///  - **有内容** → 蓝底白字，这就是"可以发了"的信号；
///  - **提交中** → 蓝底 + 白色转圈，避免用户在等待里重复点。
class _PublishPill extends StatelessWidget {
  const _PublishPill({
    required this.enabled,
    required this.busy,
    this.onTap,
  });

  final bool enabled;
  final bool busy;
  final VoidCallback? onTap;

  /// 固定高度。禁用 ↔ 可用切换时按钮不能跳，否则用户会以为点错了。
  static const double _height = 34;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return Pressable(
      // `Pressable` 在 onTap 为 null 时整个退化为不可点击（缩放开与触觉都没有），
      // 所以禁用态是"真的不能点"，而不是点了没反应。
      onTap: enabled ? onTap : null,
      scale: 0.92,
      borderRadius: AppRadius.pillAll,
      child: AnimatedContainer(
        duration: AppDuration.fast,
        curve: AppCurves.standard,
        height: _height,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: enabled ? palette.accent : palette.fill,
          borderRadius: AppRadius.pillAll,
        ),
        child: busy
            ? const CupertinoActivityIndicator(
                radius: 7,
                color: CupertinoColors.white,
              )
            : Text(
                '发布',
                style: AppTypography.subheadline.copyWith(
                  color: enabled ? CupertinoColors.white : palette.labelTertiary,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}

/// 作者行：告诉用户"这条会发到你的主页"。
class _AuthorLine extends StatelessWidget {
  const _AuthorLine({required this.author});

  final Author author;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return Row(
      children: <Widget>[
        AppAvatar(
          seed: author.id,
          imageUrl: author.avatarUrl,
          emoji: author.emoji,
          size: 38,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                author.name,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.headline.copyWith(color: palette.label),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                '@${author.handle}',
                overflow: TextOverflow.ellipsis,
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

/// 已选配图的横向预览条。
///
/// 用横向滚动而不是换行网格：草稿阶段的图可能到 9 张，换行会把输入区挤下去，
/// 而横向条的高度是恒定的 84 —— 加图不会让面板"长高"。
class _ImageStrip extends StatelessWidget {
  const _ImageStrip({required this.images, required this.onRemove});

  final List<String> images;

  /// 传下标而不是图片地址：地址可能重复（同一张图选两次），
  /// 用下标才能精确删掉用户点的那一个。
  final void Function(int index) onRemove;

  static const double _tile = 84;
  static const double _gap = AppSpacing.sm;
  static const double _bleed = 6;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return SizedBox(
      // 高度里多留 [_bleed]：删除按钮要凸出小图一点点（iOS 相册的做法），
      // 那部分必须落在可视区内，否则会被 ListView 的视口裁掉。
      height: _tile + _bleed * 2,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        // 让凸出去的那一半落在 padding 里，于是不会被裁。
        padding: const EdgeInsets.only(
          top: _bleed,
          right: _bleed,
          bottom: _bleed,
        ),
        itemCount: images.length,
        separatorBuilder: (BuildContext context, int index) =>
            const SizedBox(width: _gap),
        itemBuilder: (BuildContext context, int index) {
          return SizedBox(
            width: _tile,
            height: _tile,
            child: Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: AppRadius.smAll,
                    child: AppNetworkImage(
                      url: images[index],
                      // 缩略图加载不出来时要占住位置，否则预览条会塌成一条线。
                      fallback: ColoredBox(color: palette.surfaceRaised),
                    ),
                  ),
                ),
                Positioned(
                  top: -_bleed,
                  right: -_bleed,
                  child: Pressable(
                    onTap: () => onRemove(index),
                    scale: 0.86,
                    borderRadius: AppRadius.pillAll,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        // 这层遮罩与主题无关（Apple 也是恒定深色），
                        // 所以刻意不走 palette。
                        color: const Color(0xCC1C1C1E),
                        shape: BoxShape.circle,
                        // 描一圈面板底色，让按钮从小图上"浮"出来。
                        border: Border.all(
                          color: palette.surfaceRaised,
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        CupertinoIcons.xmark,
                        size: 11,
                        color: CupertinoColors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// 话题胶囊区。
class _TopicChips extends StatelessWidget {
  const _TopicChips({
    required this.topics,
    required this.selected,
    required this.onToggle,
  });

  /// 要显示的全部话题（已选 + 展开时的推荐）。
  final List<String> topics;

  /// 其中哪些是已选中的。
  final List<String> selected;

  final void Function(String topic) onToggle;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: <Widget>[
        for (final String topic in topics)
          _TopicChip(
            label: topic,
            selected: selected.contains(topic),
            onTap: () => onToggle(topic),
          ),
      ],
    );
  }
}

/// 话题胶囊。
///
/// 选中态用 `accentSoft` 底 + `accent` 字 + 一个对勾，靠**两种**手段区分，
/// 而不是只靠颜色 —— 只靠颜色的话，色觉障碍用户看不出选没选上。
class _TopicChip extends StatelessWidget {
  const _TopicChip({
    required this.label,
    required this.selected,
    this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return Pressable(
      onTap: onTap,
      scale: 0.93,
      borderRadius: AppRadius.pillAll,
      child: AnimatedContainer(
        duration: AppDuration.fast,
        curve: AppCurves.standard,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs + 2,
        ),
        decoration: BoxDecoration(
          color: selected ? palette.accentSoft : palette.fill,
          borderRadius: AppRadius.pillAll,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (selected) ...<Widget>[
              Icon(CupertinoIcons.checkmark, size: 12, color: palette.accent),
              const SizedBox(width: AppSpacing.xs),
            ],
            Text(
              '#$label',
              style: AppTypography.caption1.copyWith(
                color: selected ? palette.accent : palette.labelSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 底部工具栏：添加图片 / 选择标签 / 字数。
class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.imageCount,
    required this.maxImages,
    required this.pickingImages,
    required this.topicPickerOpen,
    required this.topicCount,
    required this.length,
    required this.maxLength,
    required this.onAddImages,
    required this.onToggleTopics,
  });

  final int imageCount;
  final int maxImages;
  final bool pickingImages;
  final bool topicPickerOpen;
  final int topicCount;
  final int length;
  final int maxLength;
  final VoidCallback onAddImages;
  final VoidCallback onToggleTopics;

  /// 剩余字数进入这个范围就变红，给用户一个"快满了"的提前量。
  static const int _dangerWindow = 50;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.sm,
        AppSpacing.xl,
        AppSpacing.md,
      ),
      child: Row(
        children: <Widget>[
          _ToolButton(
            icon: CupertinoIcons.photo,
            // 张数直接写进标签里：用户不用去数缩略图就知道还能加几张。
            label: imageCount == 0 ? '图片' : '图片 $imageCount/$maxImages',
            busy: pickingImages,
            enabled: imageCount < maxImages,
            onTap: onAddImages,
          ),
          const SizedBox(width: AppSpacing.lg),
          _ToolButton(
            // 展开时用实心图标，和"已展开"的状态对上。
            icon: topicPickerOpen ? CupertinoIcons.tag_fill : CupertinoIcons.tag,
            label: topicCount == 0 ? '标签' : '标签 $topicCount',
            active: topicPickerOpen,
            onTap: onToggleTopics,
          ),
          const Spacer(),
          Text(
            '$length / $maxLength',
            style: AppTypography.tabularNumber.copyWith(
              color: length > maxLength - _dangerWindow
                  ? palette.danger
                  : palette.labelTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

/// 工具栏按钮：图标 + 文字。
class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.icon,
    required this.label,
    this.onTap,
    this.active = false,
    this.busy = false,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  /// 选中 / 展开态。
  final bool active;

  /// 加载中（以转圈替换图标）。
  final bool busy;

  /// 不可用（例如配图已满 9 张）。
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final Color color = active
        ? palette.accent
        : (enabled ? palette.labelSecondary : palette.labelTertiary);

    return Pressable(
      onTap: enabled && !busy ? onTap : null,
      scale: 0.94,
      borderRadius: AppRadius.pillAll,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (busy)
              CupertinoActivityIndicator(radius: 6, color: palette.accent)
            else
              Icon(icon, size: 20, color: color),
            const SizedBox(width: AppSpacing.xs + 2),
            Text(
              label,
              style: AppTypography.footnote.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
