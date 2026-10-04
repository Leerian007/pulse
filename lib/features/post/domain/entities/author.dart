import 'package:flutter/foundation.dart';

/// 动态作者。
///
/// 和 [Post] 一样是**不可变值对象**。
/// 注意这里刻意实现了 `==` / `hashCode`：Riverpod 3 统一用 `==` 过滤更新，
/// 值对象如果不实现 `==`，每次 `copyWith` 都会触发一次无意义的 rebuild。
@immutable
class Author {
  const Author({
    required this.id,
    required this.name,
    required this.handle,
    this.avatarUrl,
    this.bio,
    this.emoji,
    this.isVerified = false,
    this.isFollowing = false,
  });

  final String id;

  final String name;

  /// 不含 `@` 前缀，展示时再补。
  final String handle;

  /// 头像图片地址。
  ///
  /// 为 `null` 时回落到 [emoji] 的渐变占位（见 `AppAvatar`）。
  /// 保留两条路径而不是直接换成图片：图片要处理加载中 / 失败 / 占位三态，
  /// 而 Mock 阶段网络并不可靠，emoji 占位永远能渲染。
  final String? avatarUrl;

  /// 一句话简介。可空 —— 列表项里通常不展示，详情页才用。
  final String? bio;

  /// 头像字符（占位用，见 `AppAvatar`）。
  final String? emoji;

  /// 认证标记。
  final bool isVerified;

  /// 当前登录用户是否关注了 TA。
  ///
  /// 这是**关系状态**而非用户属性，严格说应该单独建模；放在这里是为了
  /// 避免列表渲染时再查一次"我关注了谁"—— 和 `Post.likedByMe` 同一个取舍。
  final bool isFollowing;

  /// 是否有真实头像可加载。UI 用这个决定走 `Image.network` 还是渐变占位。
  bool get hasAvatar => avatarUrl != null && avatarUrl!.isNotEmpty;

  Author copyWith({
    String? id,
    String? name,
    String? handle,
    String? avatarUrl,
    String? bio,
    String? emoji,
    bool? isVerified,
    bool? isFollowing,
  }) {
    return Author(
      id: id ?? this.id,
      name: name ?? this.name,
      handle: handle ?? this.handle,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      emoji: emoji ?? this.emoji,
      isVerified: isVerified ?? this.isVerified,
      isFollowing: isFollowing ?? this.isFollowing,
    );
  }

  /// 切换关注状态。和 `Post.toggleLike()` 一样，是纯粹的本地状态翻转。
  Author toggleFollow() => copyWith(isFollowing: !isFollowing);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is Author &&
        other.id == id &&
        other.name == name &&
        other.handle == handle &&
        other.avatarUrl == avatarUrl &&
        other.bio == bio &&
        other.emoji == emoji &&
        other.isVerified == isVerified &&
        other.isFollowing == isFollowing;
  }

  @override
  int get hashCode => Object.hash(
        id,
        name,
        handle,
        avatarUrl,
        bio,
        emoji,
        isVerified,
        isFollowing,
      );

  @override
  String toString() =>
      'Author($id, $name, following=$isFollowing, avatar=${hasAvatar ? "yes" : "no"})';
}
