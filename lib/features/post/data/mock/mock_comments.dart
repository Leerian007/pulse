import '../../../../core/mock/mock_data_service.dart';
import '../../domain/entities/author.dart';
import '../../domain/entities/comment.dart';
import 'mock_authors.dart';

/// 评论的 Mock 种子数据。
///
/// ## 一条很容易写错的约束
///
/// 评论时间**必须晚于所属动态的发布时间**。否则界面上会出现
/// "评论比动态还早"这种一眼假的数据 —— 而且它不会报错，只会让 demo 显得廉价。
/// 下面每条评论都用 `anchor.subtract(...)` 且偏移量小于动态自身的偏移量，
/// 从构造上保证这个顺序。改动态时间时记得同步改这里。
///
/// ## 为什么只有一部分动态有评论
///
/// `Post.commentCount` 是**服务端的总数**（比如 42 条），
/// 而 `fetchComments` 返回的是分页后的第一页。两者不必相等 ——
/// 这正是真实后端的形态，Mock 里保留这个差异可以让分页逻辑早点被验证到。
Map<String, List<Comment>> buildSeedComments({DateTime? now}) {
  final DateTime anchor = MockDataService.anchorNow(now: now);

  return <String, List<Comment>>{
    // ── p_001：清空桌面（发布 4 分钟前，所以评论都很新、很少）──
    'p_001': <Comment>[
      Comment(
        id: 'c_001_1',
        postId: 'p_001',
        author: zhou,
        content: '这个结论我信。桌上多一样东西，注意力就多一个出口。',
        createdAt: anchor.subtract(const Duration(minutes: 3)),
        likeCount: 24,
        likedByMe: true,
      ),
      Comment(
        id: 'c_001_2',
        postId: 'p_001',
        author: mu,
        content: '试过，但两天就又堆满了。感觉根子不在桌面，在"东西没地方去"。',
        createdAt: anchor.subtract(const Duration(minutes: 2)),
        likeCount: 11,
      ),
      Comment(
        id: 'c_001_3',
        postId: 'p_001',
        author: lin,
        content: '同意后半句。收纳的本质是给每样东西一个"被找到"的位置。',
        createdAt: anchor.subtract(const Duration(seconds: 40)),
        likeCount: 3,
      ),
    ],

    // ── p_002：关于"流畅"的定义（发布 38 分钟前）──
    'p_002': <Comment>[
      Comment(
        id: 'c_002_1',
        postId: 'p_002',
        author: shen,
        content: '骨架屏那段太真实了。转圈是在说"等着"，骨架屏是在说"马上来"。',
        createdAt: anchor.subtract(const Duration(minutes: 30)),
        likeCount: 88,
      ),
      Comment(
        id: 'c_002_2',
        postId: 'p_002',
        author: qi,
        content: '"评价的从来不是帧率"——但反过来说，掉帧会让人把等待归因到"卡"，而不是"慢"。',
        createdAt: anchor.subtract(const Duration(minutes: 22)),
        likeCount: 41,
      ),
      Comment(
        id: 'c_002_3',
        postId: 'p_002',
        author: an,
        content: '所以"零等待"其实是不可能做到的，能做的是让等待可解释。',
        createdAt: anchor.subtract(const Duration(minutes: 9)),
        likeCount: 57,
        likedByMe: true,
      ),
    ],

    // ── p_003：柠檬树（发布 2 小时 15 分前）──
    'p_003': <Comment>[
      Comment(
        id: 'c_003_1',
        postId: 'p_003',
        author: mu,
        content: '十四个月……我的那棵第三年才结果，你已经很快了。',
        createdAt: anchor.subtract(const Duration(hours: 2)),
        likeCount: 19,
      ),
      Comment(
        id: 'c_003_2',
        postId: 'p_003',
        author: lin,
        content: '"中间差点死过一次"—— 这句话比结果本身有意思。',
        createdAt: anchor.subtract(const Duration(hours: 1, minutes: 40)),
        likeCount: 63,
      ),
      Comment(
        id: 'c_003_3',
        postId: 'p_003',
        author: currentUser,
        content: '第一颗打算怎么吃？',
        createdAt: anchor.subtract(const Duration(minutes: 55)),
        likeCount: 2,
      ),
    ],

    // ── p_004：一个人住 1000 天清单（发布 5 小时前）──
    'p_004': <Comment>[
      Comment(
        id: 'c_004_1',
        postId: 'p_004',
        author: zhou,
        content: '第二条被击中了。只开顶灯的家真的像办公室，我一直说不出哪里不对。',
        createdAt: anchor.subtract(const Duration(hours: 4, minutes: 30)),
        likeCount: 156,
      ),
      Comment(
        id: 'c_004_2',
        postId: 'p_004',
        author: shen,
        content: '补充一条：垃圾桶买小一点的，你会被迫每天倒，厨房就没味道。',
        createdAt: anchor.subtract(const Duration(hours: 3)),
        likeCount: 214,
        likedByMe: true,
      ),
      Comment(
        id: 'c_004_3',
        postId: 'p_004',
        author: an,
        content: '"能坐下两个人的沙发"——家具其实是在给关系留位置。',
        createdAt: anchor.subtract(const Duration(hours: 1, minutes: 20)),
        likeCount: 92,
      ),
    ],

    // ── p_005：手冲咖啡（发布 9 小时前）──
    'p_005': <Comment>[
      Comment(
        id: 'c_005_1',
        postId: 'p_005',
        author: qi,
        content: '92 度有点高，耶加雪菲我一般 88 走完，酸会更干净。',
        createdAt: anchor.subtract(const Duration(hours: 8)),
        likeCount: 27,
      ),
      Comment(
        id: 'c_005_2',
        postId: 'p_005',
        author: mu,
        content: '明天降两度试一下，谢了。',
        createdAt: anchor.subtract(const Duration(hours: 6, minutes: 30)),
        likeCount: 5,
      ),
    ],

    // ── p_007：重构与技术债（发布 1 天 11 小时前）──
    'p_007': <Comment>[
      Comment(
        id: 'c_007_1',
        postId: 'p_007',
        author: shen,
        content: '"不敢动"这个判据太好了。比任何 lint 规则都准。',
        createdAt: anchor.subtract(const Duration(days: 1, hours: 9)),
        likeCount: 302,
      ),
      Comment(
        id: 'c_007_2',
        postId: 'p_007',
        author: mu,
        content: '问题是很多模块"不敢动"，但也没人需要动它。那算债吗？',
        createdAt: anchor.subtract(const Duration(days: 1, hours: 2)),
        likeCount: 178,
      ),
      Comment(
        id: 'c_007_3',
        postId: 'p_007',
        author: lin,
        content: '算"或有负债"——不出事就一直不兑付，出事就是一次性还清。',
        createdAt: anchor.subtract(const Duration(hours: 20)),
        likeCount: 421,
        likedByMe: true,
      ),
    ],

    // ── p_012：不做会怎样（发布 8 天前）──
    'p_012': <Comment>[
      Comment(
        id: 'c_012_1',
        postId: 'p_012',
        author: zhou,
        content: '我把这句写在需求评审的模板里了，确实能砍掉一半。',
        createdAt: anchor.subtract(const Duration(days: 7, hours: 20)),
        likeCount: 233,
      ),
      Comment(
        id: 'c_012_2',
        postId: 'p_012',
        author: qi,
        content: '但也要小心用过头：有些需求不做当时不会怎样，一年后会很怎样。',
        createdAt: anchor.subtract(const Duration(days: 7)),
        likeCount: 389,
      ),
      Comment(
        id: 'c_012_3',
        postId: 'p_012',
        author: shen,
        content: '同意。所以我会追问一句：不做的话，先记在哪儿？',
        createdAt: anchor.subtract(const Duration(days: 5)),
        likeCount: 156,
        likedByMe: true,
      ),
    ],
  };
}

