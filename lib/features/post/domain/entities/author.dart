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
    this.emoji,
    this.isVerified = false,
  });

  final String id;

  final String name;

  /// 不含 `@` 前缀，展示时再补。
  final String handle;

  /// 头像字符（占位用，见 `AppAvatar`）。
  final String? emoji;

  /// 认证标记。
  final bool isVerified;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is Author &&
        other.id == id &&
        other.name == name &&
        other.handle == handle &&
        other.emoji == emoji &&
        other.isVerified == isVerified;
  }

  @override
  int get hashCode => Object.hash(id, name, handle, emoji, isVerified);

  @override
  String toString() => 'Author($id, $name)';
}
