import 'package:flutter_test/flutter_test.dart';
import 'package:learning_flutter/features/post/data/mock/mock_authors.dart';
import 'package:learning_flutter/features/post/data/mock/mock_comments.dart';
import 'package:learning_flutter/features/post/data/mock/mock_posts.dart';
import 'package:learning_flutter/features/post/domain/entities/author.dart';
import 'package:learning_flutter/features/post/domain/entities/comment.dart';
import 'package:learning_flutter/features/post/domain/entities/post.dart';

/// 种子数据的**自检**。
///
/// 这类断言不测业务逻辑，测的是"数据本身对不对"。Mock 数据的问题从来不是
/// 崩溃，而是某一条悄悄写歪了（时间倒挂、id 撞车、URL 少个字段），
/// 界面上只是"看着有点怪"，没人会去报 bug。
///
/// 另外几条断言是**降级路径的守门人**：Mock 阶段网络不可靠，
/// 图片永远加载不出来时界面必须还能看。为此种子数据里刻意留了
/// "有图 / 无图 / 只能 emoji 占位" 三种样本 —— 谁把它们删掉，
/// 对应那条 UI 分支就再也不会被真实渲染到，等于悄悄烂掉。
void main() {
  // 固定锚点，让整个文件的断言与"今天是几号"无关。
  final DateTime anchor = DateTime(2026, 10, 4, 12);
  final List<Post> posts = buildSeedPosts(now: anchor);

  group('动态种子数据', () {
    test('数量与 id 唯一性', () {
      expect(posts, hasLength(12));

      final Set<String> ids = posts.map((Post p) => p.id).toSet();
      expect(ids, hasLength(posts.length), reason: 'id 有重复');
    });

    test('时间严格递减：第一条最新，最后一条最旧', () {
      for (int i = 1; i < posts.length; i++) {
        expect(
          posts[i].createdAt.isBefore(posts[i - 1].createdAt),
          isTrue,
          reason: '${posts[i].id} 应该比 ${posts[i - 1].id} 旧',
        );
      }
    });

    test('发布时间都在锚点之前（不能出现"未来动态"）', () {
      for (final Post p in posts) {
        expect(p.createdAt.isBefore(anchor), isTrue, reason: '${p.id} 在未来');
      }
    });

    test('正文、作者都不为空', () {
      for (final Post p in posts) {
        expect(p.content.trim(), isNotEmpty, reason: '${p.id} 正文为空');
        expect(p.author.name, isNotEmpty);
        expect(p.author.id, isNotEmpty);
      }
    });

    test('所有配图 URL 都是合法的 picsum 地址', () {
      for (final Post p in posts) {
        for (final String url in p.images) {
          expect(url, startsWith('https://picsum.photos/seed/'),
              reason: '${p.id} 的配图 URL 不符合约定');
        }
      }
    });

    test('图片与 emoji 占位两种方案都还有样本', () {
      // 这两条断言是刻意留的"覆盖率护栏"：
      //  - 全站至少要有一条带真实配图的动态 → 走 AppNetworkImage；
      //  - 至少要有一条没有图、只有 emoji 占位的 → 走 PostCard 的降级分支。
      // 只保留一种，另一条 UI 路径就永远不会被执行到。
      expect(posts.where((Post p) => p.hasImages), isNotEmpty);
      expect(
        posts.where((Post p) => !p.hasImages && p.hasCover),
        isNotEmpty,
      );
    });

    test('p_011 专门守住 emoji 占位分支', () {
      final Post p = posts.firstWhere((Post p) => p.id == 'p_011');
      expect(p.hasImages, isFalse);
      expect(p.coverEmoji, isNotNull);
    });

    test('图片张数不超过 9 张（九宫格上限）', () {
      for (final Post p in posts) {
        expect(p.images.length, lessThanOrEqualTo(9), reason: p.id);
      }
    });
  });

  group('作者种子数据', () {
    test('当前用户也在作者表里，身份只有一份定义', () {
      // 动态、评论、会话都从 `mock_authors.dart` 取人。
      // 如果这里冒出第二份 currentUser，同一个人就会有两个名字。
      final List<Author> all = <Author>[...seedAuthors, currentUser];
      final Set<String> ids = all.map((Author a) => a.id).toSet();
      expect(ids, hasLength(all.length), reason: '作者 id 有重复');
      expect(ids, contains('u_me'));
    });

    test('动态作者都来自同一份作者表', () {
      final Set<String> knownIds =
          <String>{...seedAuthors.map((Author a) => a.id), currentUser.id};

      for (final Post p in posts) {
        expect(knownIds, contains(p.author.id), reason: '${p.id} 的作者不在表里');
      }
    });

    test('至少留一个没有头像的用户', () {
      // 全站唯一无头像用户（沈迟）刻意不配 avatarUrl，
      // 目的是让 AppAvatar 里 `imageUrl == null` 那条分支长期有真实渲染路径。
      final Iterable<Author> withoutAvatar =
          seedAuthors.where((Author a) => !a.hasAvatar);
      expect(withoutAvatar, isNotEmpty);
    });

    test('有头像的 URL 都符合约定', () {
      for (final Author a in seedAuthors.where((Author a) => a.hasAvatar)) {
        expect(a.avatarUrl, startsWith('https://picsum.photos/seed/'));
      }
    });
  });

  group('评论种子数据', () {
    final Map<String, List<Comment>> comments = buildSeedComments(now: anchor);

    test('非空，且每条评论的 postId 与所在分组一致', () {
      expect(comments, isNotEmpty);

      comments.forEach((String postId, List<Comment> list) {
        expect(list, isNotEmpty, reason: '$postId 分到了空列表');
        for (final Comment c in list) {
          expect(c.postId, postId, reason: '${c.id} 被挂到了错误的动态下');
        }
      });
    });

    test('同一动态内评论按时间正序', () {
      comments.forEach((String postId, List<Comment> list) {
        for (int i = 1; i < list.length; i++) {
          expect(
            list[i].createdAt.isAfter(list[i - 1].createdAt),
            isTrue,
            reason: '$postId 的第 $i 条评论时间倒挂',
          );
        }
      });
    });

    test('每条评论都晚于所属动态的发布时间', () {
      final Map<String, Post> byId = <String, Post>{
        for (final Post p in posts) p.id: p,
      };

      comments.forEach((String postId, List<Comment> list) {
        final Post? post = byId[postId];
        expect(post, isNotNull, reason: '评论挂在了不存在的动态 $postId 上');
        if (post == null) {
          return;
        }
        for (final Comment c in list) {
          expect(
            c.createdAt.isAfter(post.createdAt),
            isTrue,
            reason: '${c.id} 早于 ${post.id} 的发布时间',
          );
        }
      });
    });

    test('评论 id 全局唯一', () {
      final List<String> allIds = <String>[
        for (final List<Comment> list in comments.values)
          for (final Comment c in list) c.id,
      ];
      expect(allIds.toSet(), hasLength(allIds.length), reason: '评论 id 有重复');
    });

    test('有种子评论的动态都是真实存在的动态', () {
      final Set<String> postIds = posts.map((Post p) => p.id).toSet();
      for (final String postId in comments.keys) {
        expect(postIds, contains(postId));
      }
    });
  });

  group('buildMockComments 的确定性', () {
    test('同一锚点两次调用结果完全一致', () {
      // 这是"不读 DateTime.now()"这条纪律的验证：
      // 只要入参相同，结果就必须逐字相同，否则没法写断言。
      final List<Comment> a = buildMockComments('p_999', now: anchor);
      final List<Comment> b = buildMockComments('p_999', now: anchor);

      expect(a, b);
      expect(a.map((Comment c) => c.id), b.map((Comment c) => c.id));
    });

    test('count 控制条数，且不越界', () {
      expect(buildMockComments('p_999', now: anchor), hasLength(3));
      expect(buildMockComments('p_999', count: 0, now: anchor), isEmpty);
      expect(buildMockComments('p_999', count: 20, now: anchor), hasLength(20));
    });

    test('大量生成时也不会出现"未来时间"的评论', () {
      // 回归护栏：偏移量若写死成 `30 - i * 7`，count >= 6 就会减出负数，
      // 而 `subtract(负数)` 等于**加**时间，于是列表顶部出现"3 分钟后"
      // 这种一眼假的时间 —— 不报错，但 demo 立刻显得廉价。
      for (final int n in <int>[1, 3, 6, 20]) {
        for (final Comment c in buildMockComments('p_999', count: n, now: anchor)) {
          expect(
            c.createdAt.isBefore(anchor),
            isTrue,
            reason: 'count=$n 时 ${c.id} 落在了未来',
          );
        }
      }
    });

    test('时间按顺序递增（越靠后的评论越晚）', () {
      final List<Comment> list = buildMockComments('p_999', count: 4, now: anchor);
      for (int i = 1; i < list.length; i++) {
        expect(list[i].createdAt.isAfter(list[i - 1].createdAt), isTrue);
      }
    });
  });
}
