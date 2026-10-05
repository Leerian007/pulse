import 'package:flutter_test/flutter_test.dart';
import 'package:learning_flutter/features/post/data/repositories/mock_photo_library.dart';

/// `MockPhotoLibrary` 的测试。
///
/// 它实现的是 `PhotoLibrary` 这条契约，所以下面这些断言在换成
/// `ImagePickerPhotoLibrary` 之后**可以原样复用** —— 这才是有意义的测试。
void main() {
  /// 延迟归零，避免每个用例白等 500ms。
  MockPhotoLibrary build() => MockPhotoLibrary(latency: Duration.zero);

  test('默认一次挑 3 张，全部是合法的 picsum 地址', () async {
    final List<String> urls = await build().pickImages(maxCount: 9);

    expect(urls, hasLength(3));
    for (final String url in urls) {
      expect(url, startsWith('https://picsum.photos/seed/'));
    }
  });

  test('尊重 maxCount 上限', () async {
    expect(await build().pickImages(maxCount: 2), hasLength(2));
    expect(await build().pickImages(maxCount: 1), hasLength(1));
    expect(await build().pickImages(maxCount: 9), hasLength(3));
  });

  test('maxCount <= 0 时返回空列表，而不是抛异常', () async {
    // 已到九宫格上限不是错误，只是"没得挑了"。
    // 抛异常会逼着每个调用点写 try/catch，还容易误报成"选图失败"。
    expect(await build().pickImages(maxCount: 0), isEmpty);
    expect(await build().pickImages(maxCount: -3), isEmpty);
  });

  test('两次挑选拿到的是不同的图', () async {
    // 回归护栏：seed 如果写死，连续点两次「添加图片」会在预览条里
    // 出现两张一模一样的缩略图 —— 一眼就看得出来是假的。
    final MockPhotoLibrary library = build();

    final List<String> first = await library.pickImages(maxCount: 3);
    final List<String> second = await library.pickImages(maxCount: 3);

    expect(first.toSet().intersection(second.toSet()), isEmpty);
  });

  test('同一批里也不会重复', () async {
    final List<String> urls = await build().pickImages(maxCount: 9);
    expect(urls.toSet(), hasLength(urls.length));
  });

  test('返回的列表是不可变视图', () async {
    final List<String> urls = await build().pickImages(maxCount: 3);
    expect(() => urls.add('x'), throwsUnsupportedError);
  });

  test('出图是正方形的（九宫格的格子就是方的）', () async {
    final List<String> urls = await build().pickImages(maxCount: 1);
    expect(urls.single, endsWith('/900/900'));
  });
}
