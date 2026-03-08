import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../game/models/player.dart';
import '../game/models/item.dart';
import '../game/models/potential.dart';
import '../providers/game_provider.dart';
import 'cube_dialog.dart';

/// 装备详情对话框 - 显示装备信息并提供使用魔方入口
class EquipmentDetailDialog extends StatelessWidget {
  final Equipment equipment;
  final bool isEquipped;
  final VoidCallback? onEquip;
  final VoidCallback? onUnequip;
  final VoidCallback? onSell;

  const EquipmentDetailDialog({
    super.key,
    required this.equipment,
    this.isEquipped = false,
    this.onEquip,
    this.onUnequip,
    this.onSell,
  });

  @override
  Widget build(BuildContext context) {
    final potential = equipment.potential;
    
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A2E),
      title: Row(
        children: [
          Text(equipment.emoji ?? '📦', style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  equipment.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _getSlotName(equipment.slot),
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (isEquipped)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.3),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                '已装备',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 基础属性区域
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0F3460),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '基础属性',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildStatRow('攻击', equipment.atk, Colors.red),
                  _buildStatRow('防御', equipment.def, Colors.blue),
                  _buildStatRow('力量', equipment.str, Colors.orange),
                  _buildStatRow('敏捷', equipment.dex, Colors.green),
                  _buildStatRow('智力', equipment.intBonus, Colors.purple),
                  _buildStatRow('运气', equipment.luk, Colors.yellow),
                  if (equipment.crit != null && equipment.crit! > 0)
                    _buildStatRow('暴击', '${equipment.crit}%', Colors.redAccent),
                  if (equipment.avoid != null && equipment.avoid! > 0)
                    _buildStatRow('闪避', '${equipment.avoid}%', Colors.cyan),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 潜能区域
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: potential != null 
                    ? Color(int.parse(potential.gradeColor.replaceFirst('#', '0xFF'))).withOpacity(0.1)
                    : const Color(0xFF0F3460),
                borderRadius: BorderRadius.circular(12),
                border: potential != null
                    ? Border.all(
                        color: Color(int.parse(potential.gradeColor.replaceFirst('#', '0xFF'))),
                        width: 2,
                      )
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        '潜能属性',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      if (potential != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Color(int.parse(potential.gradeColor.replaceFirst('#', '0xFF'))),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            potential.gradeName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      else
                        const Text(
                          '无潜能',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (potential != null && potential.stats.isNotEmpty)
                    ...potential.stats.map((stat) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: _getGradeColor(stat.grade).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            stat.displayText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getGradeColor(stat.grade),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              stat.grade,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ))
                  else
                    const Center(
                      child: Text(
                        '该装备暂无潜能\n可使用魔方添加或重塑潜能',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 等级要求
            if (equipment.levelReq != null && equipment.levelReq! > 1)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber, color: Colors.amber, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      '需要等级 Lv.${equipment.levelReq}',
                      style: const TextStyle(
                        color: Colors.amber,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        // 卖出按钮
        if (onSell != null)
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              onSell!();
            },
            icon: const Icon(Icons.sell, color: Colors.orange),
            label: const Text('卖出', style: TextStyle(color: Colors.orange)),
          ),
        
        // 装备/卸下按钮
        if (isEquipped && onUnequip != null)
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              onUnequip!();
            },
            icon: const Icon(Icons.remove_circle),
            label: const Text('卸下'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          )
        else if (!isEquipped && onEquip != null)
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              onEquip!();
            },
            icon: const Icon(Icons.add_circle),
            label: const Text('装备'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
            ),
          ),
        
