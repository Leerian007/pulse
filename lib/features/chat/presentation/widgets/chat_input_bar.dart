import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_surface.dart';
import '../../../../core/widgets/pressable.dart';

/// 聊天输入栏。
///
/// 三点设计：
///  1. **毛玻璃**：底栏用 [GlassSurface]，消息从它下面滚过时会透出来；
///  2. **底部安全区**：Home Indicator 区域的间距由这里自己加
///     （`Scaffold` 不会替 `bottomNavigationBar` 加安全区）；
///  3. 发送按钮有"可用 / 不可用"两态，用 [AnimatedContainer] 平滑过渡，
///     避免按钮突然变色。
class ChatInputBar extends StatefulWidget {
  const ChatInputBar({super.key, required this.onSend});

  /// 回调里拿到的是**未 trim** 的原文，由上层（notifier）统一清洗。
  final ValueChanged<String> onSend;

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final String text = _controller.text;
    if (text.trim().isEmpty) {
      return;
    }
    AppHaptics.light();
    widget.onSend(text);
    // 发完立刻清空，让输入栏回到空态 —— 本地优先策略下这是安全的：
    // 消息已经以 sending 气泡出现在列表里，不需要用户再"看着输入框等待"。
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final double ratio = MediaQuery.devicePixelRatioOf(context);
    final double bottomInset = MediaQuery.paddingOf(context).bottom;

    return GlassSurface(
      blur: 24,
      border: Border(
        top: BorderSide(color: palette.separator, width: 1 / ratio),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm + bottomInset,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Expanded(
            child: Container(
              constraints: const BoxConstraints(minHeight: 36),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm - 2,
              ),
              decoration: BoxDecoration(
                color: palette.fill,
                borderRadius: AppRadius.pillAll,
              ),
              child: CupertinoTextField(
                controller: _controller,
                minLines: 1,
                maxLines: 5,
                style: AppTypography.body.copyWith(color: palette.label),
                placeholder: '发消息…',
                placeholderStyle: AppTypography.body.copyWith(
                  color: palette.labelTertiary,
                ),
                cursorColor: palette.accent,
                // 去掉 CupertinoTextField 自带的内边距与边框，
                // 由外层 Container 负责视觉。
                padding: EdgeInsets.zero,
                decoration: null,
                textInputAction: TextInputAction.newline,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _controller,
            builder: (BuildContext context, TextEditingValue value, Widget? child) {
              final bool canSend = value.text.trim().isNotEmpty;
              return Pressable(
                onTap: canSend ? _send : null,
                scale: 0.86,
                borderRadius: AppRadius.pillAll,
                child: AnimatedContainer(
                  duration: AppDuration.fast,
                  curve: AppCurves.emphasized,
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: canSend ? palette.accent : palette.fill,
                  ),
                  child: Icon(
                    CupertinoIcons.arrow_up,
                    size: 18,
                    color: canSend ? Colors.white : palette.labelTertiary,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
