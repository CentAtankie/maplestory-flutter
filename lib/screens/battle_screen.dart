import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_provider.dart';
import '../widgets/status_bar.dart';
import '../widgets/game_log.dart';

class BattleScreen extends ConsumerWidget {
  const BattleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameProvider);
    final mob = gameState.currentMob!;

    return Scaffold(
      backgroundColor: const Color(0xFF2D1B1B),
      body: SafeArea(
        child: Column(
          children: [
            // 状态栏
            const StatusBar(),
            
            // 战斗标题
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.5)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.warning, color: Colors.red),
                  SizedBox(width: 8),
                  Text(
                    '⚔️ 战斗中',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ),
            
            // 敌人信息
            _buildEnemyInfo(mob),
            
            // 游戏日志
            const Expanded(
              child: GameLog(),
            ),
            
            // 战斗操作按钮
            _buildBattleActions(context, ref, gameState),
          ],
        ),
      ),
    );
  }

  Widget _buildEnemyInfo(Mob mob) {
    final hpPercent = mob.hp / mob.maxHp;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Text(
            mob.emoji,
            style: const TextStyle(fontSize: 48),
          ),
          const SizedBox(height: 8),
          Text(
            '${mob.name} Lv.${mob.level}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          // HP 条
          Row(
            children: [
              const Text(
                'HP: ',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: hpPercent,
                    backgroundColor: Colors.grey[800],
                    valueColor: AlwaysStoppedAnimation(
                      hpPercent > 0.5 ? Colors.green : 
                      hpPercent > 0.25 ? Colors.orange : Colors.red,
                    ),
                    minHeight: 20,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${mob.hp}/${mob.maxHp}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 属性
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStatBadge('⚔️ ${mob.atk}', Colors.orange),
              const SizedBox(width: 16),
              _buildStatBadge('🛡️ ${mob.def}', Colors.blue),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildBattleActions(BuildContext context, WidgetRef ref, GameData gameState) {
    final player = gameState.player;
    final canUseSkill = player.stats.mp >= 5;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F3460),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.sports_martial_arts,
                    label: '普通攻击',
                    color: Colors.red,
                    onPressed: () {
                      ref.read(gameProvider.notifier).attack();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.auto_fix_high,
                    label: '技能攻击',
                    color: canUseSkill ? Colors.purple : Colors.grey,
                    subLabel: canUseSkill ? '消耗 5 MP' : 'MP 不足',
                    onPressed: canUseSkill 
                        ? () => ref.read(gameProvider.notifier).useSkill()
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.run_circle,
                    label: '逃跑',
                    color: Colors.orange,
                    onPressed: () {
                      ref.read(gameProvider.notifier).flee();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.info,
                    label: '查看状态',
                    color: Colors.blue,
                    onPressed: () {
                      _showStatusDialog(context, player);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    String? subLabel,
    required Color color,
    VoidCallback? onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        disabledBackgroundColor: Colors.grey[700],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 28),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (subLabel != null) ...[
            const SizedBox(height: 2),
            Text(
              subLabel,
              style: TextStyle(
                fontSize: 10,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showStatusDialog(BuildContext context, Player player) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text(
          '角色状态',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusRow('等级', 'Lv.${player.stats.level}'),
            _buildStatusRow('HP', '${player.stats.hp}/${player.stats.maxHp}'),
            _buildStatusRow('MP', '${player.stats.mp}/${player.stats.maxMp}'),
            _buildStatusRow('EXP', '${player.stats.exp}/${player.stats.maxExp}'),
            const Divider(color: Colors.white24),
            _buildStatusRow('力量', '${player.stats.str}'),
            _buildStatusRow('敏捷', '${player.stats.dex}'),
            _buildStatusRow('智力', '${player.stats.int}'),
            _buildStatusRow('运气', '${player.stats.luk}'),
            const Divider(color: Colors.white24),
            _buildStatusRow('攻击力', '${player.getAtk()}'),
            _buildStatusRow('防御力', '${player.getDef()}'),
            const Divider(color: Colors.white24),
            _buildStatusRow('金币', '${player.meso} 💰'),
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

  Widget _buildStatusRow(String label, String value) {
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
}
