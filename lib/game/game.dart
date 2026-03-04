import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/game_state.dart';

/// 冒险岛游戏主类
class MapleStoryGame extends FlameGame {
  final WidgetRef ref;
  
  MapleStoryGame({required this.ref});
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // 设置游戏背景
    camera.viewfinder.anchor = Anchor.topLeft;
    
    // 添加背景组件
    add(BackgroundComponent());
    
    // 添加游戏逻辑更新器
    add(GameLogicUpdater(ref: ref));
  }
  
  @override
  void update(double dt) {
    super.update(dt);
  }
}

/// 背景组件
class BackgroundComponent extends Component with HasGameRef<MapleStoryGame> {
  @override
  void render(Canvas canvas) {
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF1a1a2e),
          Color(0xFF16213e),
          Color(0xFF0f3460),
        ],
      ).createShader(Rect.fromLTWH(0, 0, gameRef.size.x, gameRef.size.y));
    
    canvas.drawRect(
      Rect.fromLTWH(0, 0, gameRef.size.x, gameRef.size.y),
      paint,
    );
  }
}

/// 游戏逻辑更新器 - 负责同步 Flame 和 Riverpod 状态
class GameLogicUpdater extends Component with HasGameRef<MapleStoryGame> {
  final WidgetRef ref;
  
  GameLogicUpdater({required this.ref});
  
  @override
  void update(double dt) {
    // 可以在这里添加需要每帧更新的游戏逻辑
    // 比如粒子效果、动画等
  }
}
