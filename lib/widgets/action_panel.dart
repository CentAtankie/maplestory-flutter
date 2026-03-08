import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_provider.dart';
import '../game/models/player.dart';
import '../game/models/map.dart';
import '../game/models/item.dart';
import '../screens/shop_screen.dart';
import '../screens/create_character_screen.dart';
import '../services/audio_manager.dart';
import 'inventory_dialog.dart';

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
            // 地图按钮（替换方向键）
            _buildMapButton(context, ref, gameState),
            
            const SizedBox(height: 12),
            
            // 功能按钮
            _buildActionButtons(context, ref, isTown),
            
            const SizedBox(height: 12),
            
            // 自动模式开关
            _buildAutoModeSwitches(context, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildMapButton(BuildContext context, WidgetRef ref, GameData gameState) {
    return ElevatedButton.icon(
      onPressed: () => _showMapSelector(context, ref),
      icon: const Icon(Icons.map, color: Colors.white),
      label: Text(
        '地图: ${gameState.currentMap.name}',
        style: const TextStyle(color: Colors.white),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF0F3460),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _showMapSelector(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text(
          '🗺️ 选择目的地',
          style: TextStyle(color: Colors.white),
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView(
            children: [
              // 村庄分类 - 可展开
              _buildExpandableCategory(
                context, ref,
                title: '🏘️ 安全区（村庄）',
                maps: [
                  _buildMapTile(context, ref, '射手村', 'henesys', '🏘️'),
                  _buildMapTile(context, ref, '明珠港', 'lith', '⚓'),
                ],
              ),
              const SizedBox(height: 8),
              // 初级野外 - 可展开
              _buildExpandableCategory(
                context, ref,
                title: '🌱 初级冒险区 (Lv.1-10)',
                maps: [
                  _buildMapTile(context, ref, '射手村东部平原', 'farm', '🌾'),
                  _buildMapTile(context, ref, '射手村北部小路', 'trail', '🌲'),
                  _buildMapTile(context, ref, '绿水灵树洞', 'slime_tree', '🌳'),
                ],
              ),
              const SizedBox(height: 8),
              // 中级野外 - 可展开
              _buildExpandableCategory(
                context, ref,
                title: '🌲 中级冒险区 (Lv.10-20)',
                maps: [
                  _buildMapTile(context, ref, '树洞', 'cave', '🕳️'),
                ],
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

  Widget _buildExpandableCategory(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required List<Widget> maps,
  }) {
    return StatefulBuilder(
      builder: (context, setState) {
        // 检查是否有地图在当前分类中
        final isExpanded = true; // 默认展开，方便用户看到
        
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0F3460),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 分类标题
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF533483).withOpacity(0.3),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      '${maps.length}个地图',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // 地图列表
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: maps,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMapTile(BuildContext context, WidgetRef ref, String name, String mapId, String emoji) {
    final currentMap = ref.read(gameProvider).currentMap.id;
    final isCurrent = currentMap == mapId;
    
    return ListTile(
      leading: Text(emoji, style: const TextStyle(fontSize: 24)),
      title: Text(
        name,
        style: TextStyle(
          color: isCurrent ? Colors.amber : Colors.white,
          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isCurrent
          ? const Icon(Icons.location_on, color: Colors.amber)
          : const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
      onTap: isCurrent
          ? null
          : () {
              Navigator.pop(context);
              ref.read(gameProvider.notifier).moveToMap(mapId);
            },
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
                ref.read(gameProvider.notifier).explore();
              }
            },
          ),
        ),
        const SizedBox(width: 12),
        
        // 商店
        Expanded(
          child: _buildActionButton(
            icon: Icons.store,
            label: '商店',
            color: isTown ? Colors.amber : Colors.grey,
            onPressed: isTown
                ? () {
                    ref.read(gameProvider.notifier).openShop();
                  }
                : null,
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

  /// 构建自动模式开关
  Widget _buildAutoModeSwitches(BuildContext context, WidgetRef ref) {
    final isAutoExplore = ref.watch(gameProvider.notifier).isAutoExplore;
    final isAutoBattle = ref.watch(gameProvider.notifier).isAutoBattle;
    final gameState = ref.watch(gameProvider);
    final isTown = gameState.currentMap.isTown;
    final isBattling = gameState.gameState == GameState.battling;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0F3460),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // 自动探索开关
          Expanded(
            child: InkWell(
              onTap: isTown || isBattling
                  ? null
                  : () {
                      ref.read(gameProvider.notifier).setAutoExplore(!isAutoExplore);
                    },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isAutoExplore
                      ? Colors.orange.withOpacity(0.3)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isAutoExplore ? Colors.orange : Colors.white24,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      isAutoExplore ? Icons.explore : Icons.explore_outlined,
                      color: isTown || isBattling
                          ? Colors.grey
                          : (isAutoExplore ? Colors.orange : Colors.white54),
                      size: 20,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '自动探索',
                      style: TextStyle(
                        color: isTown || isBattling
                            ? Colors.grey
                            : (isAutoExplore ? Colors.orange : Colors.white54),
                        fontSize: 10,
                      ),
                    ),
                    if (isAutoExplore)
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // 自动战斗开关
          Expanded(
            child: InkWell(
              onTap: () {
                ref.read(gameProvider.notifier).setAutoBattle(!isAutoBattle);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isAutoBattle
                      ? Colors.red.withOpacity(0.3)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isAutoBattle ? Colors.red : Colors.white24,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      isAutoBattle ? Icons.flash_on : Icons.flash_off,
                      color: isAutoBattle ? Colors.red : Colors.white54,
                      size: 20,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '自动战斗',
                      style: TextStyle(
                        color: isAutoBattle ? Colors.red : Colors.white54,
                        fontSize: 10,
                      ),
                    ),
                    if (isAutoBattle)
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onPressed,
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
    showDialog(
      context: context,
      builder: (context) => const InventoryDialog(),
    );
  }

  void _showCharacterDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final player = ref.watch(gameProvider).player;
          final stats = player.stats;

          return AlertDialog(
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
                  _buildStatRow('力量', player.baseStr, player.equipStr, Colors.orange),
                  _buildStatRow('敏捷', player.baseDex, player.equipDex, Colors.green),
                  _buildStatRow('智力', player.baseInt, player.equipInt, Colors.blue),
                  _buildStatRow('运气', player.baseLuk, player.equipLuk, Colors.purple),
                  const Divider(color: Colors.white24),
                  _buildCombatStatRow('攻击力', player.baseAtk, player.equipAtk, Colors.red),
                  _buildCombatStatRow('防御力', player.baseDef, player.equipDef, Colors.blue),
                  _buildRateStatRow('暴击率', player.baseCritRate, player.equipCritRate, Colors.orange),
                  _buildRateStatRow('闪避率', player.baseAvoidRate, player.equipAvoidRate, Colors.cyan),
                  const Divider(color: Colors.white24),
                  // 属性点区域 - 始终显示
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: stats.ap > 0 ? Colors.amber.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: stats.ap > 0 ? Colors.amber.withOpacity(0.3) : Colors.grey.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.star,
                              color: stats.ap > 0 ? Colors.amber : Colors.grey,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '可用属性点: ${stats.ap}',
                              style: TextStyle(
                                color: stats.ap > 0 ? Colors.amber : Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        if (stats.ap > 0) ...[
                          const SizedBox(height: 8),
                          const Text(
                            '点击分配：',
                            style: TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: [
                              _buildStatButton(context, '力量', 'str', ref, setDialogState),
                              _buildStatButton(context, '敏捷', 'dex', ref, setDialogState),
                              _buildStatButton(context, '智力', 'int', ref, setDialogState),
                              _buildStatButton(context, '运气', 'luk', ref, setDialogState),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Divider(color: Colors.white24),
                  // 显示已装备的装备
                  const Text(
                    '已装备',
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildEquippedItem('武器', player.equipment[EquipmentSlot.weapon], EquipmentSlot.weapon, ref, setDialogState),
                  _buildEquippedItem('头盔', player.equipment[EquipmentSlot.helmet], EquipmentSlot.helmet, ref, setDialogState),
                  _buildEquippedItem('衣服', player.equipment[EquipmentSlot.armor], EquipmentSlot.armor, ref, setDialogState),
                  _buildEquippedItem('裤子', player.equipment[EquipmentSlot.pants], EquipmentSlot.pants, ref, setDialogState),
                  _buildEquippedItem('鞋子', player.equipment[EquipmentSlot.shoes], EquipmentSlot.shoes, ref, setDialogState),
                  _buildEquippedItem('披风', player.equipment[EquipmentSlot.cape], EquipmentSlot.cape, ref, setDialogState),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('关闭'),
              ),
            ],
          );
        },
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

  Widget _buildStatRow(String label, int baseValue, int equipValue, Color color) {
    final total = baseValue + equipValue;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70),
          ),
          Row(
            children: [
              // 基础值
              Text(
                '$baseValue',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              // 装备加成（如果有）
              if (equipValue > 0) ...[
                Text(
                  ' + ',
                  style: TextStyle(
                    color: color.withOpacity(0.7),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$equipValue',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  ' = ',
                  style: TextStyle(
                    color: Colors.white54,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$total',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCombatStatRow(String label, int baseValue, int equipValue, Color color) {
    final total = baseValue + equipValue;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70),
          ),
          Row(
            children: [
              // 基础值
              Text(
                '$baseValue',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              // 装备加成（如果有）
              if (equipValue > 0) ...[
                Text(
                  ' + ',
                  style: TextStyle(
                    color: color.withOpacity(0.7),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$equipValue',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  ' = ',
                  style: TextStyle(
                    color: Colors.white54,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$total',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRateStatRow(String label, double baseValue, int equipValue, Color color) {
    final total = baseValue + equipValue;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70),
          ),
          Row(
            children: [
              // 基础值
              Text(
                '${baseValue.toStringAsFixed(1)}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              // 装备加成（如果有）
              if (equipValue > 0) ...[
                Text(
                  ' + ',
                  style: TextStyle(
                    color: color.withOpacity(0.7),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$equipValue%',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  ' = ',
                  style: TextStyle(
                    color: Colors.white54,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${total.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatButton(BuildContext context, String label, String statType, WidgetRef ref, StateSetter setDialogState) {
    return ElevatedButton(
      onPressed: () {
        final success = ref.read(gameProvider.notifier).allocateStat(statType);
        if (success) {
          // 使用 setDialogState 刷新对话框，不关闭
          setDialogState(() {});
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.amber.withOpacity(0.2),
        foregroundColor: Colors.amber,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        minimumSize: const Size(0, 32),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: const BorderSide(color: Colors.amber),
        ),
      ),
      child: Text('+ $label'),
    );
  }

  Widget _buildEquippedItem(String slotName, Equipment? equipment, EquipmentSlot slot, WidgetRef ref, StateSetter setDialogState) {
    if (equipment == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Text(
              '$slotName: ',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
            const Text(
              '无',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      );
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            '$slotName: ',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          Expanded(
            child: Text(
              equipment.name,
              style: const TextStyle(
                color: Colors.amber,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '(${equipment.stats})',
            style: TextStyle(
              color: Colors.green.withOpacity(0.8),
              fontSize: 10,
            ),
          ),
          const SizedBox(width: 8),
          // 卸下按钮
          SizedBox(
            width: 40,
            height: 24,
            child: ElevatedButton(
              onPressed: () {
                final success = ref.read(gameProvider.notifier).unequipItem(slot);
                if (success) {
                  setDialogState(() {});
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.withOpacity(0.3),
                foregroundColor: Colors.orange,
                padding: EdgeInsets.zero,
                textStyle: const TextStyle(fontSize: 10),
              ),
              child: const Text('卸下'),
            ),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog(BuildContext context, WidgetRef ref) async {
    final hasSave = await ref.read(gameProvider.notifier).hasSave();
    
    if (!context.mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text(
          '⚙️ 设置',
          style: TextStyle(color: Colors.white),
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: MediaQuery.of(context).size.height * 0.6, // 限制最大高度
          child: SingleChildScrollView( // 添加滚动支持
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 背景音乐控制
                StatefulBuilder(
                  builder: (context, setState) {
                    final audioManager = AudioManager();
                    final isPlaying = audioManager.isPlaying;
                    final volume = audioManager.volume;
                    final isWeb = audioManager.isWeb;
                    
                    return Column(
                      children: [
                        ListTile(
                          leading: Icon(
                            isWeb 
                                ? Icons.music_off 
                                : (isPlaying ? Icons.music_note : Icons.music_off),
                            color: isWeb 
                                ? Colors.grey 
                                : (isPlaying ? Colors.green : Colors.grey),
                          ),
                          title: const Text(
                            '背景音乐',
                            style: TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            isWeb 
                                ? 'Web 平台暂不支持'
                                : (isPlaying ? '正在播放: 射手村' : '已暂停'),
                            style: const TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                          trailing: isWeb 
                              ? null
                              : Switch(
                                  value: isPlaying,
                                  onChanged: (value) async {
                                    if (value) {
                                      await AudioManager().resume();
                                    } else {
                                      await AudioManager().pause();
                                    }
                                    setState(() {});
                                  },
                                  activeColor: Colors.green,
                                ),
                        ),
                        if (!isWeb && isPlaying)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.volume_down,
                                  color: Colors.white54,
                                  size: 20,
                                ),
                                Expanded(
                                  child: Slider(
                                    value: volume,
                                    onChanged: (value) async {
                                      await AudioManager().setVolume(value);
                                      setState(() {});
                                    },
                                    activeColor: Colors.green,
                                    inactiveColor: Colors.white24,
                                  ),
                                ),
                                const Icon(
                                  Icons.volume_up,
                                  color: Colors.white54,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        const Divider(color: Colors.white24),
                      ],
                    );
                  },
                ),
                // 修改名字
                ListTile(
                  leading: const Icon(Icons.edit, color: Colors.orange),
                  title: const Text(
                    '修改名字',
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    '当前: ${ref.read(gameProvider).player.name}',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showRenameDialog(context, ref);
                  },
                ),
                const Divider(color: Colors.white24),
                // 保存游戏
                ListTile(
                  leading: const Icon(Icons.save, color: Colors.green),
                  title: const Text(
                    '保存游戏',
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: const Text(
                    '将当前进度保存到本地',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    final success = await ref.read(gameProvider.notifier).saveGame();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(success ? '✅ 游戏已保存' : '❌ 保存失败'),
                          backgroundColor: success ? Colors.green : Colors.red,
                        ),
                      );
                    }
                  },
                ),
                // 读取存档
                ListTile(
                  leading: Icon(Icons.folder_open, 
                    color: hasSave ? Colors.blue : Colors.grey),
                  title: Text(
                    '读取存档',
                    style: TextStyle(
                      color: hasSave ? Colors.white : Colors.grey,
                    ),
                  ),
                  subtitle: Text(
                    hasSave ? '加载上次保存的进度' : '没有存档',
                    style: TextStyle(
                      color: hasSave ? Colors.white54 : Colors.grey, 
                      fontSize: 12
                    ),
                  ),
                  onTap: hasSave ? () async {
                    Navigator.pop(context);
                    final success = await ref.read(gameProvider.notifier).loadGame();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(success ? '✅ 存档已读取' : '❌ 读取失败'),
                          backgroundColor: success ? Colors.green : Colors.red,
                        ),
                      );
                    }
                  } : null,
                ),
                // 导出存档
                ListTile(
                  leading: const Icon(Icons.upload, color: Colors.orange),
                  title: const Text(
                    '导出存档',
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: const Text(
                    '导出为 JSON 文件（可转移存档）',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    final json = await ref.read(gameProvider.notifier).exportToJson();
                    if (context.mounted) {
                      if (json != null) {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: const Color(0xFF1A1A2E),
                            title: const Text(
                              '📤 存档已导出',
                              style: TextStyle(color: Colors.white),
                            ),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  '请复制以下文本保存到安全的地方：',
                                  style: TextStyle(color: Colors.white70),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.black26,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: SelectableText(
                                    json.substring(0, json.length > 200 ? 200 : json.length) + '...',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
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
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('❌ 导出失败'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                ),
                // 导入存档
                ListTile(
                  leading: const Icon(Icons.download, color: Colors.purple),
                  title: const Text(
                    '导入存档',
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: const Text(
                    '从 JSON 文件恢复存档',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showImportDialog(context, ref);
                  },
                ),
                const Divider(color: Colors.white24),
                // 删除存档
                ListTile(
                  leading: Icon(Icons.delete, 
                    color: hasSave ? Colors.red : Colors.grey),
                  title: Text(
                    '删除存档',
                    style: TextStyle(
                      color: hasSave ? Colors.red : Colors.grey,
                    ),
                  ),
                  onTap: hasSave ? () {
                    Navigator.pop(context);
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: const Color(0xFF1A1A2E),
                        title: const Text(
                          '⚠️ 确认删除?',
                          style: TextStyle(color: Colors.red),
                        ),
                        content: const Text(
                          '存档将被永久删除，无法恢复！',
                          style: TextStyle(color: Colors.white70),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('取消'),
                          ),
                          TextButton(
                            onPressed: () async {
                              Navigator.pop(context);
                              final success = await ref.read(gameProvider.notifier).deleteSave();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(success ? '🗑️ 存档已删除' : '❌ 删除失败'),
                                    backgroundColor: success ? Colors.green : Colors.red,
                                  ),
                                );
                              }
                            },
                            child: const Text(
                              '确认删除',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );
                  } : null,
                ),
                const Divider(color: Colors.white24),
                // 重新开始
                ListTile(
                  leading: const Icon(Icons.refresh, color: Colors.white70),
                  title: const Text(
                    '重新开始',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    final confirmed = await showDialog<bool>(
                      context: context,
                      barrierDismissible: false,
                      builder: (BuildContext ctx) {
                        return AlertDialog(
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
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: const Text('取消'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(true),
                              child: const Text(
                                '确认',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                    
                    if (confirmed == true && context.mounted) {
                      await Future.delayed(const Duration(milliseconds: 100));
                      if (context.mounted) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => CreateCharacterScreen(
                              playerName: ref.read(gameProvider).player.name,
                            ),
                          ),
                        );
                      }
                    }
                  },
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
      ),
    );
  }

  void _showImportDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text(
          '📥 导入存档',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '请粘贴之前导出的存档 JSON：',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 5,
              style: const TextStyle(color: Colors.white, fontSize: 12),
              decoration: InputDecoration(
                hintText: '{"player": {...}, ...}',
                hintStyle: const TextStyle(color: Colors.white30),
                filled: true,
                fillColor: Colors.black26,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              final json = controller.text.trim();
              if (json.isNotEmpty) {
                Navigator.pop(context);
                final success = await ref.read(gameProvider.notifier).importFromJson(json);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? '✅ 存档已导入' : '❌ 导入失败，请检查JSON格式'),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('导入'),
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController(text: ref.read(gameProvider).player.name);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text(
          '✏️ 修改名字',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '请输入新的冒险家名字：',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLength: 10,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: '输入名字（最多10字）',
                hintStyle: const TextStyle(color: Colors.white30),
                filled: true,
                fillColor: Colors.black26,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                counterStyle: const TextStyle(color: Colors.white54),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                Navigator.pop(context);
                final success = ref.read(gameProvider.notifier).changePlayerName(newName);
                if (success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('✨ 改名成功！欢迎 $newName'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('确认'),
          ),
        ],
      ),
    );
  }
}
