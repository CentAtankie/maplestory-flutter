import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_provider.dart';
import '../game/models/player.dart';
import '../game/models/potential.dart';
import 'cube_dialog.dart';

/// 角色面板对话框
class CharacterDialog extends ConsumerStatefulWidget {
  const CharacterDialog({super.key});

  @override
  ConsumerState<CharacterDialog> createState() => _CharacterDialogState();
}

class _CharacterDialogState extends ConsumerState<CharacterDialog> {
  @override
  Widget build(BuildContext context) {
    final player = ref.watch(gameProvider).player;

    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A2E),
      title: Row(
        children: [
          const Text(
            '👤 角色',
            style: TextStyle(color: Colors.white),
          ),
          const Spacer(),
          Text(
            '${player.job.displayName} Lv.${player.stats.level}',
            style: TextStyle(
              color: _getJobColor(player.job),
              fontSize: 14,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 500,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 角色信息
              _buildCharacterInfo(player),
              const SizedBox(height: 16),
              const Divider(color: Colors.white24),
              const SizedBox(height: 8),
              
              // 装备栏
              const Text(
                '⚔️ 已装备',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildEquipmentList(player),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('关闭'),
        ),
      ],
    );
  }

  /// 构建角色信息
  Widget _buildCharacterInfo(Player player) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F3460),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // 头像和名字
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: _getJobColor(player.job).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: _getJobColor(player.job),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    _getJobEmoji(player.job),
                    style: const TextStyle(fontSize: 32),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'AP: ${player.stats.ap}',
                      style: const TextStyle(
                        color: Colors.amber,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 属性
          _buildStatRow('💪 力量', player.stats.str, player.getStr()),
          _buildStatRow('🏃 敏捷', player.stats.dex, player.getDex()),
          _buildStatRow('🧠 智力', player.stats.intStat, player.getIntStat()),
          _buildStatRow('🍀 运气', player.stats.luk, player.getLuk()),
          const Divider(color: Colors.white24),
          _buildStatRow('⚔️ 攻击', 0, player.getAtk()),
          _buildStatRow('🛡️ 防御', 0, player.getDef()),
          _buildStatRow('💥 暴击', 0, player.getCritRate().toInt(), suffix: '%'),
          _buildStatRow('💨 闪避', 0, player.getAvoidRate().toInt(), suffix: '%'),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, int base, int total, {String suffix = ''}) {
    final isBuffed = total > base;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const Spacer(),
          if (base > 0) ...[
            Text(
              '$base',
              style: const TextStyle(color: Colors.white54, fontSize: 14),
            ),
            const Text(' → ', style: TextStyle(color: Colors.white54)),
          ],
          Text(
            '$total$suffix',
            style: TextStyle(
              color: isBuffed ? Colors.green : Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建装备列表
  Widget _buildEquipmentList(Player player) {
    final slots = [
      (EquipmentSlot.weapon, '🗡️', '武器'),
      (EquipmentSlot.helmet, '🪖', '头盔'),
      (EquipmentSlot.armor, '👕', '铠甲'),
      (EquipmentSlot.pants, '👖', '裤子'),
      (EquipmentSlot.shoes, '👢', '鞋子'),
      (EquipmentSlot.gloves, '🧤', '手套'),
      (EquipmentSlot.cape, '🧣', '披风'),
    ];

    return Column(
      children: slots.map((slot) {
        final equip = player.equipment[slot.$1];
        return _buildEquipmentSlot(slot.$1, slot.$2, slot.$3, equip);
      }).toList(),
    );
  }

  Widget _buildEquipmentSlot(EquipmentSlot slot, String emoji, String name, Equipment? equip) {
    return Card(
      color: equip != null ? const Color(0xFF533483) : const Color(0xFF0F3460),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Text(equip?.emoji ?? emoji, style: const TextStyle(fontSize: 24)),
        title: Text(
          equip?.name ?? '$name (未装备)',
          style: TextStyle(
            color: equip != null ? Colors.white : Colors.white54,
            fontWeight: equip != null ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: equip != null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    equip.stats,
                    style: TextStyle(
                      color: Colors.green.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                  if (equip.potential != null)
                    _buildPotentialPreview(equip.potential!),
                ],
              )
            : null,
        trailing: equip != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 详情按钮
                  IconButton(
                    onPressed: () => _showEquipmentDetail(equip),
                    icon: const Icon(Icons.info, color: Colors.blue),
                  ),
                  // 卸下按钮
                  ElevatedButton(
                    onPressed: () => _unequip(slot),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: const Text('卸下'),
                  ),
                ],
              )
            : null,
      ),
    );
  }

  /// 构建潜能预览
  Widget _buildPotentialPreview(EquipmentPotential potential) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: potential.grade.gradeColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: potential.grade.gradeColor.withOpacity(0.5)),
      ),
      child: Text(
        '${potential.grade.gradeName} ${potential.lines.length}条',
        style: TextStyle(
          color: potential.grade.gradeColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// 显示装备详情
  void _showEquipmentDetail(Equipment equip) {
    showDialog(
      context: context,
      builder: (context) => EquipmentDetailDialog(equipment: equip),
    );
  }

  /// 卸下装备
  void _unequip(EquipmentSlot slot) {
    final success = ref.read(gameProvider.notifier).unequipItem(slot);
    if (success) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📦 装备已卸下'),
          backgroundColor: Colors.green,
        ),
      );
    }
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

/// 装备详情对话框
class EquipmentDetailDialog extends StatelessWidget {
  final Equipment equipment;

  const EquipmentDetailDialog({
    super.key,
    required this.equipment,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A2E),
      title: Row(
        children: [
          Text(equipment.emoji ?? '⚔️', style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              equipment.name,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 基础属性
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F3460),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📊 基础属性',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildStatText('攻击力', equipment.atk),
                    _buildStatText('防御力', equipment.def),
                    _buildStatText('力量', equipment.str),
                    _buildStatText('敏捷', equipment.dex),
                    _buildStatText('智力', equipment.intBonus),
                    _buildStatText('运气', equipment.luk),
                    if (equipment.crit != null)
                      _buildStatText('暴击率', equipment.crit!, suffix: '%'),
                    if (equipment.avoid != null)
                      _buildStatText('闪避率', equipment.avoid!, suffix: '%'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // 潜能属性
              if (equipment.potential != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: equipment.potential!.grade.gradeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: equipment.potential!.grade.gradeColor.withOpacity(0.5),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '✨ ${equipment.potential!.grade.gradeName}潜能',
                            style: TextStyle(
                              color: equipment.potential!.grade.gradeColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...equipment.potential!.lines.map((line) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          '• ${line.description}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      )),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // 使用魔方按钮
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showCubeSelector(context);
                  },
                  icon: const Text('🎲'),
                  label: const Text('使用魔方重塑潜能'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('关闭'),
        ),
      ],
    );
  }

  Widget _buildStatText(String label, int value, {String suffix = ''}) {
    if (value == 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        '$label: +$value$suffix',
        style: const TextStyle(color: Colors.white70),
      ),
    );
  }

  void _showCubeSelector(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => CubeEquipmentSelector(initialEquipment: equipment),
    );
  }
}
