import 'dart:math';
import 'player.dart';

/// 物品类型
enum ItemType {
  consumable,  // 消耗品（药水）
  scroll,      // 卷轴
  equipment,   // 装备
  material,    // 材料
  special,     // 特殊（魔方等）
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
    // 材料不能使用
    if (type == ItemType.material) {
      return player;
    }
    
    if (effect == null) return player;

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
    // ========== 魔方道具 ==========
    // 神奇魔方
    GameItem(
      id: 'cube_normal',
      name: '神奇魔方',
      emoji: '🎲',
      type: ItemType.special,
      description: '重塑装备潜能属性',
      price: 10000,
    ),
    // 高级神奇魔方
    GameItem(
      id: 'cube_advanced',
      name: '高级神奇魔方',
      emoji: '🔷',
      type: ItemType.special,
      description: '重塑潜能，30%概率升级为黄色(史诗)',
      price: 50000,
    ),
    // 超级神奇魔方
    GameItem(
      id: 'cube_super',
      name: '超级神奇魔方',
      emoji: '💎',
      type: ItemType.special,
      description: '重塑潜能，20%概率升级为绿色(传说)',
      price: 200000,
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

/// 装备数据库（使用player.dart中的Equipment类）
class EquipmentDatabase {
  static final List<Equipment> equipments = [
    // 新手装备
    Equipment(
      name: '新手剑',
      id: 'beginner_sword',
      emoji: '🗡️',
      slot: EquipmentSlot.weapon,
      description: '新手村的训练用剑',
      price: 100,
      levelReq: 1,
      atk: 2,
    ),
    // 战士装备
    Equipment(
      name: '铁剑',
      id: 'iron_sword',
      emoji: '⚔️',
      slot: EquipmentSlot.weapon,
      description: '铁质长剑，适合战士',
      price: 500,
      levelReq: 5,
      atk: 8,
      str: 2,
    ),
    Equipment(
      name: '铁甲',
      id: 'iron_armor',
      emoji: '👕',
      slot: EquipmentSlot.armor,
      description: '铁质铠甲，提供良好防护',
      price: 400,
      levelReq: 5,
      def: 5,
      str: 1,
    ),
    // 法师装备
    Equipment(
      name: '木杖',
      id: 'wooden_staff',
      emoji: '🪄',
      slot: EquipmentSlot.weapon,
      description: '魔法师的入门法杖',
      price: 500,
      levelReq: 5,
      atk: 6,
      intBonus: 3,
    ),
    Equipment(
      name: '魔法袍',
      id: 'magic_robe',
      emoji: '👘',
      slot: EquipmentSlot.armor,
      description: '蕴含魔力的长袍',
      price: 400,
      levelReq: 5,
      def: 3,
      intBonus: 2,
    ),
    // 弓箭手装备
    Equipment(
      name: '木弓',
      id: 'wooden_bow',
      emoji: '🏹',
      slot: EquipmentSlot.weapon,
      description: '轻便的木质弓箭',
      price: 500,
      levelReq: 5,
      atk: 7,
      dex: 3,
    ),
    Equipment(
      name: '皮甲',
      id: 'leather_armor',
      emoji: '🦺',
      slot: EquipmentSlot.armor,
      description: '轻便的皮质护甲',
      price: 400,
      levelReq: 5,
      def: 4,
      dex: 2,
    ),
    // 通用防具
    Equipment(
      name: '皮帽',
      id: 'leather_helmet',
      emoji: '🎩',
      slot: EquipmentSlot.helmet,
      description: '普通的皮帽',
      price: 200,
      levelReq: 3,
      def: 2,
    ),
    Equipment(
      name: '皮鞋',
      id: 'leather_shoes',
      emoji: '👞',
      slot: EquipmentSlot.shoes,
      description: '结实的皮鞋',
      price: 150,
      levelReq: 3,
      def: 1,
      dex: 1,
    ),
    Equipment(
      name: '皮手套',
      id: 'leather_gloves',
      emoji: '🧤',
      slot: EquipmentSlot.gloves,
      description: '耐用的皮手套',
      price: 150,
      levelReq: 3,
      atk: 1,
      def: 1,
    ),
  ];

  /// 根据ID获取装备
  static Equipment? getById(String id) {
    try {
      return equipments.firstWhere((eq) => eq.id == id);
    } catch (e) {
      return null;
    }
  }

  /// 获取商店出售的装备（低级装备）
  static List<Equipment> getShopEquipments() {
    return equipments.where((eq) => (eq.levelReq ?? 1) <= 10).toList();
  }

  /// 获取指定等级范围的装备（用于怪物掉落）
  static List<Equipment> getByLevelRange(int minLevel, int maxLevel) {
    return equipments.where((eq) => 
      (eq.levelReq ?? 1) >= minLevel && (eq.levelReq ?? 1) <= maxLevel
    ).toList();
  }

  /// 获取随机装备（用于怪物掉落）
  static Equipment? getRandomDrop(int playerLevel) {
    final available = equipments.where((eq) => 
      (eq.levelReq ?? 1) <= playerLevel + 3 && (eq.levelReq ?? 1) >= playerLevel - 5
    ).toList();
    
    if (available.isEmpty) return null;
    
    // 低概率掉装备（5%）
    final random = Random();
    if (random.nextDouble() > 0.05) return null;
    
    return available[random.nextInt(available.length)];
  }
}
