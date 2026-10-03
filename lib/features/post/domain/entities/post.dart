import 'package:flutter/foundation.dart';

import 'author.dart';

/// 动态（社区的一条帖子）。
///
/// 这是 **domain 层的实体**：不含 JSON、不含数据库字段、不含任何外部框架的类型。
/// 数据层（`data/models/`）如果需要 DTO，就在那里单独定义并做转换 ——
/// 现阶段 Mock 直接用实体，所以省掉了 DTO 这一层。
@immutable
class Post {
  const Post({
    required this.id,
    required this.author,
    required this.content,
    required this.createdAt,
    this.coverEmoji,
    this.coverCaption,
    this.likeCount = 0,
    this.commentCount = 0,
    this.repostCount = 0,
    this.likedByMe = false,
    this.topics = const <String>[],
  });

  final String id;

  final Author author;

  final String content;

  final DateTime createdAt;

  /// 配图占位字符。为空表示纯文字动态。
  ///
  /// 之所以不直接放 URL：现阶段不引入任何图片资源，也让 Mock 数据保持纯文本、
  /// 便于测试断言。真实项目里换成 `coverUrl` 即可，`PostCard` 只需要改一个分支。
  final String? coverEmoji;

  /// 配图说明。
  final String? coverCaption;

  final int likeCount;

  final int commentCount;

  final int repostCount;

  /// 当前登录用户是否点过赞。**这是 UI 状态**，但放在实体上更省心：
  /// 否则列表渲染时要额外查一次"我点过哪些"，得不偿失。
  final bool likedByMe;

  /// 话题标签。
  final List<String> topics;

  bool get hasCover => coverEmoji != null;

  Post copyWith({
    String? id,
    Author? author,
    String? content,
    DateTime? createdAt,
    String? coverEmoji,
    bool clearCover = false,
    String? coverCaption,
    int? likeCount,
    int? commentCount,
    int? repostCount,
    bool? likedByMe,
    List<String>? topics,
  }) {
    return Post(
      id: id ?? this.id,
      author: author ?? this.author,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      coverEmoji: clearCover ? null : (coverEmoji ?? this.coverEmoji),
      coverCaption: clearCover ? null : (coverCaption ?? this.coverCaption),
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      repostCount: repostCount ?? this.repostCount,
      likedByMe: likedByMe ?? this.likedByMe,
      topics: topics ?? this.topics,
    );
  }

  /// 切换点赞状态，并同步维护计数。
  ///
  /// 计数不允许为负 —— 乐观更新 + 失败回滚的场景下很容易把它减成 -1。
  Post toggleLike() {
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
    return other is Post &&
        other.id == id &&
        other.author == author &&
        other.content == content &&
        other.createdAt == createdAt &&
        other.coverEmoji == coverEmoji &&
        other.coverCaption == coverCaption &&
        other.likeCount == likeCount &&
        other.commentCount == commentCount &&
        other.repostCount == repostCount &&
        other.likedByMe == likedByMe &&
        listEquals(other.topics, topics);
  }

  @override
  int get hashCode => Object.hash(
        id,
        author,
        content,
        createdAt,
        coverEmoji,
        coverCaption,
        likeCount,
        commentCount,
        repostCount,
        likedByMe,
        Object.hashAll(topics),
      );

  @override
  String toString() => 'Post($id, ${author.name}, like=$likeCount)';
}
