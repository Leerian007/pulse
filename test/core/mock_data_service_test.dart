import 'package:flutter_test/flutter_test.dart';
import 'package:learning_flutter/core/mock/mock_data_service.dart';

/// `MockDataService` 的测试。
///
/// 这个类只做三件小事（拼 URL、生成 id、给时间锚点），但它是**全站 Mock
/// 数据的唯一入口**：URL 方案要换（Picsum → 自建图床）、id 策略要改，
/// 都只动这一个文件。所以它的输出形态值得被固定下来。
void main() {
  group('avatarUrl', () {
    test('默认 200x200，seed 原样入 URL', () {
      expect(
        MockDataService.avatarUrl('u_lin'),
        'https://picsum.photos/seed/u_lin/200/200',
      );
    });

    test('size 同时作用于宽高，保证是正方形', () {
      expect(
        MockDataService.avatarUrl('u_lin', size: 80),
        'https://picsum.photos/seed/u_lin/80/80',
      );
    });

    test('同一个 seed 永远得到同一个 URL', () {
      // 这是选用 Picsum 的 `seed` 而不是 `random` 的全部理由：
      // 否则每次 rebuild 都换一张头像，界面会"闪"。
      expect(
        MockDataService.avatarUrl('u_mu'),
        MockDataService.avatarUrl('u_mu'),
      );
      expect(
        MockDataService.avatarUrl('u_mu'),
        isNot(MockDataService.avatarUrl('u_mu_2')),
      );
    });
  });

  group('photoUrl', () {
    test('默认 800x600', () {
      expect(
        MockDataService.photoUrl('p_001_a'),
        'https://picsum.photos/seed/p_001_a/800/600',
      );
    });

    test('宽高可分别指定，用于方图和竖图', () {
      expect(
        MockDataService.photoUrl('p_006_a', width: 600, height: 600),
        'https://picsum.photos/seed/p_006_a/600/600',
      );
      expect(
        MockDataService.photoUrl('p_010_a', width: 600, height: 900),
        'https://picsum.photos/seed/p_010_a/600/900',
      );
    });
  });

  group('seed 归一化', () {
    test('URL 里的保留字符被替换成连字符', () {
      // Picsum 会把 seed 里的 `/`、`?`、`#` 当路径 / 查询分隔符解析，
      // 于是拼出来的 URL 指向一张不存在的图 —— 不报错，只是碎图。
      expect(
        MockDataService.avatarUrl('a b/c?d#e'),
        'https://picsum.photos/seed/a-b-c-d-e/200/200',
      );
    });

    test('连字符和下划线是合法字符，保持原样', () {
      expect(
        MockDataService.avatarUrl('p_001-cover'),
        'https://picsum.photos/seed/p_001-cover/200/200',
      );
    });
  });

  group('localId', () {
    test('带上前缀，便于在日志里区分实体类型', () {
      final String id = MockDataService.localId('c', seq: 1);
      expect(id, startsWith('c_local_'));
    });

    test('序号不同则 id 不同', () {
      // 时间戳 + 序号双保险：同一微秒内连续发两条也不会撞。
      final String a = MockDataService.localId('c', seq: 1);
      final String b = MockDataService.localId('c', seq: 2);
      expect(a, isNot(b));
    });

    test('id 里带得进"本地未同步"的语义', () {
      // 换真实后端时，靠 `_local_` 这个片段可以把还没落库的乐观数据认出来。
      expect(MockDataService.localId('m', seq: 1), contains('_local_'));
    });
  });

  group('anchorNow', () {
    test('不传参数时取当前时间', () {
      final DateTime before = DateTime.now();
      final DateTime anchor = MockDataService.anchorNow();
      final DateTime after = DateTime.now();

      expect(anchor.isBefore(before), isFalse);
      expect(anchor.isAfter(after), isFalse);
    });

    test('传入固定时间时原样返回，让测试能断言确定结果', () {
      final DateTime fixed = DateTime(2026, 10, 4, 12);
      expect(MockDataService.anchorNow(now: fixed), fixed);
    });
  });
}
