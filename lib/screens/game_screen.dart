import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_provider.dart';
import '../game/models/map.dart';
import '../widgets/status_bar.dart';
import '../widgets/game_log.dart';
import '../widgets/action_panel.dart';
import 'battle_screen.dart';
import 'shop_screen.dart';

class GameScreen extends ConsumerWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Column(
          children: [
            // 状态栏
            const StatusBar(),
            
            // 地图信息
            _buildMapInfo(gameState),
            
            // 游戏日志区域
            const Expanded(
              child: GameLog(),
            ),
            
            // 操作面板
            const ActionPanel(),
          ],
        ),
      ),
    );
  }

  Widget _buildMapInfo(GameData gameState) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F3460),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF533483)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                gameState.currentMap.isTown ? Icons.home : Icons.terrain,
                color: gameState.currentMap.isTown 
                    ? Colors.green 
                    : Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                gameState.currentMap.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            gameState.currentMap.description,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          if (gameState.currentMap.mobs.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                const Text(
                  '👹 可能出现: ',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white54,
                  ),
                ),
                ...gameState.currentMap.mobs.map((mob) {
                  return Chip(
                    label: Text(
                      mob.displayName,
                      style: const TextStyle(fontSize: 10),
                    ),
                    backgroundColor: Colors.red.withOpacity(0.3),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                }),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// 游戏主界面包装器，处理状态切换
class GameScreenWrapper extends ConsumerWidget {
  const GameScreenWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameProvider);

    // 根据游戏状态显示不同界面
    switch (gameState.gameState) {
      case GameState.battling:
        return const BattleScreen();
      case GameState.shopping:
        return const ShopScreen();
      case GameState.gameOver:
        return _buildGameOverScreen(context, ref);
      default:
        return const GameScreen();
    }
  }

  Widget _buildGameOverScreen(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '💀',
              style: TextStyle(fontSize: 80),
            ),
            const SizedBox(height: 24),
            const Text(
              '游戏结束',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '你的冒险之旅暂时结束了...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                ref.read(gameProvider.notifier).restart();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('重新开始'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
