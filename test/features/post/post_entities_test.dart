import 'package:flutter_test/flutter_test.dart';
import 'package:learning_flutter/features/post/domain/entities/author.dart';
import 'package:learning_flutter/features/post/domain/entities/comment.dart';
import 'package:learning_flutter/features/post/domain/entities/post.dart';

/// 实体（值对象）的测试。
///
/// 这些用例守的不是"业务逻辑"而是**值语义**：`==` / `hashCode` / `copyWith`
/// 三个东西一旦写错，症状不是崩溃，而是"界面偶尔不刷新"或"每次都白刷一遍"。
/// 这种 bug 最难查，所以值得用测试把它钉死。
void main() {
  const Author baseAuthor = Author(
    id: 'u_test',
    name: '测试用户',
    handle: 'tester',
  );

  Post buildPost({
    List<String> images = const <String>[],
    String? coverEmoji,
    int likeCount = 0,
    bool likedByMe = false,
  }) {
    return Post(
      id: 'p_test',
      author: baseAuthor,
      content: '一条测试动态',
      createdAt: DateTime(2026, 10, 4, 12),
      images: images,
      coverEmoji: coverEmoji,
      likeCount: likeCount,
      likedByMe: likedByMe,
    );
  }

  Comment buildComment({int likeCount = 0, bool likedByMe = false}) {
    return Comment(
      id: 'c_test',
      postId: 'p_test',
      author: baseAuthor,
      content: '一条测试评论',
      createdAt: DateTime(2026, 10, 4, 12, 30),
      likeCount: likeCount,
      likedByMe: likedByMe,
    );
  }

  group('Author', () {
    test('copyWith 只改指定字段', () {
      final Author updated = baseAuthor.copyWith(name: '改名了');

      expect(updated.name, '改名了');
      expect(updated.id, baseAuthor.id);
      expect(updated.handle, baseAuthor.handle);
      expect(updated.isFollowing, baseAuthor.isFollowing);
    });

    test('toggleFollow 是纯本地翻转，可来回切换', () {
      expect(baseAuthor.isFollowing, isFalse);

      final Author followed = baseAuthor.toggleFollow();
      expect(followed.isFollowing, isTrue);
      // 其余字段原样保留。
      expect(followed, baseAuthor.copyWith(isFollowing: true));
      expect(followed.toggleFollow(), baseAuthor);
    });

    test('hasAvatar 同时挡住 null 和空串', () {
      expect(baseAuthor.hasAvatar, isFalse);
      expect(baseAuthor.copyWith(avatarUrl: '').hasAvatar, isFalse);
      expect(
        baseAuthor.copyWith(avatarUrl: 'https://picsum.photos/x').hasAvatar,
        isTrue,
      );
    });

    test('isFollowing 参与相等性判断', () {
      // 关注按钮的状态就靠这个刷新：如果不参与 `==`，
      // Riverpod 会认为"值没变"，按钮点了没反应。
      expect(baseAuthor, isNot(baseAuthor.copyWith(isFollowing: true)));
    });
  });

  group('Post', () {
    test('默认既没有配图也没有占位封面', () {
      final Post post = buildPost();

      expect(post.images, isEmpty);
      expect(post.hasImages, isFalse);
      expect(post.hasCover, isFalse);
      expect(post.firstImage, isNull);
    });

    test('images 走列表内容比较，而不是引用比较', () {
      // 这条是**回归护栏**：曾经这里用 `other.images == images`，
      // 两个内容相同的 List 永远不相等，导致每次 copyWith 都被判定为
      // "变了"，整条列表无意义地重建。
      final Post a = buildPost(images: const <String>['a.jpg', 'b.jpg']);
      final Post b = buildPost(images: const <String>['a.jpg', 'b.jpg']);
      final Post c = buildPost(images: const <String>['a.jpg']);

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });

    test('copyWith 不传 images 时原样保留配图', () {
      final Post post = buildPost(images: const <String>['a.jpg']);
      final Post liked = post.toggleLike();

      expect(liked.images, post.images);
      expect(liked.likeCount, 1);
      expect(liked.likedByMe, isTrue);
    });

    test('clearCover 能显式清掉占位封面', () {
      final Post post = buildPost(coverEmoji: '🌆');
      expect(post.hasCover, isTrue);

      // 用 copyWith(coverEmoji: null) 是清不掉的（null 表示"不改"），
      // 所以专门留了 clearCover 这个开关。
      expect(post.copyWith(coverEmoji: null).hasCover, isTrue);
      expect(post.copyWith(clearCover: true).hasCover, isFalse);
    });

    test('firstImage 取第一张，用于列表封面', () {
      final Post post = buildPost(images: const <String>['a.jpg', 'b.jpg']);
      expect(post.firstImage, 'a.jpg');
    });

    test('计数不会被减成负数', () {
      final Post post = buildPost(likeCount: 0, likedByMe: true);
      expect(post.toggleLike().likeCount, 0);
    });
  });

  group('Comment', () {
    test('toggleLike 正常加减', () {
      expect(buildComment(likeCount: 5).toggleLike().likeCount, 6);

      final Comment liked = buildComment(likeCount: 5, likedByMe: true);
      expect(liked.toggleLike().likeCount, 4);
      expect(liked.toggleLike().likedByMe, isFalse);
    });

    test('取消点赞时计数不会变成负数', () {
      // 乐观更新 + 失败回滚的组合下很容易减到 -1，
      // 那会在界面上显示成 "-1" 这种一眼是 bug 的东西。
      final Comment c = buildComment(likeCount: 0, likedByMe: true);
      expect(c.toggleLike().likeCount, 0);
    });

    test('postId 参与相等性判断', () {
      expect(buildComment(), isNot(buildComment().copyWith(postId: 'p_other')));
    });

    test('与 Post 的命名保持对称：likeCount / likedByMe', () {
      // 这不是废话断言 —— 它把"两个实体用同一套字段名"这个约定写进测试，
      // 将来谁把 Comment 改成 likesCount 会立刻失败。
      final Comment c = buildComment(likeCount: 3, likedByMe: true);
      expect(c.likeCount, 3);
      expect(c.likedByMe, isTrue);
    });
  });
}
