import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/mock_profile_repository.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';

/// 用户资料仓库的注入点。
final Provider<ProfileRepository> profileRepositoryProvider =
    Provider<ProfileRepository>((ref) => MockProfileRepository());

/// 当前登录用户的资料。
class ProfileNotifier extends AsyncNotifier<UserProfile> {
  @override
  Future<UserProfile> build() {
    return ref.read(profileRepositoryProvider).fetchProfile();
  }

  Future<void> refresh() async {
    final AsyncValue<UserProfile> next = await AsyncValue.guard<UserProfile>(
      () => ref.read(profileRepositoryProvider).fetchProfile(),
    );
    if (!ref.mounted) {
      return;
    }
    state = next;
  }

  /// 更新简介。
  ///
  /// 这里的策略和"点赞""发消息"不同：**不做乐观更新**。
  /// 原因是写简介是一个"提交表单"的心智模型，用户预期是"按下保存 → 等一下 → 成功"，
  /// 而不是"立刻生效"。对表单类写入做乐观更新反而会让人怀疑到底存没存上。
  Future<bool> updateBio(String bio) async {
    final String trimmed = bio.trim();
    if (trimmed.isEmpty) {
      return false;
    }
    try {
      final UserProfile updated =
          await ref.read(profileRepositoryProvider).updateBio(trimmed);

      // Riverpod 3：await 之后必须确认 provider 还活着，
      // 否则写 state 会抛 UnmountedRefException。
      if (!ref.mounted) {
        return true;
      }

      state = AsyncData<UserProfile>(updated);
      return true;
    } catch (_) {
      return false;
    }
  }
}

/// 当前登录用户的资料。
final AsyncNotifierProvider<ProfileNotifier, UserProfile> profileProvider =
    AsyncNotifierProvider<ProfileNotifier, UserProfile>(ProfileNotifier.new);
