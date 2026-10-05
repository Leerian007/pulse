import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/riverpod/async_value_ext.dart';
import '../../data/repositories/mock_photo_library.dart';
import '../../domain/entities/post.dart';
import '../../domain/repositories/photo_library.dart';
import 'feed_providers.dart';

/// 相册的注入点。
///
/// 和 `postRepositoryProvider` 一样，业务代码只读这个 provider。
/// 接真实相册时**只改这一行**：换成读取 `image_picker` 的实现，
/// 发帖面板一行都不用动（理由见 `PhotoLibrary` 的注释）。
final Provider<PhotoLibrary> photoLibraryProvider =
    Provider<PhotoLibrary>((ref) => MockPhotoLibrary());

/// 推荐话题的条数上限。
///
/// 12 条足够铺满两行，再多用户也不会往下看 —— 这不是"能放多少放多少"的地方。
const int kMaxSuggestedTopics = 12;

/// 信息流为空时的兜底话题。
///
/// 有兜底而不是给一个空列表：话题区突然空掉会让面板看起来"坏了"，
/// 而且用户确实可能想给动态打个"日常"的标签。
const List<String> _fallbackTopics = <String>['日常', '效率', '产品思考', '生活'];

/// 发帖面板里的"推荐话题"。
///
/// ## 为什么不再引一个仓库
///
/// 社区里"现在大家在聊什么"，本来就可以从**动态流本身**归纳出来：
/// 把所有动态的 topics 按出现顺序去重，就是一份天然的热门榜。
/// 这样做的额外好处是——面板里推荐的话题，一定能在信息流里找到对应的内容；
/// 换成服务端下发的热门榜反而可能出现"点了话题却搜不到东西"。
///
/// 等真实后端提供了 `/topics/trending`，把这里换成 `FutureProvider` 即可，
/// 消费方（`_TopicChips`）只需要接一个 loading 态。
final Provider<List<String>> suggestedTopicsProvider = Provider<List<String>>(
  (ref) {
    final List<Post>? posts = ref.watch(feedProvider).dataOrNull;
    if (posts == null || posts.isEmpty) {
      return _fallbackTopics;
    }

    // 用 List + contains 而不是 Set：条数上限只有 12，
    // 二次复杂度在这个规模下完全无所谓，而 List 保序、代码也少一层。
    final List<String> ordered = <String>[];
    for (final Post post in posts) {
      for (final String topic in post.topics) {
        if (!ordered.contains(topic)) {
          ordered.add(topic);
        }
        if (ordered.length >= kMaxSuggestedTopics) {
          return List<String>.unmodifiable(ordered);
        }
      }
    }

    return ordered.isEmpty
        ? _fallbackTopics
        : List<String>.unmodifiable(ordered);
  },
);
