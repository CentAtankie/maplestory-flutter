import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_provider.dart';
import '../game/models/item.dart' hide Equipment;
import '../game/models/player.dart';

class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameProvider);
    final player = gameState.player;
    final currentCategory = gameState.shopCategory;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            ref.read(gameProvider.notifier).closeShop();
          },
        ),
        title: const Row(
          children: [
            Text('🏪 ', style: TextStyle(fontSize: 24)),
            Text('杂货店'),
          ],
        ),
        actions: [
          // 显示金币
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('💰', style: TextStyle(fontSize: 16)),
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
      body: Column(
        children: [
          // 商店欢迎语
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0F3460),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF533483)),
            ),
            child: const Row(
              children: [
                Text('👴', style: TextStyle(fontSize: 32)),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '欢迎光临！这里有各种药水和卷轴，旅行者需要买点什么吗？',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 商品分类标签
          _buildCategoryTabs(ref, currentCategory),

          // 商品列表
          Expanded(
            child: currentCategory == ShopCategory.sell
                ? _buildSellList(ref, player)
                : currentCategory == ShopCategory.equipment
                    ? _buildEquipmentList(ref, player)
                    : currentCategory == ShopCategory.special
                        ? _buildSpecialList(ref, player)
                        : _buildItemList(ref, player, currentCategory),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs(WidgetRef ref, ShopCategory currentCategory) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildTab(ref, '购买', ShopCategory.all, currentCategory),
            _buildTab(ref, '装备', ShopCategory.equipment, currentCategory),
            _buildTab(ref, '特殊', ShopCategory.special, currentCategory),
            _buildTab(ref, '卖出', ShopCategory.sell, currentCategory),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(WidgetRef ref, String label, ShopCategory category, ShopCategory currentCategory) {
    final isActive = category == currentCategory;

    return GestureDetector(
      onTap: () {
        ref.read(gameProvider.notifier).setShopCategory(category);
      },
      child: Container(
        width: 80,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF533483) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? const Color(0xFF533483) : Colors.white24,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white54,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildItemList(WidgetRef ref, Player player, ShopCategory category) {
    // 商店只卖消耗品和卷轴，不卖材料
    var items = ShopDatabase.items.where((item) => 
      item.type == ItemType.consumable || item.type == ItemType.scroll
    ).toList();
    
    if (category == ShopCategory.consumable) {
      items = items.where((item) => item.type == ItemType.consumable).toList();
    } else if (category == ShopCategory.scroll) {
      items = items.where((item) => item.type == ItemType.scroll).toList();
    }

    if (items.isEmpty) {
      return const Center(
        child: Text(
          '该分类暂无商品',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final canAfford = player.meso >= item.price;

        return Card(
          color: const Color(0xFF0F3460),
          margin: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: canAfford
                ? () => _showBuyDialog(context, ref, item)
                : () {
                    // 金币不足提示
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('❌ 金币不足！需要 ${item.price} 金币'),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // 物品图标
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: _getItemColor(item.type).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        item.emoji,
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // 物品信息
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.description,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 价格
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: canAfford
                          ? Colors.green.withOpacity(0.2)
                          : Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          canAfford ? '💰' : '❌',
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${item.price}',
                          style: TextStyle(
                            color: canAfford ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getItemColor(ItemType type) {
    switch (type) {
      case ItemType.consumable:
        return Colors.red;
      case ItemType.scroll:
        return Colors.purple;
      case ItemType.equipment:
        return Colors.orange;
      case ItemType.material:
        return Colors.blue;
      case ItemType.special:
        return Colors.amber;
    }
  }

  Widget _buildSellList(WidgetRef ref, Player player) {
    // 统计物品数量
    final itemCounts = <String, int>{};
    for (final itemId in player.inventory) {
      itemCounts[itemId] = (itemCounts[itemId] ?? 0) + 1;
    }

    if (itemCounts.isEmpty) {
      return const Center(
        child: Text(
          '背包是空的，没有什么可卖的',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: itemCounts.length,
      itemBuilder: (context, index) {
        final entry = itemCounts.entries.elementAt(index);
        final item = ShopDatabase.getById(entry.key);
        if (item == null) return const SizedBox.shrink();

        final sellPrice = (item.price * 0.5).toInt();
        final maxQuantity = entry.value;
        final isMaterial = item.type == ItemType.material;

        return Card(
          color: const Color(0xFF0F3460),
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(item.emoji, style: const TextStyle(fontSize: 28)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: const TextStyle(
                              color: Colors.white, 
                              fontWeight: FontWeight.bold
                            ),
                          ),
                          Text(
                            item.description,
                            style: const TextStyle(
                              color: Colors.white70, 
                              fontSize: 12
                            ),
                          ),
                          if (isMaterial)
                            const Text(
                              '📦 材料 - 只能卖出',
                              style: TextStyle(
                                color: Colors.orange, 
                                fontSize: 10
                              ),
                            ),
                        ],
                      ),
                    ),
                    // 数量
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12, 
                        vertical: 6
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'x$maxQuantity',
                        style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // 批量卖出按钮
                Row(
                  children: [
                    // 卖1个
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          ref.read(gameProvider.notifier).sellItem(item.id, quantity: 1);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        child: Text('卖1个 💰$sellPrice'),
                      ),
                    ),
                    // 卖全部
                    if (maxQuantity > 1) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            ref.read(gameProvider.notifier).sellItem(
                              item.id, 
                              quantity: maxQuantity
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          child: Text(
                            '卖全部 💰${sellPrice * maxQuantity}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSpecialList(WidgetRef ref, Player player) {
    // 特殊物品（魔方）
    final specialItems = [
      ShopDatabase.getById('cube_normal'),
      ShopDatabase.getById('cube_advanced'),
      ShopDatabase.getById('cube_super'),
    ].where((item) => item != null).toList();

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: specialItems.length,
      itemBuilder: (context, index) {
        final item = specialItems[index]!;
        final canAfford = player.meso >= item.price;

        return Card(
          color: const Color(0xFF0F3460),
          margin: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: canAfford
                ? () => _showBuyDialog(context, ref, item)
                : () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('❌ 金币不足！需要 ${item.price} 金币'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // 物品图标
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        item.emoji,
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // 物品信息
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.description,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 价格
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: canAfford
                          ? Colors.amber.withOpacity(0.2)
                          : Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          canAfford ? '💰' : '❌',
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${item.price}',
                          style: TextStyle(
                            color: canAfford ? Colors.amber : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showBuyDialog(BuildContext context, WidgetRef ref, GameItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Row(
          children: [
            Text(item.emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Text(
              '购买 ${item.name}',
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.description,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text(
                  '价格: ',
                  style: TextStyle(color: Colors.white70),
                ),
                const Text('💰 ', style: TextStyle(fontSize: 16)),
                Text(
                  '${item.price}',
                  style: const TextStyle(
                    color: Colors.amber,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
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
              ref.read(gameProvider.notifier).buyItem(item);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('购买成功：${item.name}'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('确认购买'),
          ),
        ],
      ),
    );
  }

  // 装备列表
  Widget _buildEquipmentList(WidgetRef ref, Player player) {
    final equipments = EquipmentDatabase.getShopEquipments();
    
    if (equipments.isEmpty) {
      return const Center(
        child: Text(
          '暂无装备出售',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: equipments.length,
      itemBuilder: (context, index) {
        final equipment = equipments[index];
        final price = equipment.price ?? 0;
        final levelReq = equipment.levelReq ?? 1;
        final canAfford = player.meso >= price;
        final canEquip = player.stats.level >= levelReq;

        return Card(
          color: const Color(0xFF0F3460),
          margin: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: canAfford && canEquip
                ? () => _showEquipmentBuyDialog(context, ref, equipment)
                : canAfford && !canEquip
                    ? () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('❌ 需要等级 $levelReq 才能装备'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    : () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('❌ 金币不足！需要 $price 金币'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // 装备图标
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        equipment.emoji ?? '📦',
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // 装备信息
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              equipment.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: canEquip
                                    ? Colors.green.withOpacity(0.3)
                                    : Colors.red.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Lv.$levelReq',
                                style: TextStyle(
                                  color: canEquip ? Colors.green : Colors.red,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          equipment.description ?? '',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // 装备属性
                        _buildEquipmentStats(equipment),
                      ],
                    ),
                  ),

                  // 价格
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: canAfford && canEquip
                          ? Colors.green.withOpacity(0.2)
                          : Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          canAfford && canEquip ? '💰' : '❌',
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$price',
                          style: TextStyle(
                            color: canAfford && canEquip
                                ? Colors.green
                                : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // 装备属性显示
  Widget _buildEquipmentStats(Equipment equipment) {
    // 使用equipment的stats getter
    final statTexts = <String>[];
    
    if (equipment.atk > 0) statTexts.add('攻击+${equipment.atk}');
    if (equipment.def > 0) statTexts.add('防御+${equipment.def}');
    if (equipment.str > 0) statTexts.add('力量+${equipment.str}');
    if (equipment.dex > 0) statTexts.add('敏捷+${equipment.dex}');
    if (equipment.intBonus > 0) statTexts.add('智力+${equipment.intBonus}');
    if (equipment.luk > 0) statTexts.add('运气+${equipment.luk}');

    return Wrap(
      spacing: 8,
      children: statTexts.map((text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.amber.withOpacity(0.2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.amber,
            fontSize: 10,
          ),
        ),
      )).toList(),
    );
  }

  // 装备购买对话框
  void _showEquipmentBuyDialog(BuildContext context, WidgetRef ref, Equipment equipment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Row(
          children: [
            Text(equipment.emoji ?? '📦', style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Text(
              '购买 ${equipment.name}',
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              equipment.description ?? '',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            Text(
              '需要等级: Lv.${equipment.levelReq ?? 1}',
              style: TextStyle(
                color: (equipment.levelReq ?? 1) <= ref.read(gameProvider).player.stats.level
                    ? Colors.green
                    : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildEquipmentStats(equipment),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text(
                  '价格: ',
                  style: TextStyle(color: Colors.white70),
                ),
                const Text('💰 ', style: TextStyle(fontSize: 16)),
                Text(
                  '${equipment.price ?? 0}',
                  style: const TextStyle(
                    color: Colors.amber,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
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
              ref.read(gameProvider.notifier).buyEquipment(equipment);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('购买成功：${equipment.name}'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('确认购买'),
          ),
        ],
      ),
    );
  }
}
