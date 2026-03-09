import 'package:flutter/material.dart';
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
        backgroundColor: const Color(0xFF1A1A2E),
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
                      context, ref, player, availableQuests,
                      emptyText: '暂无可接取任务',
                      showAccept: true,
                    ),
                    // 进行中
                    _buildQuestList(
                      context, ref, player, activeQuests,
                      emptyText: '暂无进行中的任务',
                      showProgress: true,
                    ),
                    // 已完成
                    _buildQuestList(
                      context, ref, player, completedQuests,
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
        return _buildQuestCard(context, ref, player, quest, 
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
      color: const Color(0xFF0F3460),
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
                      ? () => _acceptQuest(context, ref, quest)
                      : () => _claimReward(context, ref, quest),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: showAccept ? Colors.green : Colors.amber,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(showAccept ? '接受任务' : '领取奖励'),
                ),
              ),
            ],
            // 转职按钮
            if (quest.type == QuestType.jobChange && 
                quest.status == QuestStatus.inProgress &&
                quest.targetMapId == currentMapId) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _completeJobChange(context, ref, quest),
                  icon: const Icon(Icons.workspace_premium),
                  label: const Text('完成转职'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
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
        backgroundColor: const Color(0xFF1A1A2E),
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
}
