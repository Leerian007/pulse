/// 全局常量。
///
/// 只放"跨层共享、且与 UI 无关"的值。**注意分层**：
/// data 层（Mock Repository）也要读这里的 `mockLatency`，
/// 所以它不能放在 `theme/` 里 —— 否则数据层就会反向依赖 UI 层。
abstract final class AppConstants {
  static const String appName = 'Pulse';

  static const String appTagline = '让每一次心跳都被听见';

  /// 本地 Mock 阶段统一的"网络往返"延迟。
  ///
  /// 所有 MockRepository 都必须经过它，这样以后把 Mock 换成真实 HTTP 时，
  /// loading / 骨架屏 / 空隙态这些 UX 分支已经被完整验证过了。
  static const Duration mockLatency = Duration(milliseconds: 500);

  /// 动态流一页的条数。
  static const int feedPageSize = 20;
}
