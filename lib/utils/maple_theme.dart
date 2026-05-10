import 'package:flutter/material.dart';

/// 全局主题色板。所有界面/弹窗背景色统一从这里取,避免散落在各文件
class MapleColors {
  MapleColors._();

  /// 最暗背景色,用作 Scaffold/AlertDialog 底色
  static const Color background = Color(0xFF1A1A2E);

  /// 比 background 稍亮的表面色,用于状态栏/卡片
  static const Color surface = Color(0xFF16213E);

  /// 卡片/分组容器背景
  static const Color card = Color(0xFF0F3460);

  /// 强调色 (紫色),用于按钮/边框/选中态
  static const Color accent = Color(0xFF533483);

  /// 半透明分隔线
  static const Color divider = Colors.white24;
}
