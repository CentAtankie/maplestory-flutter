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
            Text('馃彧 ', style: TextStyle(fontSize: 24)),
            Text('鏉傝揣搴?),
          ],
        ),
        actions: [
          // 鏄剧ず閲戝竵
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
                const Text('馃挵', style: TextStyle(fontSize: 16)),
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
          // 鍟嗗簵娆㈣繋璇?          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0F3460),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF533483)),
            ),
            child: const Row(
              children: [
                Text('馃懘', style: TextStyle(fontSize: 32)),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '娆㈣繋鍏変复锛佽繖閲屾湁鍚勭鑽按鍜屽嵎杞达紝鏃呰鑰呴渶瑕佷拱鐐逛粈涔堝悧锛?,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 鍟嗗搧鍒嗙被鏍囩
          _buildCategoryTabs(ref, currentCategory),

          // 鍟嗗搧鍒楄〃
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
            _buildTab(ref, '璐拱', ShopCategory.all, currentCategory),
            _buildTab(ref, '瑁呭', ShopCategory.equipment, currentCategory),
            _buildTab(ref, '鐗规畩', ShopCategory.special, currentCategory),
            _buildTab(ref, '鍗栧嚭', ShopCategory.sell, currentCategory),
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
    // 鍟嗗簵鍙崠娑堣€楀搧鍜屽嵎杞达紝涓嶅崠鏉愭枡
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
          '璇ュ垎绫绘殏鏃犲晢鍝?,
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
                    // 閲戝竵涓嶈冻鎻愮ず
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('鉂?閲戝竵涓嶈冻锛侀渶瑕?${item.price} 閲戝竵'),
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
                  // 鐗╁搧鍥炬爣
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

                  // 鐗╁搧淇℃伅
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

                  // 浠锋牸
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
                          canAfford ? '馃挵' : '鉂?,
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

  Widget _buildSellList(WidgetRef ref, Player player) {
    // 缁熻鐗╁搧鏁伴噺
    final itemCounts = <String, int>{};
    for (final itemId in player.inventory) {
      itemCounts[itemId] = (itemCounts[itemId] ?? 0) + 1;
    }

    if (itemCounts.isEmpty) {
      return const Center(
        child: Text(
          '鑳屽寘鏄┖鐨勶紝娌℃湁浠€涔堝彲鍗栫殑',
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
                              '馃摝 鏉愭枡 - 鍙兘鍗栧嚭',
                              style: TextStyle(
                                color: Colors.orange, 
                                fontSize: 10
                              ),
                            ),
                        ],
                      ),
                    ),
                    // 鏁伴噺
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
                // 鎵归噺鍗栧嚭鎸夐挳
                Row(
                  children: [
                    // 鍗?涓?                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          ref.read(gameProvider.notifier).sellItem(item.id, quantity: 1);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        child: Text('鍗?涓?馃挵$sellPrice'),
                      ),
                    ),
                    // 鍗栧叏閮?                    if (maxQuantity > 1) ...[
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
                            '鍗栧叏閮?馃挵${sellPrice * maxQuantity}',
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
    // 鐗规畩鐗╁搧锛堥瓟鏂癸級
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
                        content: Text('鉂?閲戝竵涓嶈冻锛侀渶瑕?${item.price} 閲戝竵'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // 鐗╁搧鍥炬爣
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

                  // 鐗╁搧淇℃伅
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

                  // 浠锋牸
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
                          canAfford ? '馃挵' : '鉂?,
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
              '璐拱 ${item.name}',
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
                  '浠锋牸: ',
                  style: TextStyle(color: Colors.white70),
                ),
                const Text('馃挵 ', style: TextStyle(fontSize: 16)),
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
            child: const Text('鍙栨秷'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(gameProvider.notifier).buyItem(item);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('璐拱鎴愬姛锛?{item.name}'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('纭璐拱'),
          ),
        ],
      ),
    );
  }

  // 瑁呭鍒楄〃
  Widget _buildEquipmentList(WidgetRef ref, Player player) {
    final equipments = EquipmentDatabase.getShopEquipments();
    
    if (equipments.isEmpty) {
      return const Center(
        child: Text(
          '鏆傛棤瑁呭鍑哄敭',
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
                            content: Text('鉂?闇€瑕佺瓑绾?$levelReq 鎵嶈兘瑁呭'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    : () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('鉂?閲戝竵涓嶈冻锛侀渶瑕?$price 閲戝竵'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // 瑁呭鍥炬爣
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        equipment.emoji ?? '馃摝',
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // 瑁呭淇℃伅
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
                        // 瑁呭灞炴€?                        _buildEquipmentStats(equipment),
                      ],
                    ),
                  ),

                  // 浠锋牸
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
                          canAfford && canEquip ? '馃挵' : '鉂?,
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

  // 瑁呭灞炴€ф樉绀?  Widget _buildEquipmentStats(Equipment equipment) {
    // 浣跨敤equipment鐨剆tats getter
    final statTexts = <String>[];
    
    if (equipment.atk > 0) statTexts.add('鏀诲嚮+${equipment.atk}');
    if (equipment.def > 0) statTexts.add('闃插尽+${equipment.def}');
    if (equipment.str > 0) statTexts.add('鍔涢噺+${equipment.str}');
    if (equipment.dex > 0) statTexts.add('鏁忔嵎+${equipment.dex}');
    if (equipment.intBonus > 0) statTexts.add('鏅哄姏+${equipment.intBonus}');
    if (equipment.luk > 0) statTexts.add('杩愭皵+${equipment.luk}');

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

  // 瑁呭璐拱瀵硅瘽妗?  void _showEquipmentBuyDialog(BuildContext context, WidgetRef ref, Equipment equipment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Row(
          children: [
            Text(equipment.emoji ?? '馃摝', style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Text(
              '璐拱 ${equipment.name}',
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
              '闇€瑕佺瓑绾? Lv.${equipment.levelReq ?? 1}',
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
                  '浠锋牸: ',
                  style: TextStyle(color: Colors.white70),
                ),
                const Text('馃挵 ', style: TextStyle(fontSize: 16)),
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
            child: const Text('鍙栨秷'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(gameProvider.notifier).buyEquipment(equipment);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('璐拱鎴愬姛锛?{equipment.name}'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('纭璐拱'),
          ),
        ],
      ),
    );
  }
}
