/// 种子用户（作者）目录。
///
/// ## 为什么单独抽一个文件
///
/// 原来这 6 个作者是 `buildSeedPosts()` 里的**局部变量**，只有动态能用。
/// 加上评论功能后，评论的作者必须是同一批人 —— 否则同一个 `u_lin`
/// 在动态里叫"林深"、在评论里叫别的名字，数据就自相矛盾了。
///
/// 所以提成模块级常量，让动态与评论**共用同一份身份定义**。
///
/// 注意这里是 `final` 而非 `const`：`avatarUrl` 由 [MockDataService] 拼出来，
/// 是运行期求值的。代价只是极小的初始化开销，换来 URL 方案集中在一处可改。
library;

import '../../../../core/mock/mock_data_service.dart';
import '../../domain/entities/author.dart';

/// 林深 —— 技术写作者，认证用户。
final Author lin = Author(
  id: 'u_lin',
  name: '林深',
  handle: 'linshen',
  avatarUrl: MockDataService.avatarUrl('u_lin'),
  bio: '写代码，也写怎么把代码写少一点。',
  emoji: '🦊',
  isVerified: true,
  isFollowing: true,
);

/// 周迟 —— 产品经理。
final Author zhou = Author(
  id: 'u_zhou',
  name: '周迟',
  handle: 'zhouchi',
  avatarUrl: MockDataService.avatarUrl('u_zhou'),
  bio: '在一家小公司做产品，关心体验胜过功能。',
  emoji: '🐳',
);

/// 阿南 —— 植物与写作。
final Author an = Author(
  id: 'u_an',
  name: '阿南',
  handle: 'anan',
  avatarUrl: MockDataService.avatarUrl('u_an'),
  bio: '阳台种了十七盆植物，写了两百篇没人看的文章。',
  emoji: '🌿',
  isVerified: true,
);

/// 祁七 —— 摄影师 / 独居生活。
final Author qi = Author(
  id: 'u_qi',
  name: '祁七',
  handle: 'qiqi',
  avatarUrl: MockDataService.avatarUrl('u_qi'),
  bio: '拍胶片，一个人住第六年。',
  emoji: '🪐',
);

/// 木也 —— 咖啡与城市。
final Author mu = Author(
  id: 'u_mu',
  name: '木也',
  handle: 'muye',
  avatarUrl: MockDataService.avatarUrl('u_mu'),
  bio: '每天早上一杯浅烘，然后去上班。',
  emoji: '☕️',
);

/// 沈迟 —— 前产品 / 音乐重度用户。
///
/// **刻意不配 `avatarUrl`**：全站唯一一个没有头像的用户。
/// 目的是让 `AppAvatar` 里 `imageUrl == null` 那条分支长期有真实渲染路径 ——
/// 否则它只会在"图片加载失败"时才被走到，等于没人验证过。
/// 顺带也更真实：真实社区里总有人不设头像。
final Author shen = Author(
  id: 'u_shen',
  name: '沈迟',
  handle: 'shenchi',
  bio: '听了三千张专辑，做了三年产品，现在两样都在放。',
  emoji: '🎧',
);

/// 发布新动态 / 发评论时用的"当前登录用户"。
final Author currentUser = Author(
  id: 'u_me',
  name: '你',
  handle: 'pulse_me',
  avatarUrl: MockDataService.avatarUrl('u_me'),
  bio: '在做一些安静的东西。',
  emoji: '🧊',
);

/// 全部种子用户，顺序即"推荐关注"的默认顺序。
final List<Author> seedAuthors = List<Author>.unmodifiable(<Author>[
  lin,
  zhou,
  an,
  qi,
  mu,
  shen,
]);
