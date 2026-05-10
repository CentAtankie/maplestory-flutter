import 'package:flutter/material.dart';
import "../utils/maple_theme.dart";
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../game/models/quest.dart';
import '../game/models/player.dart';
import '../providers/game_provider.dart';

class QuestDialog extends ConsumerWidget {
  const QuestDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(gameProvider).player;
    final gameData = ref.watch(gameProvider);
    final quests = gameData.quests;
    final currentMapId = gameData.currentMap.id;

    // 可接取的任务
    final availableQuests = quests.where((q) => q.status == QuestStatus.available).toList();
    // 进行中的任务
    final activeQuests = quests.where((q) => q.status == QuestStatus.inProgress).toList();
    // 已完成未领取奖励的任务
    final completedQuests = quests.where((q) => q.status == QuestStatus.completed).toList();

    return DefaultTabController(
      length: 3,
      child: AlertDialog(
        backgroundColor: MapleColors.background,
        title: const Row(
          children: [
            Text('📜 任务', style: TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: SizedBox(
          width: 350,
          height: 450,
          child: Column(
            children: [
              const TabBar(
                tabs: [
                  Tab(text: '可接取'),
                  Tab(text: '进行中'),
                  Tab(text: '已完成'),
                ],
                labelColor: Colors.amber,
                unselectedLabelColor: Colors.white54,
                indicatorColor: Colors.amber,
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    // 可接取
                    _buildQuestList(
                      context, ref, player, currentMapId, availableQuests,
                      emptyText: '暂无可接取任务',
                      showAccept: true,
                    ),
                    // 进行中
                    _buildQuestList(
                      context, ref, player, currentMapId, activeQuests,
                      emptyText: '暂无进行中的任务',
                      showProgress: true,
                    ),
                    // 已完成
                    _buildQuestList(
                      context, ref, player, currentMapId, completedQuests,
                      emptyText: '暂无已完成任务',
                      showClaim: true,
                    ),
                  ],
                ),
              ),
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

  Widget _buildQuestList(
    BuildContext context,
    WidgetRef ref,
    Player player,
    String currentMapId,
    List<GameQuest> quests, {
    required String emptyText,
    bool showAccept = false,
    bool showProgress = false,
    bool showClaim = false,
  }) {
    if (quests.isEmpty) {
      return Center(
        child: Text(
          emptyText,
          style: const TextStyle(color: Colors.white54),
        ),
      );
    }

    return ListView.builder(
      itemCount: quests.length,
      itemBuilder: (context, index) {
        final quest = quests[index];
        return _buildQuestCard(context, ref, player, currentMapId, quest,
          showAccept: showAccept,
          showProgress: showProgress,
          showClaim: showClaim,
        );
      },
    );
  }

  Widget _buildQuestCard(
    BuildContext context,
    WidgetRef ref,
    Player player,
    String currentMapId,
    GameQuest quest, {
    bool showAccept = false,
    bool showProgress = false,
    bool showClaim = false,
  }) {
    Color typeColor;
    IconData typeIcon;
    switch (quest.type) {
      case QuestType.jobChange:
        typeColor = Colors.purple;
        typeIcon = Icons.workspace_premium;
        break;
      case QuestType.levelUp:
        typeColor = Colors.blue;
        typeIcon = Icons.trending_up;
        break;
      case QuestType.hunt:
        typeColor = Colors.red;
        typeIcon = Icons.pets;
        break;
      case QuestType.collect:
        typeColor = Colors.green;
        typeIcon = Icons.inventory_2;
        break;
    }

    return Card(
      color: MapleColors.card,
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(typeIcon, color: typeColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    quest.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (quest.type == QuestType.jobChange && quest.targetJob != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: quest.targetJob!.color.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: quest.targetJob!.color),
                    ),
                    child: Text(
                      quest.targetJob!.displayName,
                      style: TextStyle(
                        color: quest.targetJob!.color,
                        fontSize: 11,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            // 等级/职业要求
            Row(
              children: [
                _buildRequirementBadge(
                  '⭐ Lv.${quest.minLevel}',
                  player.stats.level >= quest.minLevel,
                ),
                if (quest.requiredJob != null) ...[
                  const SizedBox(width: 6),
                  _buildRequirementBadge(
                    '${quest.requiredJob!.emoji} ${quest.requiredJob!.displayName}',
                    player.job == quest.requiredJob,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Text(
              quest.description,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            // 奖励
            Row(
              children: [
                if (quest.rewards['meso'] != null) ...[
                  const Text('💰', style: TextStyle(fontSize: 12)),
                  Text(' ${quest.rewards['meso']}', style: const TextStyle(color: Colors.amber, fontSize: 12)),
                  const SizedBox(width: 12),
                ],
                if (quest.rewards['exp'] != null) ...[
                  const Text('✨', style: TextStyle(fontSize: 12)),
                  Text(' ${quest.rewards['exp']} EXP', style: const TextStyle(color: Colors.purple, fontSize: 12)),
                ],
              ],
            ),
            // 进度条
            if (showProgress && quest.targetCount > 0) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: quest.progressPercent,
                backgroundColor: Colors.grey[800],
                valueColor: const AlwaysStoppedAnimation(Colors.green),
              ),
              const SizedBox(height: 4),
              Text(
                '进度: ${quest.currentCount}/${quest.targetCount}',
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ],
            // 操作按钮
            if (showAccept || showClaim) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: showAccept
                      ? (quest.canAccept(player) ? () => _acceptQuest(context, ref, quest) : null)
                      : () => _claimReward(context, ref, quest),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: showAccept ? Colors.green : Colors.amber,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[700],
                  ),
                  child: Text(
                    showAccept
                        ? (quest.canAccept(player) ? '接受任务' : _whyCannotAccept(player, quest))
                        : '领取奖励',
                  ),
                ),
              ),
            ],
            // 转职/觉醒按钮
            if (quest.type == QuestType.jobChange &&
                quest.status == QuestStatus.inProgress &&
                quest.targetMapId == currentMapId) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (quest.id.startsWith('awaken_')) {
                      _completeAwakening(context, ref, quest);
                    } else {
                      _completeJobChange(context, ref, quest);
                    }
                  },
                  icon: Icon(
                    quest.id.startsWith('awaken_') ? Icons.auto_awesome : Icons.workspace_premium,
                  ),
                  label: Text(
                    quest.id.startsWith('awaken_') ? '完成觉醒' : '完成转职',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: quest.id.startsWith('awaken_') ? Colors.amber : Colors.purple,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _acceptQuest(BuildContext context, WidgetRef ref, GameQuest quest) {
    ref.read(gameProvider.notifier).acceptQuest(quest.id);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ 已接受任务: ${quest.title}'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _claimReward(BuildContext context, WidgetRef ref, GameQuest quest) {
    ref.read(gameProvider.notifier).claimQuestReward(quest.id);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🎁 已领取奖励: ${quest.title}'),
        backgroundColor: Colors.amber,
      ),
    );
  }

  void _completeJobChange(BuildContext context, WidgetRef ref, GameQuest quest) {
    if (quest.targetJob == null) return;

    ref.read(gameProvider.notifier).completeJobChange(quest.id, quest.targetJob!);
    Navigator.pop(context);

    // 显示转职成功对话框
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: MapleColors.background,
        title: Row(
          children: [
            Text(quest.targetJob!.emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 12),
            const Text('转职成功！', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '恭喜你成为 ${quest.targetJob!.displayName}！',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: quest.targetJob!.color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: quest.targetJob!.color),
              ),
              child: Text(
                '你获得了新的职业技能加成！',
                style: TextStyle(color: quest.targetJob!.color),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: quest.targetJob!.color,
              foregroundColor: Colors.white,
            ),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _completeAwakening(BuildContext context, WidgetRef ref, GameQuest quest) {
    final notifier = ref.read(gameProvider.notifier);
    final player = ref.read(gameProvider).player;

    // Check requirements
    if (player.stats.level < 70) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ 需要达到 Lv.70 才能觉醒'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (player.isAwakened) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ 已经觉醒过了'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Complete the quest first
    notifier.completeJobChange(quest.id, quest.targetJob!);

    // Then perform awakening
    notifier.awakenJob();

    Navigator.pop(context);

    // Show awakening success dialog
    final awakenedSkill = player.job.awakenedSkill;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: MapleColors.background,
        title: const Row(
          children: [
            Text('✨', style: TextStyle(fontSize: 32)),
            SizedBox(width: 12),
            Text('觉醒成功！', style: TextStyle(color: Colors.amber)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${player.job.displayName} 完成了最终觉醒！',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber),
              ),
              child: Column(
                children: [
                  const Text(
                    '觉醒属性提升',
                    style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '💪 全属性 +10\n❤️ MaxHP +200\n💧 MaxMP +100',
                    style: TextStyle(color: Colors.white70),
                  ),
                  if (awakenedSkill != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      '⚡ 觉醒技能: ${awakenedSkill.emoji} ${awakenedSkill.name}',
                      style: const TextStyle(color: Colors.amber),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
            ),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 等级/职业要求徽章 (满足:绿色;不满足:红色)
  Widget _buildRequirementBadge(String text, bool met) {
    final color = met ? Colors.green : Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.6)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  /// 给出无法接受的具体原因
  String _whyCannotAccept(Player player, GameQuest quest) {
    if (player.stats.level < quest.minLevel) {
      return '需要 Lv.${quest.minLevel}';
    }
    if (quest.requiredJob != null && player.job != quest.requiredJob) {
      return '需要 ${quest.requiredJob!.displayName}';
    }
    return '无法接受';
  }
}
