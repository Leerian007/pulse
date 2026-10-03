import '../entities/user_profile.dart';

/// 用户资料仓库接口（domain 层）。
///
/// 刻意做得很窄：现阶段只需要"读 + 改简介"。
/// 真实项目里会拆成 `ProfileRepository`（读）与 `ProfileEditor`（写），
/// 因为两者的失效策略完全不同 —— 但这个阶段拆开只是徒增文件。
abstract interface class ProfileRepository {
  /// 读取当前登录用户的资料。
  Future<UserProfile> fetchProfile();

  /// 更新简介，返回更新后的资料。
  Future<UserProfile> updateBio(String bio);
}
