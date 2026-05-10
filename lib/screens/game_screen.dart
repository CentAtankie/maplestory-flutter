import 'package:flutter/material.dart';
import "../utils/maple_theme.dart";
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_provider.dart';
import '../game/models/map.dart';
import '../utils/version.dart';
import '../widgets/status_bar.dart';
import '../widgets/game_log.dart';
import '../widgets/action_panel.dart';
import 'battle_screen.dart';
import 'shop_screen.dart';
import 'create_character_screen.dart';

class GameScreen extends ConsumerWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 只关心当前地图,其他状态变化不触发重建
    final currentMap = ref.watch(gameProvider.select((g) => g.currentMap));

    return Scaffold(
      backgroundColor: MapleColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // 可滚动的内容区域
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 状态栏
                          const StatusBar(),

                          // 地图信息
                          _buildMapInfo(currentMap),

                          // 游戏日志区域
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 12),
                            height: 180,
                            child: const GameLog(),
                          ),

                          // 操作面板
                          const ActionPanel(),

                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // 版本号显示在底部
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                'v$appVersion',
                style: const TextStyle(
                  color: Colors.white30,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapInfo(GameMap currentMap) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MapleColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MapleColors.accent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                currentMap.isTown ? Icons.home : Icons.terrain,
                color: currentMap.isTown
                    ? Colors.green
                    : Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                currentMap.name,
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
            currentMap.description,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          if (currentMap.mobs.isNotEmpty) ...[
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
                ...currentMap.mobs.map((mob) {
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

// 游戏主界面包装器，处理状态切换和首次进入游戏
class GameScreenWrapper extends ConsumerStatefulWidget {
  const GameScreenWrapper({super.key});

  @override
  ConsumerState<GameScreenWrapper> createState() => _GameScreenWrapperState();
}

class _GameScreenWrapperState extends ConsumerState<GameScreenWrapper> {
  bool _hasCheckedSave = false;
  bool _hasSave = false;

  @override
  void initState() {
    super.initState();
    _checkSave();
  }

  Future<void> _checkSave() async {
    final hasSave = await ref.read(gameProvider.notifier).hasSave();
    setState(() {
      _hasCheckedSave = true;
      _hasSave = hasSave;
    });
    
    // 如果没有存档，显示创建角色界面
    if (!hasSave && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const CreateCharacterScreen(
              playerName: '冒险家',
            ),
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 等待检查完成
    if (!_hasCheckedSave) {
      return const Scaffold(
        backgroundColor: MapleColors.background,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final currentGameState = ref.watch(gameProvider.select((g) => g.gameState));

    // 根据游戏状态显示不同界面
    switch (currentGameState) {
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
      backgroundColor: MapleColors.background,
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
