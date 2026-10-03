import 'package:flutter/widgets.dart';

/// 间距栅格。
///
/// Apple 的布局节奏本质上是 4pt 栅格的组合，但真正产生"iOS 感"的是
/// **16pt 的屏幕边距** 与 **留白 > 内容** 的克制。所以这里既给出
/// 原子级步长（xs/sm/md...），也给出语义化常量（screenH/cardInsets）。
abstract final class AppSpacing {
  // MARK: - 原子步长

  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 40;
  static const double giant = 56;

  // MARK: - 语义化间距

  /// 屏幕左右安全边距。iOS 列表的标准内缩就是 16pt。
  static const double screenH = 16;

  /// 卡片内边距。
  static const double cardPadding = 16;

  /// 列表项之间的呼吸感。
  static const double listGap = 12;

  /// 导航栏内容高度。
  static const double navBarHeight = 44;

  /// 底部 Tab Bar 的内容高度（**不含** Home Indicator 安全区）。
  ///
  /// 与 `CupertinoTabBar` 的默认 `height`（50）保持一致，
  /// `MainScaffold` 会把这个值注入页面底部安全区，见那里的注释。
  static const double tabBarHeight = 50;

  /// 内容最大宽度。桌面 / 平板上面防止一行文字拉得过长（65ch 左右最易读）。
  static const double maxContentWidth = 640;

  // MARK: - 常用组合

  static const EdgeInsets screenPadding = EdgeInsets.symmetric(horizontal: screenH);
  static const EdgeInsets cardInsets = EdgeInsets.all(cardPadding);
  static const EdgeInsets listItemInsets = EdgeInsets.symmetric(horizontal: screenH, vertical: md);
}

/// 圆角。
///
/// iOS 的圆角是"连续圆角"（squircle），Flutter 里没有原生支持，
/// 但把半径调大一点能在观感上逼近，而不是用 [BorderRadius] 的直角圆弧。
abstract final class AppRadius {
  static const double xs = 6;
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 18;
  static const double xl = 22;

  /// 卡片圆角。iOS 16 之后卡片趋近 20pt。
  static const double card = 20;

  /// 底部弹出面板圆角。
  static const double sheet = 28;

  /// 胶囊。
  static const double pill = 999;

  // MARK: - 预置 BorderRadius

  static const BorderRadius xsAll = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius cardAll = BorderRadius.all(Radius.circular(card));
  static const BorderRadius sheetTop = BorderRadius.vertical(top: Radius.circular(sheet));
  static const BorderRadius pillAll = BorderRadius.all(Radius.circular(pill));

  /// 聊天气泡的圆角：把靠近头像的那个角收小，做出"指向发送者"的暗示。
  static const BorderRadius bubbleMine = BorderRadius.only(
    topLeft: Radius.circular(lg),
    topRight: Radius.circular(lg),
    bottomLeft: Radius.circular(lg),
    bottomRight: Radius.circular(xs),
  );
  static const BorderRadius bubbleOther = BorderRadius.only(
    topLeft: Radius.circular(lg),
    topRight: Radius.circular(lg),
    bottomLeft: Radius.circular(xs),
    bottomRight: Radius.circular(lg),
  );
}

/// 动效时长与曲线。
///
/// 统一收口的意义在于：整套 App 的手感是"一致"的，而不是每个页面各写各的
/// 300ms。iOS 的手感偏好短时长 + easeOut 类曲线（起步快、收尾慢）。
abstract final class AppDuration {
  /// 按下反馈。必须极短，否则点击会"发黏"。
  static const Duration instant = Duration(milliseconds: 100);

  /// 常规交互（hover、颜色切换、图标状态）。
  static const Duration fast = Duration(milliseconds: 180);

  /// 页面内过渡（展开、位移）。
  static const Duration normal = Duration(milliseconds: 280);

  /// 较重的过渡（弹层、主题切换）。
  static const Duration slow = Duration(milliseconds: 420);

  /// 长按触发的水波纹 / 呼吸动效。
  static const Duration breathe = Duration(milliseconds: 1200);
}

abstract final class AppCurves {
  /// 默认曲线：起步快、收尾缓，iOS 最常见的缓动。
  static const Curve emphasized = Curves.easeOutCubic;

  static const Curve standard = Curves.easeOut;

  /// 轻微回弹，用于点赞、发送成功等"有情绪"的时刻。
  static const Curve spring = Curves.easeOutBack;

  /// 减速，用于滚动惯性。
  static const Curve decelerate = Curves.decelerate;
}