/// 给没有预置评论的动态生成一段通用线程。
///
/// 和 `buildMockThread` 同样的思路：**不读 `DateTime.now()`**，
/// 时间全部从锚点反推，这样入参不变结果就确定，便于写断言。
List<Comment> buildMockComments(
  String postId, {
  int count = 3,
  DateTime? now,
}) {
  final DateTime anchor = MockDataService.anchorNow(now: now);
  const List<String> pool = <String>[
    '说到点子上了。',
    '存下来慢慢看。',
    '这个角度我之前没想过。',
    '有同感，最近也在纠结这件事。',
    '能展开讲讲吗？',
    '转给朋友了，他正好需要。',
    '写得真好，尤其是中间那段。',
    '我持保留意见，但承认这说法成立。',
  ];
  const List<int> likes = <int>[12, 47, 8, 103, 26, 5, 61, 19];

  final List<Author> candidates = seedAuthors;

  return <Comment>[
    for (int i = 0; i < count; i++)
      Comment(
        id: '${postId}_gc$i',
        postId: postId,
        // 取模保证不会越界；`candidates` 为空时下面兜底会接住。
        author: candidates.isEmpty
            ? currentUser
            : candidates[i % candidates.length],
        content: pool[i % pool.length],
        // 最早的一条在 `30 + (count - 1) * 7` 分钟前，之后每 7 分钟一条，
        // 最后一条落在 30 分钟前。i 越大 → 减得越少 → 时间越晚。
        //
        // 这里必须让偏移量随 count 一起放大，否则 count 一大就会减出负数，
        // `subtract(负数)` 等于**加**时间，直接生成"未来时间"的评论 ——
        // 不报错，但列表顶部会出现"3 分钟后"这种一眼假的时间。
        createdAt: anchor.subtract(Duration(minutes: 30 + (count - 1 - i) * 7)),
        likeCount: likes[i % likes.length],
      ),
  ];
}
