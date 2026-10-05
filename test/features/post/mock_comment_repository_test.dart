import 'package:flutter_test/flutter_test.dart';
import 'package:learning_flutter/features/post/data/repositories/mock_comment_repository.dart';
import 'package:learning_flutter/features/post/data/repositories/mock_post_repository.dart';
import 'package:learning_flutter/features/post/domain/entities/comment.dart';

/// `MockCommentRepository` 的行为测试。
///
/// 和 `mock_post_repository_test.dart` 同样的价值取向：断言的是**契约**，
/// 不是"这份种子数据长什么样"。将来换成 `HttpCommentRepository` 时，
/// 把构造函数换掉、断言原样复用即可。
void main() {
  /// 延迟归零，避免每个用例白等 500ms。
  MockCommentRepository buildRepo() =>
      MockCommentRepository(latency: Duration.zero);

  group('MockCommentRepository.fetchComments', () {
    test('按时间正序返回，最早的在前', () async {
      final repo = buildRepo();
      final comments = await repo.fetchComments('p_001');

      expect(comments, hasLength(3));
      expect(comments.first.id, 'c_001_1');
      expect(comments.last.id, 'c_001_3');

      // 这条断言才是重点：顺序不是巧合，而是排序约定。
      // 评论经常互相回应（p_007 就是"提问 → 追问 → 回答"），
      // 一旦倒序，整段对话会被读反。
      for (int i = 1; i < comments.length; i++) {
        expect(
          comments[i].createdAt.isAfter(comments[i - 1].createdAt),
          isTrue,
          reason: '第 $i 条评论应晚于前一条',
        );
      }
    });

    test('每条评论都晚于所属动态的发布时间', () async {
      final posts = MockPostRepository(latency: Duration.zero);
      final comments = buildRepo();

      // 这是最容易写错、而且不会报错只会显得廉价的约束：
      // 界面上出现"评论比动态还早"时没人会崩溃，但一眼假。
      // 所以这里**跨仓库**比对，而不是在评论数据内部自说自话。
      for (final String postId in <String>[
        'p_001',
        'p_002',
        'p_003',
        'p_004',
        'p_005',
        'p_007',
        'p_012',
      ]) {
        final post = await posts.fetchById(postId);
        final list = await comments.fetchComments(postId);

        expect(list, isNotEmpty, reason: '$postId 应该有种子评论');
        for (final Comment c in list) {
          expect(
            c.createdAt.isAfter(post.createdAt),
            isTrue,
            reason: '$postId 的评论 ${c.id} 早于动态发布时间',
          );
        }
      }
    });

    test('没有评论的动态返回空列表而不是抛错', () async {
      final repo = buildRepo();
      expect(await repo.fetchComments('p_not_exist'), isEmpty);
    });

    test('分页按 pageSize 切片且不重叠', () async {
      final repo = buildRepo();
      final firstPage = await repo.fetchComments('p_001', page: 0, pageSize: 2);
      final secondPage = await repo.fetchComments('p_001', page: 1, pageSize: 2);

      expect(firstPage, hasLength(2));
      expect(secondPage, hasLength(1));
      expect(firstPage.map((c) => c.id), <String>['c_001_1', 'c_001_2']);
      expect(secondPage.map((c) => c.id), <String>['c_001_3']);
    });

    test('越界分页返回空列表', () async {
      final repo = buildRepo();
      expect(await repo.fetchComments('p_001', page: 99, pageSize: 20), isEmpty);
    });

    test('返回的列表不可变', () async {
      final repo = buildRepo();
      final comments = await repo.fetchComments('p_001');
      expect(() => comments.add(comments.first), throwsUnsupportedError);
    });
  });

  group('MockCommentRepository.addComment', () {
    test('新评论追加到末尾，与"时间正序"约定一致', () async {
      final repo = buildRepo();
      final before = await repo.fetchComments('p_001');

      final created = await repo.addComment(postId: 'p_001', content: '新评论');

      expect(created.postId, 'p_001');
      // 评论作者固定是"当前登录用户"——猜"我是谁"是数据层的职责，
      // presentation 层拼不出 `Author`，所以不做乐观插入。
      expect(created.author.id, 'u_me');
      expect(created.likeCount, 0);
      expect(created.likedByMe, isFalse);

      final after = await repo.fetchComments('p_001');
      expect(after, hasLength(before.length + 1));
      expect(after.last.id, created.id);
      expect(after.last.content, '新评论');
    });

    test('内容首尾空白被裁掉', () async {
      final repo = buildRepo();
      final created =
          await repo.addComment(postId: 'p_001', content: '  有点意思  ');
      expect(created.content, '有点意思');
    });

    test('空内容抛 ArgumentError 而不是静默写入', () async {
      final repo = buildRepo();

      // 空评论是**客户端校验漏了**，属于编程错误。返回 null 会让调用方
      // 继续往下走，最后在界面上留一条空气泡 —— 不如尽早炸出来。
      await expectLater(
        repo.addComment(postId: 'p_001', content: '   '),
        throwsArgumentError,
      );
    });

    test('原本没有评论的动态也能发出第一条', () async {
      final repo = buildRepo();
      // 刻意用一个不存在的 id：要的就是"空 → 有一条"这条路径。
      const String postId = 'p_999_no_seed';

      expect(await repo.fetchComments(postId), isEmpty);

      await repo.addComment(postId: postId, content: '第一条');

      expect(await repo.fetchComments(postId), hasLength(1));
    });

    test('连续发多条时 id 不重复', () async {
      final repo = buildRepo();
      final a = await repo.addComment(postId: 'p_001', content: 'a');
      final b = await repo.addComment(postId: 'p_001', content: 'b');

      expect(a.id, isNot(b.id));
    });
  });

  group('MockCommentRepository.toggleLike', () {
    test('翻转点赞状态并同步计数', () async {
      final repo = buildRepo();
      final before = (await repo.fetchComments('p_005')).first;
      expect(before.likedByMe, isFalse);

      final after = await repo.toggleLike(before.id);

      expect(after.likedByMe, isTrue);
      expect(after.likeCount, before.likeCount + 1);
    });

    test('状态被"服务端"记住：重新拉取是翻转后的值', () async {
      final repo = buildRepo();
      final before = (await repo.fetchComments('p_005')).first;

      final toggled = await repo.toggleLike(before.id);
      final refetched = (await repo.fetchComments('p_005')).first;

      // 刻意不假设初始 likedByMe —— 种子里"已点赞"的条目是给 UI
      // 展示实心心形用的，调整它们不该让这条用例失效。
      expect(refetched.likedByMe, !before.likedByMe);
      expect(refetched, toggled);
    });

    test('未知 id 抛 StateError', () async {
      final repo = buildRepo();
      await expectLater(repo.toggleLike('c_not_exist'), throwsStateError);
    });
  });

  group('每个实例状态独立', () {
    test('一个实例发的评论不会出现在另一个实例里', () async {
      final a = buildRepo();
      final b = buildRepo();

      await a.addComment(postId: 'p_003', content: '只属于 a');

      expect(await b.fetchComments('p_003'), hasLength(3));
    });
  });
}
