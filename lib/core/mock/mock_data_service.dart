/// Mock 数据服务的**共享基座**。
///
/// ## 为什么这个类在 `core/` 而不在某个 feature 里
///
/// 它只做三件与业务无关的事：拼图片 URL、生成 id、取时间锚点。
/// 不 import 任何 feature 的实体，所以放在 `core/` 符合分层规则
/// （`core/` 禁止认识 features，反之亦然）。
///
/// **注意**：真正的种子数据（12 条动态、6 个会话…）**不能**统一放到这里。
/// 它们依赖 `Post` / `Conversation` 等 feature 实体，一旦搬到 `core/`
/// 就会让 `core` import `features`，直接违反分层。所以那些数据留在
/// `features/*/data/mock/` 下 —— 这不是分散，而是依赖方向的必然结果。
///
/// ## 图片方案：为什么是 picsum 而不是 Unsplash
///
/// ⚠️ **`source.unsplash.com/random/...` 已于 2024 年下线**，现在返回
/// `HTTP 503`。网上大量教程仍在教这个写法，照着写会满屏碎图。实测：
///
/// ```
/// source.unsplash.com/random/400x400            → 503   ❌
/// images.unsplash.com/photo-<id>?w=400          → 200   ✅ 但单图 1.3MB，慢
/// picsum.photos/seed/<seed>/400/400             → 200   ✅ 快且稳定
/// ```
///
/// Lorem Picsum 的图源本身就是 Unsplash 的照片，且支持 `seed` 参数
/// 保证「同一个 seed 永远返回同一张图」—— 这正是 Mock 数据需要的确定性。
///
/// 想换回 Unsplash 直链时，**只需要改这一个文件**里的两个方法。
abstract final class MockDataService {
  /// 头像 URL。
  ///
  /// [seed] 用用户 id，保证同一个人每次拿到的头像一致。
  /// 传 `u_lin` 和传 `u_lin_2` 会是两张不同的图 —— seed 变了图就变。
  static String avatarUrl(String seed, {int size = 200}) {
    return '$_base/seed/${_normalize(seed)}/$size/$size';
  }

  /// 配图 URL。
  ///
  /// [width] / [height] 决定裁切比例，Picsum 会按这个比例裁好再返回，
  /// 所以客户端不需要再处理纵横比 —— 直接丢给 `Image.network` 即可。
  static String photoUrl(
    String seed, {
    int width = 800,
    int height = 600,
  }) {
    return '$_base/seed/${_normalize(seed)}/$width/$height';
  }

  /// 生成一个**本地** id（乐观更新用）。
  ///
  /// 时间戳 + 序号双保险：同一微秒内连续发两条也不会撞 id。
  /// 真实项目里这个 id 会被服务端返回值替换掉（见 `ChatMessagesNotifier.send`）。
  static String localId(String prefix, {required int seq}) {
    return '${prefix}_local_${DateTime.now().microsecondsSinceEpoch}_$seq';
  }

  /// 种子数据的时间锚点。
  ///
  /// 所有 Mock 时间都用 `anchor.subtract(...)` 相对计算，
  /// 这样界面永远显示"3 分钟前"而不是"2024年某天"，截图和演示不会过期。
  ///
  /// 留出 [now] 参数是为了测试能注入固定时间，从而断言确定的结果。
  static DateTime anchorNow({DateTime? now}) => now ?? DateTime.now();

  /// Picsum 的根地址。抽成常量方便整体替换（例如换成自建图片代理）。
  static const String _base = 'https://picsum.photos';

  /// seed 里只允许出现 URL 安全字符。
  ///
  /// Picsum 对 seed 里的 `/`、`?`、`#` 会解析歧义（`/` 会被当成路径分隔符），
  /// 所以统一替换成 `-`。
  static String _normalize(String seed) {
    return seed.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '-');
  }
}
