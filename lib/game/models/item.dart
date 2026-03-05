import 'player.dart';

/// 物品类型
enum ItemType {
  consumable,  // 消耗品（药水）
  scroll,      // 卷轴
  equipment,   // 装备
  material,    // 材料
}

/// 物品效果
class ItemEffect {
  final String type;  // 'heal_hp', 'heal_mp', 'teleport'
  final int value;

  ItemEffect({
    required this.type,
    required this.value,
  });
}

/// 游戏物品
class GameItem {
  String id;
  String name;
  String emoji;
  ItemType type;
  String description;
  int price;
  ItemEffect? effect;

  GameItem({
    required this.id,
    required this.name,
    required this.emoji,
    required this.type,
    required this.description,
    required this.price,
    this.effect,
  });

  /// 使用物品
  Player use(Player player) {
    if (type == ItemType.material || effect == null) return player;  // 材料不能使用

    switch (effect!.type) {
      case 'heal_hp':
        final newHp = (player.stats.hp + effect!.value).clamp(0, player.stats.maxHp);
        return player.copyWith(
          stats: player.stats.copyWith(hp: newHp),
        );
      case 'heal_mp':
        final newMp = (player.stats.mp + effect!.value).clamp(0, player.stats.maxMp);
        return player.copyWith(
          stats: player.stats.copyWith(mp: newMp),
        );
      case 'teleport':
        // 回城卷轴 - 回到射手村
        return player.copyWith(currentMap: 'henesys');
      default:
        return player;
    }
  }
}

/// 商店数据库
class ShopDatabase {
  static final List<GameItem> items = [
    // 红药水
    GameItem(
      id: 'red_potion',
      name: '红药水',
      emoji: '❤️',
      type: ItemType.consumable,
      description: '恢复 50 点 HP',
      price: 50,
      effect: ItemEffect(type: 'heal_hp', value: 50),
    ),
    // 大瓶红药水
    GameItem(
      id: 'red_potion_large',
      name: '大瓶红药水',
      emoji: '💖',
      type: ItemType.consumable,
      description: '恢复 150 点 HP',
      price: 120,
      effect: ItemEffect(type: 'heal_hp', value: 150),
    ),
    // 蓝药水
    GameItem(
      id: 'blue_potion',
      name: '蓝药水',
      emoji: '💙',
      type: ItemType.consumable,
      description: '恢复 50 点 MP',
      price: 40,
      effect: ItemEffect(type: 'heal_mp', value: 50),
    ),
    // 大瓶蓝药水
    GameItem(
      id: 'blue_potion_large',
      name: '大瓶蓝药水',
      emoji: '💎',
      type: ItemType.consumable,
      description: '恢复 150 点 MP',
      price: 100,
      effect: ItemEffect(type: 'heal_mp', value: 150),
    ),
    // 回城卷轴
    GameItem(
      id: 'town_scroll',
      name: '回城卷轴',
      emoji: '📜',
      type: ItemType.scroll,
      description: '立即回到射手村',
      price: 200,
      effect: ItemEffect(type: 'teleport', value: 0),
    ),
    // 橙色药水（高级）
    GameItem(
      id: 'orange_potion',
      name: '橙色药水',
      emoji: '🧡',
      type: ItemType.consumable,
      description: '恢复 300 点 HP',
      price: 300,
      effect: ItemEffect(type: 'heal_hp', value: 300),
    ),
    // 白色药水（高级）
    GameItem(
      id: 'white_potion',
      name: '白色药水',
      emoji: '🤍',
      type: ItemType.consumable,
      description: '恢复 300 点 MP',
      price: 250,
      effect: ItemEffect(type: 'heal_mp', value: 300),
    ),
    // ========== 怪物掉落材料 ==========
    // 蜗牛壳
    GameItem(
      id: 'snail_shell',
      name: '蜗牛壳',
      emoji: '🐚',
      type: ItemType.material,
      description: '蜗牛的外壳，可以卖给商店',
      price: 10,
    ),
    // 蓝蜗牛壳
    GameItem(
      id: 'blue_snail_shell',
      name: '蓝蜗牛壳',
      emoji: '🔷',
      type: ItemType.material,
      description: '蓝蜗牛的壳，比普通的更值钱',
      price: 20,
    ),
    // 红蜗牛壳
    GameItem(
      id: 'red_snail_shell',
      name: '红蜗牛壳',
      emoji: '🔴',
      type: ItemType.material,
      description: '红蜗牛的壳，很稀有',
      price: 30,
    ),
    // 绿水灵的珠
    GameItem(
      id: 'slime_bubble',
      name: '绿水灵的珠',
      emoji: '💧',
      type: ItemType.material,
      description: '绿水灵体内的宝珠',
      price: 40,
    ),
    // 蘑菇仔的帽子
    GameItem(
      id: 'mushroom_cap',
      name: '蘑菇仔的帽子',
      emoji: '🍄',
      type: ItemType.material,
      description: '蘑菇仔的伞盖',
      price: 50,
    ),
    // 蓝蘑菇盖
    GameItem(
      id: 'blue_mushroom_cap',
      name: '蓝蘑菇盖',
      emoji: '🟦',
      type: ItemType.material,
      description: '蓝蘑菇的伞盖，很值钱',
      price: 70,
    ),
    // 刺蘑菇盖
    GameItem(
      id: 'horny_mushroom_cap',
      name: '刺蘑菇盖',
      emoji: '🌵',
      type: ItemType.material,
      description: '刺蘑菇的伞盖，非常稀有',
      price: 100,
    ),
  ];

  /// 根据 ID 获取物品
  static GameItem? getById(String id) {
    try {
      return items.firstWhere((item) => item.id == id);
    } catch (e) {
      return null;
    }
  }

  /// 获取所有消耗品
  static List<GameItem> getConsumables() {
    return items.where((item) => item.type == ItemType.consumable).toList();
  }

  /// 获取所有卷轴
  static List<GameItem> getScrolls() {
    return items.where((item) => item.type == ItemType.scroll).toList();
  }
}

/// 背包物品（带数量）
class InventoryItem {
  String itemId;
  int quantity;

  InventoryItem({
    required this.itemId,
    this.quantity = 1,
  });

  GameItem? get item => ShopDatabase.getById(itemId);
}
