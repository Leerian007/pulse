/// 时间格式化。
///
/// 刻意**不引 intl**：现阶段只需要"几分钟前"这种相对时间和两个绝对格式，
/// 手写 30 行就够，也省掉一个会随 Flutter 版本被 pin 的依赖。
/// 真要做多语言 / 时区 / 12-24 小时制时，再换成 `intl` 的 `DateFormat`。
library;

/// 相对时间：刚刚 / 3 分钟前 / 2 小时前 / 5 天前 / 10月2日 / 2025年12月1日。
///
/// [now] 只用于测试注入，生产代码不传。
String formatRelativeTime(DateTime time, {DateTime? now}) {
  final DateTime reference = now ?? DateTime.now();
  final Duration diff = reference.difference(time);

  // 未来时间（客户端时钟偏移）也按"刚刚"处理，避免出现"-1 分钟前"。
  if (diff.inSeconds < 60) {
    return '刚刚';
  }
  if (diff.inMinutes < 60) {
    return '${diff.inMinutes} 分钟前';
  }
  if (diff.inHours < 24) {
    return '${diff.inHours} 小时前';
  }
  if (diff.inDays < 7) {
    return '${diff.inDays} 天前';
  }
  if (time.year == reference.year) {
    return '${time.month}月${time.day}日';
  }
  return '${time.year}年${time.month}月${time.day}日';
}

/// 时钟时间：`14:05`。用于聊天气泡右上角、会话列表右侧。
String formatClock(DateTime time, {bool use24Hour = true}) {
  final String hour = time.hour.toString().padLeft(2, '0');
  final String minute = time.minute.toString().padLeft(2, '0');
  if (use24Hour) {
    return '$hour:$minute';
  }
  final int h12 = time.hour % 12 == 0 ? 12 : time.hour % 12;
  final String suffix = time.hour < 12 ? 'AM' : 'PM';
  return '$h12:$minute $suffix';
}

/// 会话列表右侧的时间：今天显示时钟，昨天显示"昨天"，更早显示日期。
String formatConversationTime(DateTime time, {DateTime? now}) {
  final DateTime reference = now ?? DateTime.now();
  final DateTime today = DateTime(reference.year, reference.month, reference.day);
  final DateTime target = DateTime(time.year, time.month, time.day);
  final int dayGap = today.difference(target).inDays;

  if (dayGap <= 0) {
    return formatClock(time);
  }
  if (dayGap == 1) {
    return '昨天';
  }
  if (dayGap < 7) {
    return '星期${_weekdayNames[time.weekday - 1]}';
  }
  return '${time.month}/${time.day}';
}

/// 加入时间：`2026年10月加入`。个人主页用。
String formatJoinDate(DateTime time, {DateTime? now}) {
  final DateTime reference = now ?? DateTime.now();
  if (time.year == reference.year) {
    return '${time.month}月加入';
  }
  return '${time.year}年${time.month}月加入';
}

/// 大于 1000 时缩写为 `1.2万`，避免点赞数把一行撑爆。
String formatCount(int count) {
  if (count < 1000) {
    return '$count';
  }
  if (count < 10000) {
    final double value = count / 1000;
    return '${value.toStringAsFixed(value >= 10 ? 0 : 1)}k';
  }
  final double value = count / 10000;
  return '${value.toStringAsFixed(value >= 10 ? 0 : 1)}万';
}

const List<String> _weekdayNames = <String>['一', '二', '三', '四', '五', '六', '日'];
