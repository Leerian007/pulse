import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learning_flutter/app/app.dart';

/// 冒烟测试：验证"启动 → 底部导航 → 动态流加载出内容"这条主线是通的。
///
/// ⚠️ 注意：全程**不能用 `pumpAndSettle()`**。
/// 骨架屏里的 `AnimationController.repeat()` 永远不会停，
/// `pumpAndSettle` 会一直等到超时。Mock 的 500ms 延迟用
/// `pump(Duration)` 显式推进即可（`testWidgets` 跑在 FakeAsync 里）。
void main() {
  testWidgets('启动后展示三个 Tab，并加载出动态流内容', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: PulseApp()),
    );

    // ── 首帧：底部导航就位 ──
    // 大标题与 Tab 标签都叫「动态」，所以用 findsWidgets（≥1）。
    expect(find.text('动态'), findsWidgets);
    expect(find.text('消息'), findsWidgets);
    expect(find.text('我的'), findsWidgets);

    // ── 越过 Mock 的 500ms 模拟延迟 ──
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();

    // 种子数据里的第一条动态已经渲染出来（说明骨架屏已让位给真实内容）。
    expect(find.textContaining('把书桌彻底清空'), findsOneWidget);
  });

  testWidgets('点击「消息」Tab 切到会话列表', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: PulseApp()),
    );
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();

    // 点底部 Tab Bar 上的「消息」标签。
    await tester.tap(find.text('消息').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // 会话列表的第一个联系人在种子数据里是「林深」。
    expect(find.text('林深'), findsWidgets);
  });
}
