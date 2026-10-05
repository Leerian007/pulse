import '../entities/author.dart';
import '../entities/post.dart';

/// 动态仓库**接口**（domain 层）。
///
/// 这是整个架构里最重要的一条契约：presentation 层只认识这个接口，
/// 完全不知道数据从哪来。带来的直接好处：
///  - 现在：`MockPostRepository`（内存 + 500ms 延迟）
///  - 以后：`HttpPostRepository`（Dio / retrofit），presentation 层零改动
///  - 测试：`FakePostRepository` 一行 override 注入，不需要任何网络与延迟
///
/// 注意返回类型是 `Future`，且**没有** `Result<T, Error>` 包装 —— 失败直接抛异常，
/// 由 `AsyncValue.guard` / `AsyncError` 统一承接。这是 Riverpod 的惯用法，
/// 比手写 Result 类型少一层心智负担。
abstract interface class PostRepository {
  /// 当前登录用户的身份。
  ///
  /// ## 为什么"我是谁"会挂在动态仓库上
  ///
  /// 因为 [create] 必然是**以当前用户的名义**创建动态 —— 两者是同一件事的两面。
  /// 放在这里，presentation 层就能在不 import 任何 data 层实现的前提下拿到当前用户：
  /// 发帖面板要显示"发到谁的主页"，乐观发布要拼出一条完整的本地 `Post`
  /// （而 `Post` 必须带 `author`，这个字段 UI 自己造不出来）。
  ///
  /// ## 为什么是**同步** getter
  ///
  /// 会话信息在真实后端里也是登录后缓存在本地的，不该为"我是谁"再走一次网络。
  /// 换成 HTTP 实现时从内存里的 session 返回即可 —— 那个类本来就要持有 token
  /// 和用户信息，不算额外负担。
  Author get currentAuthor;

  /// 拉取动态流。分页参数现在就留出来，避免将来改签名波及全链路。
  Future<List<Post>> fetchFeed({int page = 0, int pageSize = 20});

  /// 拉取单条动态。
  Future<Post> fetchById(String postId);

  /// 切换点赞，返回**服务端权威**的那条动态。
  ///
  /// 为什么返回整个 Post 而不是 void：真实后端会把别人的点赞也计入，
  /// 返回值可以用来校正乐观更新造成的偏差。
  Future<Post> toggleLike(String postId);

  /// 发布一条动态，返回创建后的实体（带上了服务端生成的 id 与时间）。
  ///
  /// [images] 是配图地址（最多 9 张，顺序即九宫格顺序），[topics] 是话题标签。
  /// 两者都给了默认值而不是设成必填：绝大多数动态就是纯文字，
  /// 强迫调用方传两个空列表只是噪音。
  Future<Post> create({
    required String content,
    List<String> images = const <String>[],
    List<String> topics = const <String>[],
    String? coverEmoji,
  });
}
