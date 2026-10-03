import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';

/// Pulse 启动入口。
///
/// 这里刻意保持极简 —— **不要**在 `main()` 里塞初始化逻辑
/// （SharedPreferences、Dio、Firebase...）。那些应该做成
/// `FutureProvider`，或用 `ProviderScope(overrides: [...])` 注入，
/// 否则测试和预览环境就没法绕开它们。
void main() {
  // 唯一必须的初始化：在与平台通道交互前确保绑定已就绪。
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    const ProviderScope(
      child: PulseApp(),
    ),
  );
}
