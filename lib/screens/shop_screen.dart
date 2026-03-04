import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_provider.dart';
import '../game/models/item.dart';

class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameProvider);
    final player = gameState.player;

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
          _buildCategoryTabs(),

          // 商品列表
          Expanded(
            child: _buildItemList(ref, player),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          _buildTab('全部', true),
          _buildTab('药水', false),
          _buildTab('卷轴', false),
        ],
      ),
    );
  }

  Widget _buildTab(String label, bool isActive) {
    return Expanded(
      child: Container(
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

  Widget _buildItemList(WidgetRef ref, Player player) {
    final items = ShopDatabase.items;

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
                : null,
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
    }
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
}
