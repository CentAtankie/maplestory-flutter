import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_provider.dart';
import '../game/models/player.dart';
import '../game/models/item.dart';

/// 物品栏分类
enum InventoryCategory {
  all,       // 全部
  equipment, // 装备
  consumable,// 消耗品
  material,  // 材料/其他
}

/// 物品栏对话框
class InventoryDialog extends ConsumerStatefulWidget {
  const InventoryDialog({super.key});

  @override
  ConsumerState<InventoryDialog> createState() => _InventoryDialogState();
}

class _InventoryDialogState extends ConsumerState<InventoryDialog> {
  InventoryCategory _selectedCategory = InventoryCategory.all;

  @override
  Widget build(BuildContext context) {
    final player = ref.watch(gameProvider).player;
    
    // 分类物品
    final categorizedItems = _categorizeItems(player);
    final displayItems = _getDisplayItems(categorizedItems);

    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A2E),
      title: const Text(
        '🎒 物品栏',
        style: TextStyle(color: Colors.white),
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 450,
        child: Column(
          children: [
            // 分类标签
            _buildCategoryTabs(),
            const SizedBox(height: 12),
            // 物品列表
            Expanded(
              child: displayItems.isEmpty
                  ? const Center(
                      child: Text(
                        '该分类没有物品',
                        style: TextStyle(color: Colors.white54),
                      ),
                    )
                  : _buildItemList(displayItems, player),
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
    );
  }

  /// 分类物品
  Map<InventoryCategory, List<MapEntry<String, int>>> _categorizeItems(Player player) {
    final result = <InventoryCategory, List<MapEntry<String, int>>>{
      InventoryCategory.all: [],
      InventoryCategory.equipment: [],
      InventoryCategory.consumable: [],
      InventoryCategory.material: [],
    };

    // 统计物品数量
    final itemCounts = <String, int>{};
    for (final itemId in player.inventory) {
      itemCounts[itemId] = (itemCounts[itemId] ?? 0) + 1;
    }

    for (final entry in itemCounts.entries) {
      final itemId = entry.key;
      final count = entry.value;
      
      // 检查是否是装备
      final equipment = EquipmentDatabase.getById(itemId);
      if (equipment != null) {
        result[InventoryCategory.equipment]!.add(entry);
        result[InventoryCategory.all]!.add(entry);
        continue;
      }

      // 检查是否是普通物品
      final item = ShopDatabase.getById(itemId);
      if (item != null) {
        if (item.type == ItemType.consumable || item.type == ItemType.scroll) {
          result[InventoryCategory.consumable]!.add(entry);
        } else if (item.type == ItemType.material) {
          result[InventoryCategory.material]!.add(entry);
        }
        result[InventoryCategory.all]!.add(entry);
      }
    }

    return result;
  }

  /// 获取当前分类的物品
  List<MapEntry<String, int>> _getDisplayItems(
    Map<InventoryCategory, List<MapEntry<String, int>>> categorizedItems,
  ) {
    return categorizedItems[_selectedCategory] ?? [];
  }

  /// 构建分类标签
  Widget _buildCategoryTabs() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F3460),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          _buildTab('全部', InventoryCategory.all),
          _buildTab('装备', InventoryCategory.equipment),
          _buildTab('消耗', InventoryCategory.consumable),
          _buildTab('其他', InventoryCategory.material),
        ],
      ),
    );
  }

  Widget _buildTab(String label, InventoryCategory category) {
    final isSelected = _selectedCategory == category;
    
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedCategory = category),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF533483) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white54,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  /// 构建物品列表
  Widget _buildItemList(List<MapEntry<String, int>> items, Player player) {
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final entry = items[index];
        final itemId = entry.key;
        final count = entry.value;
        
        // 获取物品信息
        final item = ShopDatabase.getById(itemId);
        final equipment = EquipmentDatabase.getById(itemId);
        
        final String name = item?.name ?? equipment?.name ?? '未知物品';
        final String emoji = item?.emoji ?? equipment?.emoji ?? '❓';
        final String description = item?.description ?? equipment?.description ?? '';
        
        // 判断类型
        final bool isEquipment = equipment != null;
        final bool isConsumable = item?.type == ItemType.consumable || item?.type == ItemType.scroll;
        
        // 检查装备是否已装备
        final bool isEquipped = isEquipment && _isEquipped(equipment!, player);

        return Card(
          color: isEquipped ? const Color(0xFF533483) : const Color(0xFF0F3460),
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Text(emoji, style: const TextStyle(fontSize: 24)),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                if (isEquipped)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      '已装备',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                if (isEquipment)
                  Text(
                    equipment!.stats,
                    style: TextStyle(
                      color: Colors.green.withOpacity(0.8),
                      fontSize: 10,
                    ),
                  ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 数量
                if (count > 1)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'x$count',
                      style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                // 操作按钮
                if (isEquipped)
                  ElevatedButton(
                    onPressed: () => _unequip(equipment!),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: const Text('卸下'),
                  )
                else if (isEquipment)
                  ElevatedButton(
                    onPressed: () => _equip(itemId),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: const Text('装备'),
                  )
                else if (item?.type == ItemType.material)
                  ElevatedButton(
                    onPressed: () => _sell(itemId),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: const Text('卖出'),
                  )
                else if (isConsumable)
                  ElevatedButton(
                    onPressed: () => _use(itemId),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: const Text('使用'),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 检查装备是否已装备
  bool _isEquipped(Equipment equipment, Player player) {
    return player.equipment.values.any((eq) => eq?.id == equipment.id);
  }

  /// 装备物品
  void _equip(String itemId) {
    ref.read(gameProvider.notifier).equipItem(itemId);
    setState(() {}); // 刷新界面
  }

  /// 卸下装备
  void _unequip(Equipment equipment) {
    ref.read(gameProvider.notifier).unequipItem(equipment.slot);
    setState(() {}); // 刷新界面
  }

  /// 使用物品
  void _use(String itemId) {
    ref.read(gameProvider.notifier).useItem(itemId);
    Navigator.pop(context);
  }

  /// 卖出物品
  void _sell(String itemId) {
    ref.read(gameProvider.notifier).sellItem(itemId, quantity: 1);
    setState(() {}); // 刷新界面
  }
}
