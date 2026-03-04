import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_provider.dart';
import '../game/models/player.dart';
import '../game/models/map.dart';

class ActionPanel extends ConsumerWidget {
  const ActionPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameProvider);
    final isTown = gameState.currentMap.isTown;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 方向按钮（十字键）
            _buildDirectionPad(context, ref, gameState),
            
            const SizedBox(height: 16),
            
            // 功能按钮
            _buildActionButtons(context, ref, isTown),
          ],
        ),
      ),
    );
  }

  Widget _buildDirectionPad(BuildContext context, WidgetRef ref, GameData gameState) {
    final exits = gameState.currentMap.exits;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 方向控制区
        Container(
          width: 160,
          height: 160,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 上
              Positioned(
                top: 0,
                child: _buildDirectionButton(
                  icon: Icons.arrow_upward,
                  label: exits['北'] != null ? '北' : '',
                  onPressed: exits['北'] != null 
                      ? () => ref.read(gameProvider.notifier).move('北')
                      : null,
                ),
              ),
              // 下
              Positioned(
                bottom: 0,
                child: _buildDirectionButton(
                  icon: Icons.arrow_downward,
                  label: exits['南'] != null ? '南' : '',
                  onPressed: exits['南'] != null 
                      ? () => ref.read(gameProvider.notifier).move('南')
                      : null,
                ),
              ),
              // 左
              Positioned(
                left: 0,
                child: _buildDirectionButton(
                  icon: Icons.arrow_back,
                  label: exits['西'] != null ? '西' : '',
                  onPressed: exits['西'] != null 
                      ? () => ref.read(gameProvider.notifier).move('西')
                      : null,
                ),
              ),
              // 右
              Positioned(
                right: 0,
                child: _buildDirectionButton(
                  icon: Icons.arrow_forward,
                  label: exits['东'] != null ? '东' : '',
                  onPressed: exits['东'] != null 
                      ? () => ref.read(gameProvider.notifier).move('东')
                      : null,
                ),
              ),
              // 中心（当前位置）
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF533483).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    '📍',
                    style: TextStyle(fontSize: 24),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDirectionButton({
    required IconData icon,
    required String label,
    VoidCallback? onPressed,
  }) {
    final isEnabled = onPressed != null;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: isEnabled 
                ? const Color(0xFF0F3460) 
                : Colors.grey[800],
            foregroundColor: isEnabled ? Colors.white : Colors.grey,
            padding: const EdgeInsets.all(12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: isEnabled ? 4 : 0,
          ),
          child: Icon(icon, size: 24),
        ),
        if (label.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isEnabled ? Colors.white70 : Colors.grey,
              fontSize: 10,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref, bool isTown) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // 狩猎/休息
        Expanded(
          child: _buildActionButton(
            icon: isTown ? Icons.hotel : Icons.sports_martial_arts,
            label: isTown ? '休息 (R)' : '探索',
            color: isTown ? Colors.green : Colors.orange,
            onPressed: () {
              if (isTown) {
                ref.read(gameProvider.notifier).rest();
              } else {
                // 探索会触发随机遭遇，由 move 处理
                ref.read(gameProvider.notifier).addLog('🔍 正在探索这片区域...');
              }
            },
          ),
        ),
        const SizedBox(width: 12),
        
        // 物品栏
        Expanded(
          child: _buildActionButton(
            icon: Icons.backpack,
            label: '物品',
            color: Colors.blue,
            onPressed: () {
              _showInventoryDialog(context, ref);
            },
          ),
        ),
        const SizedBox(width: 12),
        
        // 角色
        Expanded(
          child: _buildActionButton(
            icon: Icons.person,
            label: '角色',
            color: Colors.purple,
            onPressed: () {
              _showCharacterDialog(context, ref);
            },
          ),
        ),
        const SizedBox(width: 12),
        
        // 设置
        Expanded(
          child: _buildActionButton(
            icon: Icons.settings,
            label: '设置',
            color: Colors.grey,
            onPressed: () {
              _showSettingsDialog(context, ref);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.2),
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withOpacity(0.5)),
        ),
        elevation: 0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
  }

  void _showInventoryDialog(BuildContext context, WidgetRef ref) {
    final player = ref.read(gameProvider).player;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text(
          '🎒 物品栏',
          style: TextStyle(color: Colors.white),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: player.inventory.isEmpty
              ? const Center(
                  child: Text(
                    '背包是空的',
                    style: TextStyle(color: Colors.white54),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: player.inventory.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      leading: const Text('📦', style: TextStyle(fontSize: 20)),
                      title: Text(
                        player.inventory[index],
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  void _showCharacterDialog(BuildContext context, WidgetRef ref) {
    final player = ref.read(gameProvider).player;
    final stats = player.stats;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Text(
          '${player.job.emoji} 角色信息',
          style: const TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInfoRow('名字', player.name),
              _buildInfoRow('职业', player.job.displayName),
              _buildInfoRow('等级', 'Lv.${stats.level}'),
              const Divider(color: Colors.white24),
              _buildInfoRow('HP', '${stats.hp}/${stats.maxHp}'),
              _buildInfoRow('MP', '${stats.mp}/${stats.maxMp}'),
              _buildInfoRow('EXP', '${stats.exp}/${stats.maxExp}'),
              const Divider(color: Colors.white24),
              _buildInfoRow('力量', '${stats.str}'),
              _buildInfoRow('敏捷', '${stats.dex}'),
              _buildInfoRow('智力', '${stats.int}'),
              _buildInfoRow('运气', '${stats.luk}'),
              const Divider(color: Colors.white24),
              _buildInfoRow('攻击力', '${player.getAtk()}'),
              _buildInfoRow('防御力', '${player.getDef()}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text(
          '⚙️ 设置',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.save, color: Colors.white70),
              title: const Text(
                '保存游戏',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                // TODO: 实现存档功能
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('存档功能开发中...')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.refresh, color: Colors.white70),
              title: const Text(
                '重新开始',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: const Color(0xFF1A1A2E),
                    title: const Text(
                      '确认重新开始?',
                      style: TextStyle(color: Colors.white),
                    ),
                    content: const Text(
                      '当前进度将会丢失',
                      style: TextStyle(color: Colors.white70),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('取消'),
                      ),
                      TextButton(
                        onPressed: () {
                          ref.read(gameProvider.notifier).restart();
                          Navigator.pop(context);
                        },
                        child: const Text(
                          '确认',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }
}
