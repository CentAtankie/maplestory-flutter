import 'package:flutter/material.dart';
import "../utils/maple_theme.dart";
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_provider.dart';
import '../game/models/player.dart';
import '../game/models/quest.dart';
import '../widgets/mail_dialog.dart';
import '../widgets/character_dialog.dart';
import '../widgets/quest_dialog.dart';

class StatusBar extends ConsumerWidget {
  const StatusBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 细粒度订阅: player 变化才重建顶部信息和血条
    final player = ref.watch(gameProvider.select((g) => g.player));
    final stats = player.stats;

    // 邮件徽标只关心计数
    final unreadMails = ref.watch(
      gameProvider.select((g) => g.mails.where((m) => !m.isRead).length),
    );
    final unclaimedAttachments = ref.watch(
      gameProvider.select((g) => g.mails.where((m) => m.hasUnclaimedAttachments).length),
    );

    // 任务徽标只关心计数
    final availableQuestCount = ref.watch(
      gameProvider.select((g) => g.availableQuestCount),
    );
    final activeQuestCount = ref.watch(
      gameProvider.select((g) => g.activeQuestCount),
    );

    final hpPercent = stats.hp / stats.maxHp;
    final mpPercent = stats.mp / stats.maxMp;
    final expPercent = stats.exp / stats.maxExp;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: MapleColors.surface,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // 头部信息
            Row(
              children: [
                // 职业图标
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _getJobColor(player.job).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getJobColor(player.job),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _getJobEmoji(player.job),
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                
                // 名字和职业
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        player.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '${player.job.displayName} Lv.${stats.level}',
                        style: TextStyle(
                          fontSize: 14,
                          color: _getJobColor(player.job),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // 角色按钮
                IconButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => const CharacterDialog(),
                    );
                  },
                  icon: const Icon(
                    Icons.person,
                    color: Colors.white70,
                  ),
                ),
                
                // 任务按钮
                Stack(
                  children: [
                    IconButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => const QuestDialog(),
                        );
                      },
                      icon: const Icon(
                        Icons.assignment,
                        color: Colors.white70,
                      ),
                    ),
                    // 可接取或进行中任务标记
                    if (availableQuestCount > 0 || activeQuestCount > 0)
                      Positioned(
                        right: 4,
                        top: 4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: availableQuestCount > 0 ? Colors.green : Colors.orange,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${availableQuestCount > 0 ? availableQuestCount : activeQuestCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                
                // 邮件按钮
                Stack(
                  children: [
                    IconButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => const MailDialog(),
                        );
                      },
                      icon: const Icon(
                        Icons.email,
                        color: Colors.white70,
                      ),
                    ),
                    // 未读邮件标记
                    if (unreadMails > 0 || unclaimedAttachments > 0)
                      Positioned(
                        right: 4,
                        top: 4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: unclaimedAttachments > 0 ? Colors.red : Colors.blue,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${unreadMails > 0 ? unreadMails : unclaimedAttachments}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                
                // 金币
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.amber.withOpacity(0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('💰', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 4),
                      Text(
                        '${player.meso}',
                        style: const TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // HP 条
            _buildBar(
              label: 'HP',
              value: stats.hp,
              maxValue: stats.maxHp,
              percent: hpPercent,
              color: hpPercent > 0.5 ? Colors.green : 
                     hpPercent > 0.25 ? Colors.orange : Colors.red,
              icon: Icons.favorite,
            ),
            
            const SizedBox(height: 8),
            
            // MP 条
            _buildBar(
              label: 'MP',
              value: stats.mp,
              maxValue: stats.maxMp,
              percent: mpPercent,
              color: Colors.blue,
              icon: Icons.bolt,
            ),
            
            const SizedBox(height: 8),

            // EXP 条
            _buildBar(
              label: 'EXP',
              value: stats.exp,
              maxValue: stats.maxExp,
              percent: expPercent,
              color: Colors.purple,
              icon: Icons.star,
            ),
            const SizedBox(height: 8),
            // SP 显示
            Row(
              children: [
                SizedBox(
                  width: 50,
                  child: Row(
                    children: [
                      const Icon(Icons.auto_fix_high, color: Colors.cyan, size: 14),
                      const SizedBox(width: 4),
                      const Expanded(
                        child: Text(
                          'SP',
                          style: TextStyle(
                            color: Colors.cyan,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.visible,
                          softWrap: false,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${stats.sp}',
                  style: const TextStyle(
                    color: Colors.cyan,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '击杀怪物获得',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBar({
    required String label,
    required int value,
    required int maxValue,
    required double percent,
    required Color color,
    required IconData icon,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 50,
          child: Row(
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.visible,
                  softWrap: false,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: percent,
              backgroundColor: Colors.grey[800],
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 16,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 70,
          child: Text(
            '$value/$maxValue',
            style: TextStyle(
              color: color.withOpacity(0.8),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Color _getJobColor(Job job) {
    switch (job) {
      case Job.warrior:
        return Colors.red;
      case Job.magician:
        return Colors.blue;
      case Job.bowman:
        return Colors.green;
      case Job.thief:
        return Colors.purple;
      case Job.pirate:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getJobEmoji(Job job) {
    switch (job) {
      case Job.warrior:
        return '⚔️';
      case Job.magician:
        return '🔮';
      case Job.bowman:
        return '🏹';
      case Job.thief:
        return '🗡️';
      case Job.pirate:
        return '⚓';
      default:
        return '🙂';
    }
  }
}
