import 'package:flutter/foundation.dart';

/// 用户资料。
@immutable
class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.handle,
    required this.bio,
    required this.joinedAt,
    this.emoji,
    this.location,
    this.postCount = 0,
    this.followingCount = 0,
    this.followerCount = 0,
    this.likesReceived = 0,
    this.isVerified = false,
  });

  final String id;

  final String name;

  final String handle;

  final String bio;

  /// 加入时间。展示时用 `formatJoinDate` 转成"2026年3月加入"。
  final DateTime joinedAt;

  final String? emoji;

  final String? location;

  final int postCount;

  final int followingCount;

  final int followerCount;

  /// 收到的总赞数。个人主页里这个数字通常比粉丝数更"有面子"，放在首位。
  final int likesReceived;

  final bool isVerified;

  UserProfile copyWith({
    String? id,
    String? name,
    String? handle,
    String? bio,
    DateTime? joinedAt,
    String? emoji,
    String? location,
    int? postCount,
    int? followingCount,
    int? followerCount,
    int? likesReceived,
    bool? isVerified,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      handle: handle ?? this.handle,
      bio: bio ?? this.bio,
      joinedAt: joinedAt ?? this.joinedAt,
      emoji: emoji ?? this.emoji,
      location: location ?? this.location,
      postCount: postCount ?? this.postCount,
      followingCount: followingCount ?? this.followingCount,
      followerCount: followerCount ?? this.followerCount,
      likesReceived: likesReceived ?? this.likesReceived,
      isVerified: isVerified ?? this.isVerified,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is UserProfile &&
        other.id == id &&
        other.name == name &&
        other.handle == handle &&
        other.bio == bio &&
        other.joinedAt == joinedAt &&
        other.emoji == emoji &&
        other.location == location &&
        other.postCount == postCount &&
        other.followingCount == followingCount &&
        other.followerCount == followerCount &&
        other.likesReceived == likesReceived &&
        other.isVerified == isVerified;
  }

  @override
  int get hashCode => Object.hash(
        id,
        name,
        handle,
        bio,
        joinedAt,
        emoji,
        location,
        postCount,
        followingCount,
        followerCount,
        likesReceived,
        isVerified,
      );

  @override
  String toString() => 'UserProfile($id, $name)';
}
