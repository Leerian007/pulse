import '../../domain/entities/author.dart';
import '../../domain/entities/post.dart';

/// 动态流的 Mock 种子数据。
///
/// 三条刻意的设计约定：
///  1. **唯一的动态信息源**。Repository 持有它并在内存里做增删改，
///     而不是每次调用都重新生成 —— 否则点赞后下拉刷新会把点赞"刷没"，
///     这不是 Mock 该有的行为（Mock 要模拟的是"服务端记得住"）。
///  2. 时间是 **相对 now 计算的**，所以永远显示"3 分钟前"而不是"2024年某天"，
///     截图和演示不会过期。
///  3. 不依赖任何 assets，配图用 emoji 占位。
List<Post> buildSeedPosts({DateTime? now}) {
  final DateTime anchor = now ?? DateTime.now();

  const Author lin = Author(
    id: 'u_lin',
    name: '林深',
    handle: 'linshen',
    emoji: '🦊',
    isVerified: true,
  );
  const Author zhou = Author(
    id: 'u_zhou',
    name: '周迟',
    handle: 'zhouchi',
    emoji: '🐳',
  );
  const Author an = Author(
    id: 'u_an',
    name: '阿南',
    handle: 'anan',
    emoji: '🌿',
    isVerified: true,
  );
  const Author qi = Author(
    id: 'u_qi',
    name: '祁七',
    handle: 'qiqi',
    emoji: '🪐',
  );
  const Author mu = Author(
    id: 'u_mu',
    name: '木也',
    handle: 'muye',
    emoji: '☕️',
  );
  const Author shen = Author(
    id: 'u_shen',
    name: '沈迟',
    handle: 'shenchi',
    emoji: '🎧',
  );

  return <Post>[
    Post(
      id: 'p_001',
      author: lin,
      content:
          '把书桌彻底清空之后，写代码的效率大概提升了三成。\n\n'
          '结论：不是自律的问题，是视野里东西太多了。留白本身也是一种生产力。',
      createdAt: anchor.subtract(const Duration(minutes: 4)),
      coverEmoji: '🪴',
      coverCaption: '清空后的桌面，只剩一盏灯和一台电脑',
      likeCount: 328,
      commentCount: 42,
      repostCount: 17,
      topics: <String>['效率', '桌面'],
    ),
    Post(
      id: 'p_002',
      author: zhou,
      content:
          '深夜想到一件事：我们评价一个 App「流畅」，其实评价的从来不是帧率，'
          '而是**它有没有让我等**。\n\n'
          '60fps 的动画配上一秒的接口，体感远不如 30fps 但零等待的界面。'
          '这也是为什么骨架屏比转圈更有效——它至少让等待"有内容"。',
      createdAt: anchor.subtract(const Duration(minutes: 38)),
      likeCount: 1204,
      commentCount: 96,
      repostCount: 233,
      likedByMe: true,
      topics: <String>['产品思考', '体验设计'],
    ),
    Post(
      id: 'p_003',
      author: an,
      content: '阳台上的柠檬树终于结果了。从插枝到现在整整十四个月，中间差点死过一次。',
      createdAt: anchor.subtract(const Duration(hours: 2, minutes: 15)),
      coverEmoji: '🍋',
      coverCaption: '第一颗柠檬',
      likeCount: 512,
      commentCount: 58,
      repostCount: 9,
      topics: <String>['植物', '日常'],
    ),
    Post(
      id: 'p_004',
      author: qi,
      content:
          '整理了一份「一个人住的第 1000 天」清单，全是踩过的坑：\n'
          '· 厨具只买一件最好的，别买三件便宜的\n'
          '· 灯光要有两个层次，只开顶灯的家像办公室\n'
          '· 买一个能坐下两个人的沙发，朋友会来得更频繁',
      createdAt: anchor.subtract(const Duration(hours: 5)),
      likeCount: 2860,
      commentCount: 174,
      repostCount: 611,
      topics: <String>['独居', '生活'],
    ),
    Post(
      id: 'p_005',
      author: mu,
      content: '今天的手冲终于没有翻车。水温 92，闷蒸 30 秒，二三段注水——刻度化的好处是不用凭感觉。',
      createdAt: anchor.subtract(const Duration(hours: 9)),
      coverEmoji: '☕️',
      coverCaption: '耶加雪菲，浅烘',
      likeCount: 176,
      commentCount: 21,
      repostCount: 4,
      topics: <String>['咖啡'],
    ),
    Post(
      id: 'p_006',
      author: shen,
      content:
          '把最近循环的五张专辑放这里了。共同点大概是：都留了很长的器乐段落，'
          '都不急着让你听见主唱。',
      createdAt: anchor.subtract(const Duration(days: 1, hours: 3)),
      likeCount: 433,
      commentCount: 64,
      repostCount: 82,
      topics: <String>['音乐', '歌单'],
    ),
    Post(
      id: 'p_007',
      author: lin,
      content:
          '关于「重构」的一点体会：如果一个模块你不敢动，那它就已经是技术债了——'
          '不管代码本身写得多漂亮。可修改性才是唯一的质量标准。',
      createdAt: anchor.subtract(const Duration(days: 1, hours: 11)),
      likeCount: 977,
      commentCount: 87,
      repostCount: 305,
      topics: <String>['工程', '技术债'],
    ),
    Post(
      id: 'p_008',
      author: zhou,
      content: '周末骑了四十公里，回来发现腿上晒出了骑行裤的印子。夏天的证据。',
      createdAt: anchor.subtract(const Duration(days: 2, hours: 6)),
      coverEmoji: '🚲',
      coverCaption: '沿江绿道，20 公里处',
      likeCount: 289,
      commentCount: 33,
      repostCount: 6,
      topics: <String>['骑行'],
    ),
    Post(
      id: 'p_009',
      author: an,
      content:
          '被问过很多次「怎么坚持写东西」。老实说没有坚持，'
          '只是把门槛降到「打开备忘录打一行字也算」。\n\n'
          '门槛足够低的事情，才不需要毅力。',
      createdAt: anchor.subtract(const Duration(days: 3, hours: 2)),
      likeCount: 1542,
      commentCount: 118,
      repostCount: 447,
      likedByMe: true,
      topics: <String>['写作', '习惯'],
    ),
    Post(
      id: 'p_010',
      author: qi,
      content: '整理旧硬盘翻到 2019 年的照片。那会儿拍的东西很糙，但构图比现在大胆得多。技术进步有时候是想象力退步。',
      createdAt: anchor.subtract(const Duration(days: 5)),
      coverEmoji: '🎞️',
      coverCaption: '2019，第一卷胶片',
      likeCount: 668,
      commentCount: 71,
      repostCount: 124,
      topics: <String>['摄影'],
    ),
    Post(
      id: 'p_011',
      author: mu,
      content: '早上六点半的城市是另一个城市。安静到能听见红绿灯的提示音。',
      createdAt: anchor.subtract(const Duration(days: 6, hours: 4)),
      likeCount: 392,
      commentCount: 45,
      repostCount: 28,
      topics: <String>['城市'],
    ),
    Post(
      id: 'p_012',
      author: shen,
      content:
          '做了三年产品之后最大的转变：不再问「这个功能怎么做」，'
          '而是问「不做会怎样」。大部分需求，不做会怎样都是——不会怎样。',
      createdAt: anchor.subtract(const Duration(days: 8)),
      likeCount: 3110,
      commentCount: 262,
      repostCount: 908,
      topics: <String>['产品思考'],
    ),
  ];
}

/// 发布新动态时用的"当前登录用户"。
const Author currentUser = Author(
  id: 'u_me',
  name: '你',
  handle: 'pulse_me',
  emoji: '🧊',
);
