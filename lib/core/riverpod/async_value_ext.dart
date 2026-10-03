import 'package:flutter_riverpod/flutter_riverpod.dart';

/// `AsyncValue` 的取值扩展。
///
/// **为什么不用现成的 `.value` / `.valueOrNull`？**
///
/// Riverpod 3 对这两个名字做过语义调整（原本的 `valueOrNull` 被合并进 `value`，
/// 旧的 `value` 因为"出错时行为不合理"被移除）。为了让这份骨架在 Riverpod
/// 2 与 3 上都能编译，这里统一用**模式匹配**取值 —— 它只依赖
/// `AsyncData` 这个稳定的类型和它的 `value` 字段，不依赖 getter 的命名。
extension AsyncValueData<T> on AsyncValue<T> {
  /// 拿到数据；处于 loading / error 且没有历史数据时返回 `null`。
  ///
  /// ```dart
  /// final posts = ref.watch(feedProvider).dataOrNull;
  /// ```
  T? get dataOrNull => switch (this) {
        AsyncData<T>(:final value) => value,
        _ => null,
      };

  /// 是否处于"首次加载"（还没有任何数据可展示）。
  ///
  /// 下拉刷新时 `isLoading` 也是 true，但那时旧数据还在 ——
  /// 这两种情况的 UI 处理完全不同（骨架屏 vs 继续显示旧列表）。
  bool get isInitialLoading => isLoading && dataOrNull == null;

  /// 是否处于"首次失败"（没有任何可回退的历史数据）。
  bool get isInitialError => hasError && dataOrNull == null;
}
