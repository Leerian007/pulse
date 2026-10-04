import '../../../../core/mock/mock_data_service.dart';
import '../../domain/entities/user_profile.dart';

/// 当前登录用户的 Mock 资料。
UserProfile buildMockProfile({DateTime? now}) {
  final DateTime anchor = MockDataService.anchorNow(now: now);

  return UserProfile(
    id: 'u_me',
    name: '你',
    handle: 'pulse_me',
    // 一句"有信息量"的简介比"这个人很懒"更能在走查时体现排版效果。
    bio: '在做一些安静的东西。\n写代码、拍照、偶尔做饭。',
    joinedAt: DateTime(anchor.year, 3, 14),
    // 和 `mock_authors.currentUser` 用同一个 seed，
    // 保证「我」在动态流、评论、个人主页三处是同一张脸。
    avatarUrl: MockDataService.avatarUrl('u_me'),
    emoji: '🧊',
    location: '杭州',
    postCount: 128,
    followingCount: 86,
    followerCount: 1247,
    likesReceived: 5320,
  );
}
