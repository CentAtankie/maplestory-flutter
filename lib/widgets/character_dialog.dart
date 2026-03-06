import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_provider.dart';
import '../game/models/player.dart';
import '../game/models/potential.dart';
import 'cube_dialog.dart';

class CharacterDialog extends ConsumerStatefulWidget {
  const CharacterDialog({super.key});

  @override
  ConsumerState<CharacterDialog> createState() => _CharacterDialogState();
}

class _CharacterDialogState extends ConsumerState<CharacterDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A2E),
      title: Row(
        children: [
          const Text('👤 角色', style: TextStyle(color: Colors.white)),
          const Spacer(),
          // 使用 Consumer 监听等级变化
          Consumer(
            builder: (context, ref, child) {
              final player = ref.watch(gameProvider).player;
              return Text('${player.job.displayName} Lv.${player.stats.level}', 
                   style: TextStyle(color: _getJobColor(player.job), fontSize: 14));
            }
          ),
        ],
      ),
      content: SizedBox(
        width: 350,
        height: 500,
        child: StatefulBuilder(
          builder: (context, setDialogState) {
            // 每次重建都获取最新 player
            final player = ref.watch(gameProvider).player;
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCharacterInfo(player),
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 8),
                  const Text('⚔️ 已装备', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildEquipmentList(player, setDialogState),
                ],
              ),
            );
          }
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('关闭'))],
    );
  }

  Widget _buildCharacterInfo(Player player) {
    // 计算装备加成
    final equipStr = player.equipment.values.where((e) => e != null).fold(0, (s, e) => s + (e!.str));
    final equipDex = player.equipment.values.where((e) => e != null).fold(0, (s, e) => s + (e!.dex));
    final equipInt = player.equipment.values.where((e) => e != null).fold(0, (s, e) => s + (e!.intBonus));
    final equipLuk = player.equipment.values.where((e) => e != null).fold(0, (s, e) => s + (e!.luk));
    
    // 计算总属性
    final totalStr = player.stats.str + equipStr;
    final totalDex = player.stats.dex + equipDex;
    final totalInt = player.stats.intStat + equipInt;
    final totalLuk = player.stats.luk + equipLuk;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF0F3460), borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  color: _getJobColor(player.job).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: _getJobColor(player.job), width: 2),
                ),
                child: Center(child: Text(_getJobEmoji(player.job), style: const TextStyle(fontSize: 32))),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(player.name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    Text('AP: ${player.stats.ap}', style: const TextStyle(color: Colors.amber, fontSize: 14)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildStatRow('💪 力量', player.stats.str, equipStr, totalStr),
          _buildStatRow('🏃 敏捷', player.stats.dex, equipDex, totalDex),
          _buildStatRow('🧠 智力', player.stats.intStat, equipInt, totalInt),
          _buildStatRow('🍀 运气', player.stats.luk, equipLuk, totalLuk),
          const Divider(color: Colors.white24),
          _buildSimpleStatRow('⚔️ 攻击', player.getAtk()),
          _buildSimpleStatRow('🛡️ 防御', player.getDef()),
          _buildSimpleStatRow('💥 暴击', player.getCritRate().toInt(), suffix: '%'),
          _buildSimpleStatRow('💨 闪避', player.getAvoidRate().toInt(), suffix: '%'),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, int base, int equipBonus, int total) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const Spacer(),
          if (equipBonus > 0)
            Text('$base', style: const TextStyle(color: Colors.white54, fontSize: 14)),
          if (equipBonus > 0)
            Text(' +$equipBonus', style: const TextStyle(color: Colors.green, fontSize: 14)),
          if (equipBonus > 0)
            const Text(' = ', style: TextStyle(color: Colors.white54)),
          Text('$total', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSimpleStatRow(String label, int value, {String suffix = ''}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const Spacer(),
          Text('$value$suffix', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildEquipmentList(Player player, StateSetter setDialogState) {
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
        return _buildEquipmentSlot(slot.$1, slot.$2, slot.$3, equip, setDialogState);
      }).toList(),
    );
  }

  Widget _buildEquipmentSlot(EquipmentSlot slot, String emoji, String name, Equipment? equip, StateSetter setDialogState) {
    return Card(
      color: equip != null ? const Color(0xFF533483) : const Color(0xFF0F3460),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Text(equip?.emoji ?? emoji, style: const TextStyle(fontSize: 24)),
        title: Text(equip?.name ?? '$name (未装备)', 
          style: TextStyle(color: equip != null ? Colors.white : Colors.white54, 
                          fontWeight: equip != null ? FontWeight.bold : FontWeight.normal)),
        subtitle: equip != null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(equip.stats, style: TextStyle(color: Colors.green.withOpacity(0.8), fontSize: 12)),
                  if (equip.potential != null) _buildPotentialPreview(equip.potential!),
                ],
              )
            : null,
        trailing: equip != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () => _showEquipmentDetail(context, equip),
                    icon: const Icon(Icons.info, color: Colors.blue),
                  ),
                  ElevatedButton(
                    onPressed: () => _unequip(slot, setDialogState),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                    child: const Text('卸下'),
                  ),
                ],
              )
            : null,
      ),
    );
  }

  Widget _buildPotentialPreview(EquipmentPotential potential) {
    final gradeColor = _getGradeColor(potential.grade);
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: gradeColor.withOpacity(0.2), borderRadius: BorderRadius.circular(4), border: Border.all(color: gradeColor.withOpacity(0.5))),
      child: Text('${_getGradeName(potential.grade)} 潜能', style: TextStyle(color: gradeColor, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  void _unequip(EquipmentSlot slot, StateSetter setDialogState) {
    final notifier = ref.read(gameProvider.notifier);
    final success = notifier.unequipItem(slot);
    if (success) {
      setDialogState(() {});
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('📦 装备已卸下'), backgroundColor: Colors.green));
    }
  }

  void _showEquipmentDetail(BuildContext context, Equipment equip) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Row(children: [Text(equip.emoji ?? '⚔️', style: const TextStyle(fontSize: 28)), const SizedBox(width: 12), Expanded(child: Text(equip.name, style: const TextStyle(color: Colors.white)))]),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFF0F3460), borderRadius: BorderRadius.circular(8)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('📊 基础属性', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    if (equip.atk > 0) Text('攻击力: +${equip.atk}', style: const TextStyle(color: Colors.white70)),
                    if (equip.def > 0) Text('防御力: +${equip.def}', style: const TextStyle(color: Colors.white70)),
                    if (equip.str > 0) Text('力量: +${equip.str}', style: const TextStyle(color: Colors.white70)),
                    if (equip.dex > 0) Text('敏捷: +${equip.dex}', style: const TextStyle(color: Colors.white70)),
                    if (equip.intBonus > 0) Text('智力: +${equip.intBonus}', style: const TextStyle(color: Colors.white70)),
                    if (equip.luk > 0) Text('运气: +${equip.luk}', style: const TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (equip.potential != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: _getGradeColor(equip.potential!.grade).withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: _getGradeColor(equip.potential!.grade))),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('✨ ${_getGradeName(equip.potential!.grade)}潜能', style: TextStyle(color: _getGradeColor(equip.potential!.grade), fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ...equip.potential!.stats.map((s) => Text('• ${s.displayText}', style: const TextStyle(color: Colors.white70))),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showCubeDialog(context, equip);
                  },
                  icon: const Text('🎲'),
                  label: const Text('使用魔方重塑潜能'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white),
                ),
              ),
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('关闭'))],
      ),
    );
  }

  void _showCubeDialog(BuildContext context, Equipment equip) {
    showDialog(
      context: context,
      builder: (context) => CubeEquipmentSelector(cubeType: 'normal', initialEquipment: equip),
    );
  }

  Color _getJobColor(Job job) {
    switch (job) {
      case Job.warrior: return Colors.red;
      case Job.magician: return Colors.blue;
      case Job.bowman: return Colors.green;
      case Job.thief: return Colors.purple;
      case Job.pirate: return Colors.orange;
      default: return Colors.grey;
    }
  }

  String _getJobEmoji(Job job) {
    switch (job) {
      case Job.warrior: return '⚔️';
      case Job.magician: return '🔮';
      case Job.bowman: return '🏹';
      case Job.thief: return '🗡️';
      case Job.pirate: return '⚓';
      default: return '🙂';
    }
  }
  
  Color _getGradeColor(PotentialGrade grade) {
    switch (grade) {
      case PotentialGrade.rare: return Colors.blue;
      case PotentialGrade.epic: return Colors.purple;
      case PotentialGrade.unique: return Colors.green;
      default: return Colors.grey;
    }
  }

  String _getGradeName(PotentialGrade grade) {
    switch (grade) {
      case PotentialGrade.rare: return '稀有';
      case PotentialGrade.epic: return '史诗';
      case PotentialGrade.unique: return '传说';
      default: return '普通';
    }
  }
}
