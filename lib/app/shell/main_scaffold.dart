import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/haptics/app_haptics.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_avatar.dart';
import '../../features/chat/presentation/providers/chat_providers.dart';

/// Pulse 的底部 Tab 容器。
///
/// ## 它在架构里的位置
///
/// 这是 go_router [StatefulShellRoute] 的 **shell**。每个 Tab 拥有一个
/// **独立的 Navigator 栈**，带来两个关键好处：
///  1. 「消息 → 会话详情」不会污染「动态」的返回栈；
///  2. 来回切 Tab 时，滚动位置和子页面**都还在**（`IndexedStack` 保活）。
///
/// 它被放在 `app/`（组合根）而不是 `core/` 或某个 feature 里：
/// shell 天然需要认识所有 Tab 对应的 feature（这里读了 chat 的未读总数），
/// 属于"应用级装配"，和 `core/`（不认识任何 feature）不是一类东西。
///
/// ## 三个关键的视觉/交互决策
///
/// 1. **`extendBody: true`** —— 让页面内容延伸到 Tab Bar 后面。
///    没有它，毛玻璃背后就是一片纯色，模糊等于白做。
/// 2. **底部安全区注入** —— 内容因此会滚到 Tab Bar 底下，所以必须给每个
///    页面补回 `TabBar 高度 + Home Indicator` 的底部留白，
///    否则列表最后一条会被永久遮住。这里通过改 `MediaQuery` 一次性解决，
///    页面侧不需要写任何额外代码（`SafeArea` / `ListView` 会自动读到）。
/// 3. **半透明背景** —— `CupertinoTabBar` 检测到 `backgroundColor` 不透明
///    就会自动套上 `BackdropFilter`，这是 iOS 底栏观感的来源。
class MainScaffold extends ConsumerWidget {
  const MainScaffold({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppPalette palette = context.palette;
    final MediaQueryData media = MediaQuery.of(context);

    // 未读总数。
    //
    // 顺手 watch 它还带来一个副作用：会话列表会在 App 启动时就被拉取，
    // 于是角标不必等用户切到「消息」Tab 才出现 —— 这正是真实 App 的行为。
    final int unread = ref.watch(unreadTotalProvider);

    // 底部内容留白 = Tab Bar 高度 + 真实安全区。
    //
    // 用 `viewPadding` 而不是 `padding`：开启 `extendBody` 之后，
    // Scaffold 会把 body 的 `padding.bottom` 置零（内容本来就要延伸到栏下），
    // 而 `viewPadding` 保存的是设备原始安全区，不受 Scaffold 影响。
    // 外面再套一层 max，是为了在键盘弹起等特殊情况下绝不"减少"系统给的留白。
    final double contentInset = math.max(
      media.padding.bottom,
      AppSpacing.tabBarHeight + media.viewPadding.bottom,
    );

    return Scaffold(
      backgroundColor: palette.canvas,
      extendBody: true,
      body: MediaQuery(
        data: media.copyWith(
          padding: media.padding.copyWith(bottom: contentInset),
        ),
        child: navigationShell,
      ),
      bottomNavigationBar: CupertinoTabBar(
        currentIndex: navigationShell.currentIndex,
        onTap: _onTap,
        items: <BottomNavigationBarItem>[
          _buildItem(
            label: '动态',
            icon: CupertinoIcons.house,
            activeIcon: CupertinoIcons.house_fill,
          ),
          // 角标只挂在「消息」这一项（下标 1）上。
          _buildItem(
            label: '消息',
            icon: CupertinoIcons.chat_bubble,
            activeIcon: CupertinoIcons.chat_bubble_fill,
            badge: unread,
          ),
          _buildItem(
            label: '我的',
            icon: CupertinoIcons.person,
            activeIcon: CupertinoIcons.person_fill,
          ),
        ],
        // 半透明 → 自动高斯模糊（见类注释第 3 点）。
        backgroundColor: palette.glass,
        activeColor: palette.accent,
        inactiveColor: palette.labelTertiary,
        iconSize: 26,
        height: AppSpacing.tabBarHeight,
        // 用 hairline（1 物理像素）而不是 1 逻辑像素。
        border: Border(
          top: BorderSide(
            color: palette.separator,
            width: 1 / media.devicePixelRatio,
          ),
        ),
      ),
    );
  }

  /// Tab 点击。
  void _onTap(int index) {
    // Tab 切换属于"高频轻操作"，用最轻的一档触觉。
    AppHaptics.selection();

    navigationShell.goBranch(
      index,
      // 再次点击**当前** Tab → 回到该分支的根路由（清空栈）。
      // 这是 iOS 的标准行为：连点两次「消息」会退出会话详情。
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  /// 构造一个 Tab 项。
  ///
  /// [CupertinoTabBar] 只接受 [BottomNavigationBarItem]，它**不支持角标**，
  /// 所以角标由 [_TabIcon] 自己在图标右上角叠出来。
  static BottomNavigationBarItem _buildItem({
    required String label,
    required IconData icon,
    required IconData activeIcon,
    int badge = 0,
  }) {
    return BottomNavigationBarItem(
      label: label,
      icon: _TabIcon(icon: icon, badge: badge),
      activeIcon: _TabIcon(icon: activeIcon, badge: badge),
    );
  }
}

/// Tab 图标 + 未读角标。
///
/// 图标**不设颜色**：`CupertinoTabBar` 会通过 `IconTheme` 注入
/// activeColor / inactiveColor，手写颜色反而会覆盖掉它的选中态。
class _TabIcon extends StatelessWidget {
  const _TabIcon({required this.icon, this.badge = 0});

  final IconData icon;
  final int badge;

  @override
  Widget build(BuildContext context) {
    // 固定尺寸：让有无角标时图标位置不偏移。
    return SizedBox(
      width: 36,
      height: 28,
      child: Stack(
        // 允许角标溢出图标框（右上角）。
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: <Widget>[
          Icon(icon, size: 26),
          if (badge > 0)
            Positioned(
              top: -3,
              right: -2,
              child: UnreadBadge(count: badge, mini: true),
            ),
        ],
      ),
    );
  }
}