        // 使用魔方按钮
        ElevatedButton.icon(
          onPressed: () {
            Navigator.pop(context);
            _showCubeSelector(context);
          },
          icon: const Icon(Icons.auto_fix_high),
          label: const Text('使用魔方'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, dynamic value, Color color) {
    if (value == null || (value is int && value == 0) || (value is String && value == '0')) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          const Spacer(),
          Text(
            value is String ? value : '+$value',
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getGradeColor(String grade) {
    switch (grade) {
      case 'B':
        return Colors.blue;
      case 'A':
        return Colors.purple;
      case 'S':
        return Colors.orange;
      case 'SS':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getSlotName(EquipmentSlot slot) {
    switch (slot) {
      case EquipmentSlot.weapon:
        return '武器';
      case EquipmentSlot.helmet:
        return '头盔';
      case EquipmentSlot.armor:
        return '铠甲';
      case EquipmentSlot.pants:
        return '护腿';
      case EquipmentSlot.shoes:
        return '鞋子';
      case EquipmentSlot.gloves:
        return '手套';
      case EquipmentSlot.cape:
        return '披风';
      case EquipmentSlot.shield:
        return '盾牌';
    }
  }

  void _showCubeSelector(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => CubeSelectorDialog(equipment: equipment),
    );
  }
}

/// 选择魔方对话框 - 从背包中选择要使用的魔方
class CubeSelectorDialog extends ConsumerWidget {
  final Equipment equipment;

  const CubeSelectorDialog({
    super.key,
    required this.equipment,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(gameProvider).player;
    
    // 统计背包中的魔方
    final cubeCounts = <String, int>{};
    for (final itemId in player.inventory) {
      if (itemId == 'cube_normal' || itemId == 'cube_advanced' || itemId == 'cube_super') {
        cubeCounts[itemId] = (cubeCounts[itemId] ?? 0) + 1;
      }
    }

    final hasCubes = cubeCounts.isNotEmpty;

    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A2E),
      title: const Row(
        children: [
          Icon(Icons.auto_fix_high, color: Colors.blue),
          SizedBox(width: 12),
          Text(
            '选择魔方',
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
      content: SizedBox(
        width: 320,
        child: hasCubes
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 装备预览
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F3460),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Text(equipment.emoji ?? '📦', style: const TextStyle(fontSize: 24)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                equipment.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (equipment.potential != null)
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Color(int.parse(
                                      equipment.potential!.gradeColor.replaceFirst('#', '0xFF'),
                                    )),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    equipment.potential!.gradeName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                    ),
                                  ),
                                )
                              else
                                const Text(
                                  '无潜能',
                                  style: TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '背包中的魔方:',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // 魔方列表
                  if (cubeCounts['cube_normal'] != null)
                    _buildCubeTile(
                      context,
                      '🎲',
                      '神奇魔方',
                      '重塑装备潜能属性',
                      cubeCounts['cube_normal']!,
                      Colors.purple,
                      () => _useCube(context, ref, 'normal'),
                    ),
                  if (cubeCounts['cube_advanced'] != null)
                    _buildCubeTile(
                      context,
                      '🔷',
                      '高级神奇魔方',
                      '30%概率升级为史诗',
                      cubeCounts['cube_advanced']!,
                      Colors.blue,
                      () => _useCube(context, ref, 'advanced'),
                    ),
                  if (cubeCounts['cube_super'] != null)
                    _buildCubeTile(
                      context,
                      '💎',
                      '超级神奇魔方',
                      '20%概率升级为传说',
                      cubeCounts['cube_super']!,
                      Colors.green,
                      () => _useCube(context, ref, 'super'),
                    ),
                ],
              )
            : const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inventory_2_outlined, color: Colors.grey, size: 48),
                  SizedBox(height: 16),
                  Text(
                    '背包中没有魔方',
                    style: TextStyle(color: Colors.white70),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '请前往商店购买或查收邮件',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
      ],
    );
  }

  Widget _buildCubeTile(
    BuildContext context,
    String emoji,
    String name,
    String description,
    int count,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      color: const Color(0xFF0F3460),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Text(emoji, style: const TextStyle(fontSize: 28)),
        title: Text(name, style: const TextStyle(color: Colors.white)),
        subtitle: Text(
          description,
          style: const TextStyle(color: Colors.white54, fontSize: 11),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'x$count',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: const Text('使用'),
            ),
          ],
        ),
      ),
    );
  }

  void _useCube(BuildContext context, WidgetRef ref, String cubeType) {
    // 消耗魔方
    final cubeId = cubeType == 'advanced' 
        ? 'cube_advanced' 
        : cubeType == 'super' 
            ? 'cube_super' 
            : 'cube_normal';
    
    ref.read(gameProvider.notifier).useItem(cubeId);
    
    Navigator.pop(context);
    
    // 打开洗潜能对话框
    showDialog(
      context: context,
      builder: (context) => CubeDialog(
        equipment: equipment,
        cubeType: cubeType,
      ),
    );
  }
}
