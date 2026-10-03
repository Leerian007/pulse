import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../mock/mock_profile.dart';

/// [ProfileRepository] 的内存实现。
class MockProfileRepository implements ProfileRepository {
  MockProfileRepository({Duration? latency})
      : _latency = latency ?? AppConstants.mockLatency;

  final Duration _latency;

  late UserProfile _profile = buildMockProfile();

  @override
  Future<UserProfile> fetchProfile() async {
    await _delay();
    return _profile;
  }

  @override
  Future<UserProfile> updateBio(String bio) async {
    await _delay();
    _profile = _profile.copyWith(bio: bio.trim());
    return _profile;
  }

  Future<void> _delay() => Future<void>.delayed(_latency);
}
