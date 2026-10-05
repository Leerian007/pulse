import '../../../../core/constants/app_constants.dart';
import '../../../../core/mock/mock_data_service.dart';
import '../../domain/repositories/photo_library.dart';

/// [PhotoLibrary] 的 Mock 实现：不打开相册，直接返回一批现成的图片地址。
///
/// ## 为什么每次"挑"出来的图都不一样
///
/// seed 里混进了 `DateTime.now().microsecondsSinceEpoch`。
/// 如果 seed 固定，连续点两次「添加图片」会拿到**同一批图**，
/// 预览条里出现两张一模一样的缩略图 —— 一眼就露馅。
///
/// ## 接真实相册时要改什么
///
/// 换成 `ImagePickerPhotoLibrary implements PhotoLibrary`：调 `image_picker`
/// 拿到本地临时文件，逐个上传，返回远端地址。**发帖面板一行都不用改** ——
/// 它看到的永远只是"一批能放进动态的图片地址"。
class MockPhotoLibrary implements PhotoLibrary {
  MockPhotoLibrary({Duration? latency})
      : _latency = latency ?? AppConstants.mockLatency;

  final Duration _latency;

  /// 一次"挑"几张。
  ///
  /// 真实相册里由用户决定，这里固定 3 张 —— 足以覆盖九宫格的
  /// 单图 / 两图 / 三图三种排布，又不会一次把预览条塞满。
  static const int _pickSize = 3;

  /// 序号，保证同一微秒内生成的 seed 也不重复。
  int _seq = 0;

  @override
  Future<List<String>> pickImages({required int maxCount}) async {
    // 模拟"打开相册 → 用户挑选 → 返回"的往返，让面板上的 loading 态
    // 在开发期就被真实覆盖到。
    await Future<void>.delayed(_latency);

    if (maxCount <= 0) {
      // 已经到九宫格上限了。返回空列表而不是抛异常 —— 这不是错误，只是没得挑。
      return const <String>[];
    }

    final int count = maxCount < _pickSize ? maxCount : _pickSize;
    final int batch = DateTime.now().microsecondsSinceEpoch;

    return List<String>.unmodifiable(<String>[
      for (int i = 0; i < count; i++)
        MockDataService.photoUrl(
          'upload_${batch}_${++_seq}_$i',
          // 一律按正方形出图：九宫格里的格子就是方的，
          // 让服务端先裁好，客户端不必再处理纵横比。
          width: 900,
          height: 900,
        ),
    ]);
  }
}
