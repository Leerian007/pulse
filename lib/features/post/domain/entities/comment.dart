import 'package:flutter/foundation.dart';

import 'author.dart';

/// 一条评论。
///
/// ## 为什么放在 `features/post/` 而不是新开一个 feature
///
/// 评论的唯一作用域就是动态，且必须复用 [Author]。独立成
/// `features/comment/` 的话，`comment` 的 domain 就要 import `post` 的
/// `Author` —— 而分层规则要求 feature 之间互不依赖，
/// 只能把这个类型再往上提一层，白白多一层间接。
/// 放在 post 里，"动态 + 评论"是一个内聚的业务单元。
///
/// ## 与 `Post` 的对称性
///
/// [likeCount] / [likedByMe] 的命名和 `Post` 保持一致（注意是 `likeCount`
/// 而不是 `likesCount`），[toggleLike] 也是同样的纯本地翻转语义 ——
/// 这样两个实体的用法可以互相类推，不需要记两套名字。
@immutable
class Comment {
  const Comment({
    required this.id,
    required this.postId,
    required this.author,
    required this.content,
    required this.createdAt,
    this.likeCount = 0,
    this.likedByMe = false,
  });

  final String id;

  /// 所属动态的 id。评论永远挂在某条动态下，所以是 `required`。
  final String postId;

  final Author author;

  final String content;

  final DateTime createdAt;

  final int likeCount;

  /// 当前登录用户是否点过赞。理由同 `Post.likedByMe`：
  /// 放在实体上可以省掉列表渲染时的额外查询。
  final bool likedByMe;

  Comment copyWith({
    String? id,
    String? postId,
    Author? author,
    String? content,
    DateTime? createdAt,
    int? likeCount,
    bool? likedByMe,
  }) {
    return Comment(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      author: author ?? this.author,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      likeCount: likeCount ?? this.likeCount,
      likedByMe: likedByMe ?? this.likedByMe,
    );
  }

  /// 切换点赞，并同步维护计数。
  ///
  /// 和 `Post.toggleLike()` 一样做了下限保护：计数不允许为负 ——
  /// 乐观更新 + 失败回滚的组合下很容易把它减成 -1。
  Comment toggleLike() {
    final int next = likedByMe ? likeCount - 1 : likeCount + 1;
    return copyWith(
      likedByMe: !likedByMe,
      likeCount: next < 0 ? 0 : next,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is Comment &&
        other.id == id &&
        other.postId == postId &&
        other.author == author &&
        other.content == content &&
        other.createdAt == createdAt &&
        other.likeCount == likeCount &&
        other.likedByMe == likedByMe;
  }

  @override
  int get hashCode => Object.hash(
        id,
        postId,
        author,
        content,
        createdAt,
        likeCount,
        likedByMe,
      );

  @override
  String toString() =>
      'Comment($id, post=$postId, by=${author.name}, like=$likeCount)';
}
