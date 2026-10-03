import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/post.dart';
import '../providers/feed_providers.dart';

/// 发布动态的底部面板。
///
/// 用 `showModalBottomSheet` + 主题里统一的 `sheetTop` 圆角与 drag handle，
/// 得到 iOS sheet 的观感；键盘弹起时通过 `viewInsets.bottom` 把面板顶上去。
///
/// 刻意不收 `WidgetRef` 参数：面板内部用 `ConsumerStatefulWidget` 自己拿 ref，
/// 这样调用方（FeedPage）不需要把自己持有的 ref 透传进来。
Future<void> showPostComposer(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    // 背景遮罩压暗一点，让 sheet 更"浮"。
    barrierColor: Colors.black.withValues(alpha: 0.32),
    builder: (BuildContext sheetContext) => const _PostComposerSheet(),
  );
}

class _PostComposerSheet extends ConsumerStatefulWidget {
  const _PostComposerSheet();

  @override
  ConsumerState<_PostComposerSheet> createState() => _PostComposerSheetState();
}

class _PostComposerSheetState extends ConsumerState<_PostComposerSheet> {
  final TextEditingController _controller = TextEditingController();
  bool _submitting = false;
  String? _error;

  static const int _maxLength = 500;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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

    final Post? created = await ref.read(feedProvider.notifier).publish(content: text);

    // await 之后必须确认 widget 还活着，否则 context 已经失效。
    if (!mounted) {
      return;
    }

    if (created == null) {
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

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final double bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    // 用 `runes` 而不是 `length`：Emoji 在 UTF-16 下占 2 个 code unit，
    // 直接数长度会让字数统计比用户感知的多 1。
    final int length = _controller.text.runes.length;
    final bool canSubmit = _controller.text.trim().isNotEmpty && !_submitting;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          0,
          AppSpacing.xl,
          AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // ── 标题行：取消 / 标题 / 发布 ──
            Row(
              children: <Widget>[
                _TextAction(
                  label: '取消',
                  color: palette.labelSecondary,
                  onTap: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: Text(
                    '新动态',
                    textAlign: TextAlign.center,
                    style: AppTypography.headline.copyWith(color: palette.label),
                  ),
                ),
                _TextAction(
                  label: _submitting ? '发布中' : '发布',
                  color: canSubmit ? palette.accent : palette.labelTertiary,
                  bold: true,
                  onTap: canSubmit ? _submit : null,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── 输入区 ──
            Container(
              constraints: const BoxConstraints(minHeight: 132),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: palette.fill,
                borderRadius: AppRadius.mdAll,
              ),
              child: CupertinoTextField(
                controller: _controller,
                autofocus: true,
                maxLines: null,
                minLines: 5,
                maxLength: _maxLength,
                // `maxLength` 会在右下角自动渲染一个字数计数器，
                // 这正是 iOS 输入框的习惯位置。
                style: AppTypography.body.copyWith(color: palette.label),
                placeholder: '分享点什么…',
                placeholderStyle: AppTypography.body.copyWith(
                  color: palette.labelTertiary,
                ),
                cursorColor: palette.accent,
                padding: EdgeInsets.zero,
                decoration: null,
                onChanged: (_) => setState(() => _error = null),
              ),
            ),

            if (_error != null || length > 0) ...<Widget>[
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: <Widget>[
                  if (_error != null)
                    Expanded(
                      child: Text(
                        _error!,
                        style: AppTypography.footnote.copyWith(color: palette.danger),
                      ),
                    )
                  else
                    const Spacer(),
                  Text(
                    '$length / $_maxLength',
                    style: AppTypography.tabularNumber.copyWith(
                      color: length > _maxLength - 50
                          ? palette.danger
                          : palette.labelTertiary,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 极简的纯文字按钮（不引 Material 的 TextButton，避免继承到 M3 的水波纹与内边距）。
class _TextAction extends StatelessWidget {
  const _TextAction({
    required this.label,
    required this.color,
    this.onTap,
    this.bold = false,
  });

  final String label;
  final Color color;
  final VoidCallback? onTap;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap == null
          ? null
          : () {
              AppHaptics.light();
              onTap!();
            },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.sm,
        ),
        child: Text(
          label,
          style: AppTypography.callout.copyWith(
            color: color,
            fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
