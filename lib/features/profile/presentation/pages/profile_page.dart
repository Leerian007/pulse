import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/riverpod/async_value_ext.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_status_view.dart';
import '../../domain/entities/user_profile.dart';
import '../providers/profile_providers.dart';
import '../widgets/profile_header.dart';
import '../widgets/settings_group.dart';
import '../widgets/theme_mode_selector.dart';

/// 个人中心（Tab 3）。
///
/// 结构上它比前两个 Tab "重"：头部卡片 + 三组设置。
/// 因此这里不再用骨架屏，而是首次加载直接给一个居中的 [CupertinoActivityIndicator] ——
/// 个人资料是低频页面，用户对它的等待预期更宽容，
/// 骨架屏反而会显得页面"闪了一下"。
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<UserProfile> asyncProfile = ref.watch(profileProvider);
    final UserProfile? profile = asyncProfile.dataOrNull;
    final AppPalette palette = context.palette;

    return ColoredBox(
      color: palette.canvas,
      child: CustomScrollView(
        slivers: <Widget>[
          CupertinoSliverNavigationBar(
            largeTitle: const Text('我的'),
            backgroundColor: palette.glass,
          ),
          ..._buildBody(context: context, ref: ref, asyncProfile: asyncProfile, profile: profile),
        ],
      ),
    );
  }

  List<Widget> _buildBody({
    required BuildContext context,
    required WidgetRef ref,
    required AsyncValue<UserProfile> asyncProfile,
    required UserProfile? profile,
  }) {
    if (asyncProfile.isInitialLoading) {
      return const <Widget>[
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: CupertinoActivityIndicator(radius: 12)),
        ),
      ];
    }

    if (profile == null) {
      return <Widget>[
        SliverFillRemaining(
          hasScrollBody: false,
          child: AppStatusView(
            icon: CupertinoIcons.exclamationmark_circle,
            title: '没能加载个人资料',
            message: '稍后再试一次。',
            actionLabel: '重试',
            onAction: () => ref.invalidate(profileProvider),
          ),
        ),
      ];
    }

    return <Widget>[
      SliverList(
        delegate: SliverChildListDelegate(<Widget>[
          const SizedBox(height: AppSpacing.md),

          ProfileHeader(
            profile: profile,
            onEditBio: () => _editBio(context, ref, profile),
          ),

          const SizedBox(height: AppSpacing.xxl),

          // ── 外观 ──
          InsetGroup(
            title: '外观',
            footer: '配色全部来自主题里的 AppPalette，切换后所有页面同步生效。',
            children: <Widget>[
              const ThemeModeSelector(),
            ],
          ),

          // ── 内容 ──
          InsetGroup(
            title: '内容',
            children: <Widget>[
              SettingsRow(
                icon: CupertinoIcons.bookmark,
                label: '我的收藏',
                onTap: () => _showComingSoon(context, '我的收藏'),
              ),
              SettingsRow(
                icon: CupertinoIcons.doc_text,
                label: '草稿箱',
                value: '2 篇',
                onTap: () => _showComingSoon(context, '草稿箱'),
              ),
              SettingsRow(
                icon: CupertinoIcons.bell,
                label: '通知设置',
                value: '已开启',
                onTap: () => _showComingSoon(context, '通知设置'),
              ),
            ],
          ),

          // ── 关于 ──
          InsetGroup(
            title: '关于',
            footer:
                '${AppConstants.appName} · ${AppConstants.appTagline}\n'
                '当前阶段：本地 Mock 数据，所有网络请求均为 500ms 模拟延迟。',
            children: <Widget>[
              SettingsRow(
                icon: CupertinoIcons.info_circle,
                label: '版本',
                value: 'v1.0.0 (1)',
              ),
              SettingsRow(
                icon: CupertinoIcons.settings,
                label: '高级设置',
                onTap: () => _showComingSoon(context, '高级设置'),
              ),
            ],
          ),

          // ── 危险操作 ──
          InsetGroup(
            children: <Widget>[
              SettingsRow(
                label: '退出登录',
                danger: true,
                onTap: () => _confirmSignOut(context),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xxl),
        ]),
      ),
    ];
  }
}

/// 编辑简介：用 iOS 原生的 `CupertinoAlertDialog` + 内嵌输入框。
///
/// 刻意用对话框而不是底部 sheet：单字段的短编辑用 alert 更轻，
/// 也不会因为键盘弹起而需要额外的布局处理。
Future<void> _editBio(
  BuildContext context,
  WidgetRef ref,
  UserProfile profile,
) async {
  final TextEditingController controller =
      TextEditingController(text: profile.bio);

  final String? result = await showCupertinoDialog<String>(
    context: context,
    builder: (BuildContext dialogContext) {
      return CupertinoAlertDialog(
        title: const Text('编辑简介'),
        content: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.md),
          child: CupertinoTextField(
            controller: controller,
            minLines: 3,
            maxLines: 5,
            maxLength: 80,
            autofocus: true,
            style: AppTypography.callout,
            placeholder: '介绍一下自己…',
            padding: const EdgeInsets.all(AppSpacing.sm + 2),
            decoration: BoxDecoration(
              color: CupertinoColors.tertiarySystemFill,
              borderRadius: AppRadius.smAll,
            ),
          ),
        ),
        actions: <Widget>[
          CupertinoDialogAction(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('取消'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: const Text('保存'),
          ),
        ],
      );
    },
  );

  if (result == null) {
    return;
  }

  final bool ok = await ref.read(profileProvider.notifier).updateBio(result);
  if (ok) {
    AppHaptics.medium();
  } else {
    AppHaptics.heavy();
  }
}

/// 尚未实现的入口，统一给一个诚实的提示。
///
/// 骨架阶段刻意**不**让这些行"点了没反应"——静默失败是最差的
/// 交互（用户会怀疑是不是自己没点准），也给后续开发留下明确的待办标记。
Future<void> _showComingSoon(BuildContext context, String feature) async {
  AppHaptics.light();
  return showCupertinoDialog<void>(
    context: context,
    builder: (BuildContext dialogContext) {
      return CupertinoAlertDialog(
        title: Text(feature),
        content: const Padding(
          padding: EdgeInsets.only(top: AppSpacing.sm),
          child: Text('该功能尚未实现，骨架阶段先预留入口。'),
        ),
        actions: <Widget>[
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('好'),
          ),
        ],
      );
    },
  );
}

/// 退出登录的二次确认。
Future<void> _confirmSignOut(BuildContext context) async {
  AppHaptics.heavy();
  return showCupertinoDialog<void>(
    context: context,
    builder: (BuildContext dialogContext) {
      return CupertinoAlertDialog(
        title: const Text('退出登录'),
        content: const Padding(
          padding: EdgeInsets.only(top: AppSpacing.sm),
          child: Text('当前是本地 Mock 阶段，退出后不会有任何真实影响。'),
        ),
        actions: <Widget>[
          CupertinoDialogAction(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('取消'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('退出'),
          ),
        ],
      );
    },
  );
}
