import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_provider.dart';
import '../game/models/player.dart';
import '../game/models/item.dart';
import 'cube_dialog.dart';

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
  bool _isBatchMode = false;  // 批量模式
  final Set<String> _selectedItems = {};  // 选中的物品ID

  @override
  Widget build(BuildContext context) {
    final player = ref.watch(gameProvider).player;
    
    // 分类物品
    final categorizedItems = _categorizeItems(player);
    final displayItems = _getDisplayItems(categorizedItems);
    
    // 计算选中物品的总价值
    final totalSellPrice = _calculateTotalSellPrice();

    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A2E),
      title: Row(
        children: [
          const Text(
            '🎒 物品栏',
            style: TextStyle(color: Colors.white),
          ),
          const Spacer(),
          // 批量模式切换按钮
          TextButton.icon(
            onPressed: () {
              setState(() {
                _isBatchMode = !_isBatchMode;
                _selectedItems.clear();
              });
            },
            icon: Icon(
              _isBatchMode ? Icons.check_box : Icons.check_box_outline_blank,
              color: _isBatchMode ? Colors.amber : Colors.white54,
              size: 20,
            ),
            label: Text(
              _isBatchMode ? '退出批量' : '批量出售',
              style: TextStyle(
                color: _isBatchMode ? Colors.amber : Colors.white54,
                fontSize: 12,
              ),
            ),
          ),
        ],
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
            // 批量操作栏
            if (_isBatchMode && _selectedItems.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '已选中 ${_selectedItems.length} 件物品',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '预计获得: $totalSellPrice 金币',
                            style: const TextStyle(
                              color: Colors.amber,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _batchSell,
                      icon: const Icon(Icons.sell, size: 18),
                      label: const Text('出售'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (_isBatchMode)
          TextButton(
            onPressed: () {
              setState(() {
                _selectedItems.clear();
              });
            },
            child: const Text('清空选择'),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('关闭'),
        ),
      ],
    );
  }

  /// 计算选中物品的总售价
  int _calculateTotalSellPrice() {
    int total = 0;
    for (final itemId in _selectedItems) {
      final item = ShopDatabase.getById(itemId);
      final equipment = EquipmentDatabase.getById(itemId);
      final price = item?.price ?? equipment?.price ?? 0;
      total += (price * 0.5).toInt();
    }
    return total;
  }

  /// 批量出售
  void _batchSell() {
    if (_selectedItems.isEmpty) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text(
          '确认批量出售?',
          style: TextStyle(color: Colors.orange),
        ),
        content: Text(
          '即将出售 ${_selectedItems.length} 件物品，获得 ${_calculateTotalSellPrice()} 金币',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              int totalGold = 0;
              for (final itemId in _selectedItems.toList()) {
                final item = ShopDatabase.getById(itemId);
                final equipment = EquipmentDatabase.getById(itemId);
                final itemName = item?.name ?? equipment?.name ?? '物品';
                final price = item?.price ?? equipment?.price ?? 0;
                
                if (ref.read(gameProvider.notifier).sellItem(itemId, quantity: 1)) {
                  totalGold += (price * 0.5).toInt();
                }
              }
              
              setState(() {
                _selectedItems.clear();
              });
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('💰 批量出售完成，获得 $totalGold 金币'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('确认出售'),
          ),
        ],
      ),
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
      
      // 首先尝试通过instanceId获取装备实例（新系统）
      final equipInstance = ref.read(gameProvider.notifier).getEquipmentByInstanceId(itemId);
      if (equipInstance != null) {
        result[InventoryCategory.equipment]!.add(entry);
        result[InventoryCategory.all]!.add(entry);
        continue;
      }
      
      // 然后尝试通过类型ID查找（兼容旧系统）
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
        onTap: () {
          setState(() {
            _selectedCategory = category;
            _selectedItems.clear(); // 切换分类时清空选择
          });
        },
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
        
        // 获取物品信息 - 优先通过instanceId获取装备实例
        final equipInstance = ref.read(gameProvider.notifier).getEquipmentByInstanceId(itemId);
        final item = ShopDatabase.getById(itemId);
        final equipment = equipInstance ?? EquipmentDatabase.getById(itemId);
        
        final String name = equipInstance?.name ?? item?.name ?? equipment?.name ?? '未知物品';
        final String emoji = equipInstance?.emoji ?? item?.emoji ?? equipment?.emoji ?? '❓';
        final String description = equipInstance?.description ?? item?.description ?? equipment?.description ?? '';
        
        // 判断类型
        final bool isEquipment = equipment != null;
        final bool isConsumable = item?.type == ItemType.consumable || item?.type == ItemType.scroll;
        
        // 检查装备是否已装备（仅用于视觉标记，不影响按钮显示）
        final bool hasEquipped = isEquipment && _hasEquippedType(equipment!, player);
        final bool isSelected = _selectedItems.contains(itemId);

        return Card(
          color: isSelected 
              ? Colors.orange.withOpacity(0.3)
              : (hasEquipped ? const Color(0xFF533483) : const Color(0xFF0F3460)),
          margin: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: _isBatchMode
                ? () {
                    setState(() {
                      if (isSelected) {
                        _selectedItems.remove(itemId);
                      } else {
                        _selectedItems.add(itemId);
                      }
                    });
                  }
                : null,
            child: ListTile(
              leading: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isBatchMode)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Icon(
                        isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                        color: isSelected ? Colors.orange : Colors.white54,
                      ),
                    ),
                  Text(emoji, style: const TextStyle(fontSize: 24)),
                ],
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  if (hasEquipped)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '已装备同类型',
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
              trailing: _isBatchMode
                  ? null
                  : Row(
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
                        // 操作按钮 - 背包里的装备都显示装备和卖出
                        if (isEquipment)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ElevatedButton(
                                onPressed: () => _equip(itemId),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.purple,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                ),
                                child: const Text('装备'),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () => _sell(itemId),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                ),
                                child: const Text('卖出'),
                              ),
                            ],
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
          ),
        );
      },
    );
  }

  /// 检查玩家是否已装备同类型装备（仅用于显示标记）
  bool _hasEquippedType(Equipment equipment, Player player) {
    return player.equipment.values.any((eq) => eq?.id == equipment.id);
  }

  /// 装备物品
  void _equip(String itemId) {
    final equipment = EquipmentDatabase.getById(itemId);
    final success = ref.read(gameProvider.notifier).equipItem(itemId);
    if (success) {
      setState(() {}); // 刷新界面
      if (equipment != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✨ 已装备 ${equipment.name}'),
            backgroundColor: Colors.purple,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      if (equipment != null) {
        final levelReq = equipment.levelReq ?? 1;
        final playerLevel = ref.read(gameProvider).player.stats.level;
        if (playerLevel < levelReq) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ 等级不足！需要 Lv.$levelReq 才能装备 ${equipment.name}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }

  /// 卸下装备
  void _unequip(Equipment equipment) {
    final success = ref.read(gameProvider.notifier).unequipItem(equipment.slot);
    if (success) {
      setState(() {}); // 刷新界面
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('📦 已卸下 ${equipment.name}'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// 使用物品
  void _use(String itemId) {
    // 检查是否是魔方
    if (itemId == 'cube_normal' || itemId == 'cube_advanced' || itemId == 'cube_super') {
      Navigator.pop(context);
      final cubeType = itemId == 'cube_advanced' 
          ? 'advanced' 
          : itemId == 'cube_super' 
              ? 'super' 
              : 'normal';
      showDialog(
        context: context,
        builder: (context) => CubeEquipmentSelector(cubeType: cubeType),
      );
      return;
    }
    
    ref.read(gameProvider.notifier).useItem(itemId);
    Navigator.pop(context);
  }

  /// 卖出物品
  void _sell(String itemId) {
    final item = ShopDatabase.getById(itemId);
    final equipment = EquipmentDatabase.getById(itemId);
    final itemName = item?.name ?? equipment?.name ?? '物品';
    final itemPrice = item?.price ?? equipment?.price ?? 0;
    final sellPrice = (itemPrice * 0.5).toInt();
    
    final success = ref.read(gameProvider.notifier).sellItem(itemId, quantity: 1);
    if (success) {
      setState(() {}); // 刷新界面
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('💰 卖出 $itemName，获得 $sellPrice 金币'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}