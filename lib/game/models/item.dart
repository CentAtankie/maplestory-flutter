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
    // 木片
    GameItem(
      id: 'wood_piece',
      name: '木片',
      emoji: '🪵',
      type: ItemType.material,
      description: '木妖身上掉落的碎片',
      price: 80,
    ),
    // 野猪牙齿
    GameItem(
      id: 'boar_tooth',
      name: '野猪牙齿',
      emoji: '🦷',
      type: ItemType.material,
      description: '野猪的尖牙，可以打磨成饰品',
      price: 120,
    ),
    // 独眼兽尾巴
    GameItem(
      id: 'evil_eye_tail',
      name: '独眼兽尾巴',
      emoji: '🌀',
      type: ItemType.material,
      description: '独眼兽的尾巴，有微弱的魔力',
      price: 150,
    ),
    // 僵尸蘑菇盖
    GameItem(
      id: 'zombie_mushroom_cap',
      name: '僵尸蘑菇盖',
      emoji: '🧟',
      type: ItemType.material,
      description: '散发着诡异气息的蘑菇盖',
      price: 200,
    ),
    // 火焰野猪牙齿
    GameItem(
      id: 'fire_boar_tooth',
      name: '火焰野猪牙齿',
      emoji: '🔥',
      type: ItemType.material,
      description: '带有火焰纹路的尖牙',
      price: 250,
    ),
    // 石头人核心
    GameItem(
      id: 'golem_stone',
      name: '石头人核心',
      emoji: '🗿',
      type: ItemType.material,
      description: '石头人的动力核心',
      price: 350,
    ),
    // 暗黑石头人核心
    GameItem(
      id: 'dark_golem_stone',
      name: '暗黑石头人核心',
      emoji: '⬛',
      type: ItemType.material,
      description: '散发着黑暗气息的石头核心',
      price: 500,
    ),
    // 冰晶碎片
    GameItem(
      id: 'ice_piece',
      name: '冰晶碎片',
      emoji: '❄️',
      type: ItemType.material,
      description: '极寒之地凝结的冰晶',
      price: 400,
    ),
    // 火焰碎片
    GameItem(
      id: 'fire_piece',
      name: '火焰碎片',
      emoji: '🔥',
      type: ItemType.material,
      description: '永不熄灭的火焰凝结物',
      price: 400,
    ),
    // 幽灵布料
    GameItem(
      id: 'wraith_cloth',
      name: '幽灵布料',
      emoji: '👻',
      type: ItemType.material,
      description: '小幽灵留下的神秘布料',
      price: 600,
    ),
  ];

  /// 根据 ID 获取物品 - O(1) Map 查询
  static final Map<String, GameItem> _byId = {
    for (final item in items) item.id: item,
  };

  static GameItem? getById(String id) => _byId[id];

  /// 获取所有消耗品 (缓存,避免每次重建)
  static final List<GameItem> _consumables =
      items.where((item) => item.type == ItemType.consumable).toList(growable: false);
  static List<GameItem> getConsumables() => _consumables;

  /// 获取所有卷轴 (缓存)
  static final List<GameItem> _scrolls =
      items.where((item) => item.type == ItemType.scroll).toList(growable: false);
  static List<GameItem> getScrolls() => _scrolls;
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
    
    // 新手礼包1级装备
    Equipment(
      name: '🎁 冒险家头盔',
      id: 'gift_lvl1_helmet',
      emoji: '🪖',
      slot: EquipmentSlot.helmet,
      description: '新手礼包赠送的冒险家头盔',
      price: 0,
      levelReq: 1,
      def: 5,
      str: 2,
      setName: 'Adventurer Set',
    ),
    Equipment(
      name: '🎁 冒险家铠甲',
      id: 'gift_lvl1_armor',
      emoji: '👕',
      slot: EquipmentSlot.armor,
      description: '新手礼包赠送的冒险家铠甲',
      price: 0,
      levelReq: 1,
      def: 8,
      str: 3,
      setName: 'Adventurer Set',
    ),
    Equipment(
      name: '🎁 冒险家护腿',
      id: 'gift_lvl1_pants',
      emoji: '👖',
      slot: EquipmentSlot.pants,
      description: '新手礼包赠送的冒险家护腿',
      price: 0,
      levelReq: 1,
      def: 6,
      dex: 2,
      setName: 'Adventurer Set',
    ),
    Equipment(
      name: '🎁 冒险家战靴',
      id: 'gift_lvl1_shoes',
      emoji: '👢',
      slot: EquipmentSlot.shoes,
      description: '新手礼包赠送的冒险家战靴',
      price: 0,
      levelReq: 1,
      def: 4,
      dex: 3,
      setName: 'Adventurer Set',
    ),
    Equipment(
      name: '🎁 冒险家手套',
      id: 'gift_lvl1_gloves',
      emoji: '🧤',
      slot: EquipmentSlot.gloves,
      description: '新手礼包赠送的冒险家手套',
      price: 0,
      levelReq: 1,
      def: 3,
      atk: 2,
      setName: 'Adventurer Set',
    ),
    Equipment(
      name: '🎁 冒险家之剑',
      id: 'gift_lvl1_weapon',
      emoji: '⚔️',
      slot: EquipmentSlot.weapon,
      description: '新手礼包赠送的冒险家武器',
      price: 0,
      levelReq: 1,
      atk: 10,
      str: 2,
      setName: 'Adventurer Set',
    ),
    Equipment(
      name: '🎁 冒险家披风',
      id: 'gift_lvl1_cape',
      emoji: '🧣',
      slot: EquipmentSlot.cape,
      description: '新手礼包赠送的冒险家披风',
      price: 0,
      levelReq: 1,
      def: 3,
      luk: 2,
      setName: 'Adventurer Set',
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
      setName: 'Iron Set',
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
      setName: 'Iron Set',
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
      setName: 'Mage Set',
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
      setName: 'Mage Set',
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
    // ========== 冒险家套装 (gift_lvl1 items) ==========
    // 这些已经是 gift_lvl1 前缀的装备，添加 Adventurer Set
    // 已在上面定义，通过 copyWithInstanceId 时保留 setName
    // 需要在定义时就加上 setName，所以修改上面的 gift 装备
    // ========== Level 10-20 装备 ==========
    // 战士 - 钢系列
    Equipment(
      name: '钢剑',
      id: 'steel_sword',
      emoji: '🗡️',
      slot: EquipmentSlot.weapon,
      description: '钢制长剑，比铁剑更锋利',
      price: 1500,
      levelReq: 10,
      atk: 15,
      str: 4,
    ),
    Equipment(
      name: '钢盔',
      id: 'steel_helmet',
      emoji: '🪖',
      slot: EquipmentSlot.helmet,
      description: '钢制头盔，坚固耐用',
      price: 1000,
      levelReq: 10,
      def: 8,
      str: 2,
    ),
    Equipment(
      name: '钢甲',
      id: 'steel_armor',
      emoji: '🛡️',
      slot: EquipmentSlot.armor,
      description: '钢制铠甲，战士的标准装备',
      price: 1200,
      levelReq: 10,
      def: 12,
      str: 3,
    ),
    Equipment(
      name: '钢靴',
      id: 'steel_boots',
      emoji: '👢',
      slot: EquipmentSlot.shoes,
      description: '钢制战靴，沉重但坚固',
      price: 800,
      levelReq: 10,
      def: 6,
      str: 1,
    ),
    // 法师 - 魔导系列
    Equipment(
      name: '魔导杖',
      id: 'mage_staff',
      emoji: '🔮',
      slot: EquipmentSlot.weapon,
      description: '蕴含魔力的法杖',
      price: 1500,
      levelReq: 10,
      atk: 12,
      intBonus: 6,
    ),
    Equipment(
      name: '魔导帽',
      id: 'mage_hat',
      emoji: '🎓',
      slot: EquipmentSlot.helmet,
      description: '魔法师的尖顶帽',
      price: 1000,
      levelReq: 10,
      def: 4,
      intBonus: 3,
    ),
    Equipment(
      name: '魔导袍',
      id: 'mage_robe',
      emoji: '👘',
      slot: EquipmentSlot.armor,
      description: '高级魔法长袍',
      price: 1200,
      levelReq: 10,
      def: 6,
      intBonus: 5,
    ),
    Equipment(
      name: '魔导鞋',
      id: 'mage_shoes',
      emoji: '👡',
      slot: EquipmentSlot.shoes,
      description: '轻便的魔法鞋',
      price: 800,
      levelReq: 10,
      def: 3,
      intBonus: 2,
    ),
    // 弓箭手 - 猎人系列
    Equipment(
      name: '猎人弓',
      id: 'hunter_bow',
      emoji: '🏹',
      slot: EquipmentSlot.weapon,
      description: '猎人常用的复合弓',
      price: 1500,
      levelReq: 10,
      atk: 14,
      dex: 5,
    ),
    Equipment(
      name: '猎人帽',
      id: 'hunter_hat',
      emoji: '🎩',
      slot: EquipmentSlot.helmet,
      description: '猎人专用的宽边帽',
      price: 1000,
      levelReq: 10,
      def: 5,
      dex: 3,
    ),
    Equipment(
      name: '猎人装',
      id: 'hunter_suit',
      emoji: '🦺',
      slot: EquipmentSlot.armor,
      description: '猎人轻便护甲',
      price: 1200,
      levelReq: 10,
      def: 7,
      dex: 4,
    ),
    // 飞侠 - 暗影系列
    Equipment(
      name: '暗影短刀',
      id: 'shadow_dagger',
      emoji: '🗡️',
      slot: EquipmentSlot.weapon,
      description: '锋利的暗影短刀',
      price: 1500,
      levelReq: 10,
      atk: 13,
      luk: 5,
    ),
    Equipment(
      name: '暗影帽',
      id: 'shadow_hat',
      emoji: '🎭',
      slot: EquipmentSlot.helmet,
      description: '飞侠的暗影面罩',
      price: 1000,
      levelReq: 10,
      def: 4,
      luk: 3,
    ),
    Equipment(
      name: '暗影服',
      id: 'shadow_suit',
      emoji: '🥷',
      slot: EquipmentSlot.armor,
      description: '暗影紧身衣',
      price: 1200,
      levelReq: 10,
      def: 5,
      luk: 4,
    ),
    // 海盗 - 水手系列
    Equipment(
      name: '水手指虎',
      id: 'sailor_knuckle',
      emoji: '👊',
      slot: EquipmentSlot.weapon,
      description: '海盗水手用的指虎',
      price: 1500,
      levelReq: 10,
      atk: 14,
      str: 3,
      dex: 2,
    ),
    Equipment(
      name: '水手帽',
      id: 'sailor_hat',
      emoji: '⚓',
      slot: EquipmentSlot.helmet,
      description: '海盗船员的帽子',
      price: 1000,
      levelReq: 10,
      def: 5,
      str: 2,
      dex: 1,
    ),
    Equipment(
      name: '水手服',
      id: 'sailor_suit',
      emoji: '👕',
      slot: EquipmentSlot.armor,
      description: '海盗船员的制服',
      price: 1200,
      levelReq: 10,
      def: 7,
      str: 3,
      dex: 1,
    ),
    // ========== Level 20-40 装备 ==========
    // 战士 - 战魂系列
    Equipment(
      name: '战魂剑',
      id: 'warrior_blade',
      emoji: '⚔️',
      slot: EquipmentSlot.weapon,
      description: '灌注战魂之力的巨剑',
      price: 5000,
      levelReq: 25,
      atk: 28,
      str: 8,
    ),
    Equipment(
      name: '战魂盔',
      id: 'warrior_helm',
      emoji: '🪖',
      slot: EquipmentSlot.helmet,
      description: '战魂头盔，威风凛凛',
      price: 3500,
      levelReq: 25,
      def: 15,
      str: 4,
    ),
    Equipment(
      name: '战魂甲',
      id: 'warrior_plate',
      emoji: '🛡️',
      slot: EquipmentSlot.armor,
      description: '战魂铠甲，坚不可摧',
      price: 4000,
      levelReq: 25,
      def: 20,
      str: 5,
    ),
    Equipment(
      name: '战魂手套',
      id: 'warrior_gloves',
      emoji: '🥊',
      slot: EquipmentSlot.gloves,
      description: '战魂手套，握紧胜利',
      price: 2500,
      levelReq: 25,
      atk: 5,
      def: 5,
      str: 3,
    ),
    // 法师 - 元素系列
    Equipment(
      name: '元素杖',
      id: 'element_staff',
      emoji: '🔮',
      slot: EquipmentSlot.weapon,
      description: '操控元素之力的法杖',
      price: 5000,
      levelReq: 25,
      atk: 24,
      intBonus: 12,
    ),
    Equipment(
      name: '元素帽',
      id: 'element_hat',
      emoji: '🎓',
      slot: EquipmentSlot.helmet,
      description: '元素法师的冠冕',
      price: 3500,
      levelReq: 25,
      def: 8,
      intBonus: 6,
    ),
    Equipment(
      name: '元素袍',
      id: 'element_robe',
      emoji: '👘',
      slot: EquipmentSlot.armor,
      description: '编织元素之力的长袍',
      price: 4000,
      levelReq: 25,
      def: 10,
      intBonus: 8,
    ),
    Equipment(
      name: '元素手套',
      id: 'element_gloves',
      emoji: '🧤',
      slot: EquipmentSlot.gloves,
      description: '元素传导手套',
      price: 2500,
      levelReq: 25,
      atk: 3,
      intBonus: 5,
    ),
    // 弓箭手 - 风行者系列
    Equipment(
      name: '风行者弓',
      id: 'wind_bow',
      emoji: '🏹',
      slot: EquipmentSlot.weapon,
      description: '风之力加持的长弓',
      price: 5000,
      levelReq: 25,
      atk: 26,
      dex: 10,
    ),
    Equipment(
      name: '风行者帽',
      id: 'wind_hat',
      emoji: '🎩',
      slot: EquipmentSlot.helmet,
      description: '风行者羽帽',
      price: 3500,
      levelReq: 25,
      def: 10,
      dex: 5,
    ),
    Equipment(
      name: '风行者装',
      id: 'wind_suit',
      emoji: '🦺',
      slot: EquipmentSlot.armor,
      description: '风行者轻甲，灵动如风',
      price: 4000,
      levelReq: 25,
      def: 12,
      dex: 6,
    ),
    // 飞侠 - 夜行者系列
    Equipment(
      name: '夜行者短刀',
      id: 'night_dagger',
      emoji: '🗡️',
      slot: EquipmentSlot.weapon,
      description: '夜行者的致命短刀',
      price: 5000,
      levelReq: 25,
      atk: 25,
      luk: 10,
      crit: 3,
    ),
    Equipment(
      name: '夜行者帽',
      id: 'night_hat',
      emoji: '🎭',
      slot: EquipmentSlot.helmet,
      description: '夜行者面罩，隐匿于黑暗',
      price: 3500,
      levelReq: 25,
      def: 8,
      luk: 5,
      avoid: 2,
    ),
    Equipment(
      name: '夜行者装',
      id: 'night_suit',
      emoji: '🥷',
      slot: EquipmentSlot.armor,
      description: '夜行者夜行衣',
      price: 4000,
      levelReq: 25,
      def: 10,
      luk: 6,
      avoid: 2,
    ),
    // 海盗 - 破坏者系列
    Equipment(
      name: '破坏者指虎',
      id: 'destroyer_knuckle',
      emoji: '👊',
      slot: EquipmentSlot.weapon,
      description: '破坏一切的重型指虎',
      price: 5000,
      levelReq: 25,
      atk: 27,
      str: 6,
      dex: 4,
    ),
    Equipment(
      name: '破坏者帽',
      id: 'destroyer_hat',
      emoji: '⚓',
      slot: EquipmentSlot.helmet,
      description: '破坏者船长帽',
      price: 3500,
      levelReq: 25,
      def: 11,
      str: 3,
      dex: 2,
    ),
    Equipment(
      name: '破坏者装',
      id: 'destroyer_suit',
      emoji: '👕',
      slot: EquipmentSlot.armor,
      description: '破坏者战衣',
      price: 4000,
      levelReq: 25,
      def: 14,
      str: 4,
      dex: 2,
    ),
    // ========== Level 40-60 装备 ==========
    // 战士 - 龙骑士系列
    Equipment(
      name: '龙骑士剑',
      id: 'dragon_blade',
      emoji: '🐉',
      slot: EquipmentSlot.weapon,
      description: '龙之力灌注的巨剑',
      price: 15000,
      levelReq: 45,
      atk: 45,
      str: 15,
    ),
    Equipment(
      name: '龙骑士盔',
      id: 'dragon_helm',
      emoji: '🐲',
      slot: EquipmentSlot.helmet,
      description: '龙鳞打造的头盔',
      price: 10000,
      levelReq: 45,
      def: 25,
      str: 6,
    ),
    Equipment(
      name: '龙骑士甲',
      id: 'dragon_armor',
      emoji: '🛡️',
      slot: EquipmentSlot.armor,
      description: '龙鳞铠甲，传说级防具',
      price: 12000,
      levelReq: 45,
      def: 32,
      str: 8,
    ),
    Equipment(
      name: '龙骑士靴',
      id: 'dragon_boots',
      emoji: '👢',
      slot: EquipmentSlot.shoes,
      description: '龙皮战靴',
      price: 8000,
      levelReq: 45,
      def: 15,
      str: 4,
    ),
    // 法师 - 大魔导系列
    Equipment(
      name: '大魔导杖',
      id: 'archmage_staff',
      emoji: '🔮',
      slot: EquipmentSlot.weapon,
      description: '大魔导师的传承法杖',
      price: 15000,
      levelReq: 45,
      atk: 40,
      intBonus: 20,
    ),
    Equipment(
      name: '大魔导帽',
      id: 'archmage_hat',
      emoji: '👑',
      slot: EquipmentSlot.helmet,
      description: '大魔导师的智慧之冠',
      price: 10000,
      levelReq: 45,
      def: 12,
      intBonus: 8,
    ),
    Equipment(
      name: '大魔导袍',
      id: 'archmage_robe',
      emoji: '👘',
      slot: EquipmentSlot.armor,
      description: '大魔导师的奥法长袍',
      price: 12000,
      levelReq: 45,
      def: 15,
      intBonus: 10,
    ),
    Equipment(
      name: '大魔导手套',
      id: 'archmage_gloves',
      emoji: '🧤',
      slot: EquipmentSlot.gloves,
      description: '大魔导手套，魔力无穷',
      price: 7000,
      levelReq: 45,
      atk: 5,
      intBonus: 7,
    ),
    // 弓箭手 - 神射手系列
    Equipment(
      name: '神射手弓',
      id: 'sniper_bow',
      emoji: '🏹',
      slot: EquipmentSlot.weapon,
      description: '神射手专用的精灵弓',
      price: 15000,
      levelReq: 45,
      atk: 42,
      dex: 16,
      crit: 3,
    ),
    Equipment(
      name: '神射手帽',
      id: 'sniper_hat',
      emoji: '🎯',
      slot: EquipmentSlot.helmet,
      description: '神射手鹰眼帽',
      price: 10000,
      levelReq: 45,
      def: 14,
      dex: 7,
    ),
    Equipment(
      name: '神射手装',
      id: 'sniper_suit',
      emoji: '🦺',
      slot: EquipmentSlot.armor,
      description: '神射手精灵甲',
      price: 12000,
      levelReq: 45,
      def: 18,
      dex: 8,
    ),
    // 飞侠 - 暗影双刀系列
    Equipment(
      name: '暗影双刀',
      id: 'dual_dagger',
      emoji: '🗡️',
      slot: EquipmentSlot.weapon,
      description: '双持暗影之刃',
      price: 15000,
      levelReq: 45,
      atk: 40,
      luk: 16,
      crit: 5,
    ),
    Equipment(
      name: '暗影双刀帽',
      id: 'dual_hat',
      emoji: '🎭',
      slot: EquipmentSlot.helmet,
      description: '暗影双刀面罩',
      price: 10000,
      levelReq: 45,
      def: 12,
      luk: 7,
      avoid: 3,
    ),
    Equipment(
      name: '暗影双刀装',
      id: 'dual_suit',
      emoji: '🥷',
      slot: EquipmentSlot.armor,
      description: '暗影双刀夜行衣',
      price: 12000,
      levelReq: 45,
      def: 15,
      luk: 8,
      avoid: 3,
    ),
    // 海盗 - 冲锋队长系列
    Equipment(
      name: '冲锋队长指虎',
      id: 'captain_knuckle',
      emoji: '👊',
      slot: EquipmentSlot.weapon,
      description: '冲锋队长的钢铁指虎',
      price: 15000,
      levelReq: 45,
      atk: 43,
      str: 10,
      dex: 6,
    ),
    Equipment(
      name: '冲锋队长帽',
      id: 'captain_hat',
      emoji: '⚓',
      slot: EquipmentSlot.helmet,
      description: '冲锋队长军帽',
      price: 10000,
      levelReq: 45,
      def: 16,
      str: 5,
      dex: 3,
    ),
    Equipment(
      name: '冲锋队长装',
      id: 'captain_suit',
      emoji: '👕',
      slot: EquipmentSlot.armor,
      description: '冲锋队长战袍',
      price: 12000,
      levelReq: 45,
      def: 20,
      str: 6,
      dex: 4,
    ),
    // ========== Level 60-80 装备 ==========
    // 战士 - 狂战士系列
    Equipment(
      name: '狂战士巨剑',
      id: 'berserker_blade',
      emoji: '⚔️',
      slot: EquipmentSlot.weapon,
      description: '狂战士的毁灭之剑',
      price: 40000,
      levelReq: 65,
      atk: 65,
      str: 22,
      crit: 5,
    ),
    Equipment(
      name: '狂战士盔',
      id: 'berserker_helm',
      emoji: '🪖',
      slot: EquipmentSlot.helmet,
      description: '狂战士的战魂头盔',
      price: 25000,
      levelReq: 65,
      def: 35,
      str: 8,
    ),
    Equipment(
      name: '狂战士甲',
      id: 'berserker_armor',
      emoji: '🛡️',
      slot: EquipmentSlot.armor,
      description: '狂战士的血腥铠甲',
      price: 30000,
      levelReq: 65,
      def: 45,
      str: 10,
    ),
    // 法师 - 圣魔导系列
    Equipment(
      name: '圣魔导杖',
      id: 'saint_staff',
      emoji: '🔮',
      slot: EquipmentSlot.weapon,
      description: '圣魔导师的神圣法杖',
      price: 40000,
      levelReq: 65,
      atk: 58,
      intBonus: 28,
    ),
    Equipment(
      name: '圣魔导帽',
      id: 'saint_hat',
      emoji: '👑',
      slot: EquipmentSlot.helmet,
      description: '圣魔导师的圣洁之冠',
      price: 25000,
      levelReq: 65,
      def: 18,
      intBonus: 10,
    ),
    Equipment(
      name: '圣魔导袍',
      id: 'saint_robe',
      emoji: '👘',
      slot: EquipmentSlot.armor,
      description: '圣魔导师的神圣长袍',
      price: 30000,
      levelReq: 65,
      def: 22,
      intBonus: 12,
    ),
    // 弓箭手 - 箭神系列
    Equipment(
      name: '箭神弓',
      id: 'bowmaster_bow',
      emoji: '🏹',
      slot: EquipmentSlot.weapon,
      description: '箭神的传说之弓',
      price: 40000,
      levelReq: 65,
      atk: 62,
      dex: 24,
      crit: 6,
    ),
    Equipment(
      name: '箭神帽',
      id: 'bowmaster_hat',
      emoji: '🎯',
      slot: EquipmentSlot.helmet,
      description: '箭神的鹰眼之冠',
      price: 25000,
      levelReq: 65,
      def: 20,
      dex: 9,
    ),
    Equipment(
      name: '箭神装',
      id: 'bowmaster_suit',
      emoji: '🦺',
      slot: EquipmentSlot.armor,
      description: '箭神的精灵战甲',
      price: 30000,
      levelReq: 65,
      def: 25,
      dex: 10,
    ),
    // 飞侠 - 夜行者系列 (高级)
    Equipment(
      name: '夜行者之刃',
      id: 'night_lord_dagger',
      emoji: '🗡️',
      slot: EquipmentSlot.weapon,
      description: '夜行者的传说短刀',
      price: 40000,
      levelReq: 65,
      atk: 60,
      luk: 24,
      crit: 7,
    ),
    Equipment(
      name: '夜行者之冠',
      id: 'night_lord_hat',
      emoji: '🎭',
      slot: EquipmentSlot.helmet,
      description: '夜行者的暗影之冠',
      price: 25000,
      levelReq: 65,
      def: 17,
      luk: 9,
      avoid: 4,
    ),
    Equipment(
      name: '夜行者之衣',
      id: 'night_lord_suit',
      emoji: '🥷',
      slot: EquipmentSlot.armor,
      description: '夜行者的暗影战衣',
      price: 30000,
      levelReq: 65,
      def: 21,
      luk: 10,
      avoid: 4,
    ),
    // 海盗 - 船长系列
    Equipment(
      name: '船长指虎',
      id: 'ship_captain_knuckle',
      emoji: '👊',
      slot: EquipmentSlot.weapon,
      description: '船长的传奇指虎',
      price: 40000,
      levelReq: 65,
      atk: 63,
      str: 14,
      dex: 10,
    ),
    Equipment(
      name: '船长帽',
      id: 'ship_captain_hat',
      emoji: '⚓',
      slot: EquipmentSlot.helmet,
      description: '船长的三角帽',
      price: 25000,
      levelReq: 65,
      def: 22,
      str: 6,
      dex: 4,
    ),
    Equipment(
      name: '船长装',
      id: 'ship_captain_suit',
      emoji: '👕',
      slot: EquipmentSlot.armor,
      description: '船长的传奇战袍',
      price: 30000,
      levelReq: 65,
      def: 28,
      str: 7,
      dex: 5,
    ),
    // ========== 通用高级装备 ==========
    Equipment(
      name: '英雄披风',
      id: 'hero_cape',
      emoji: '🧣',
      slot: EquipmentSlot.cape,
      description: '英雄的象征，全属性提升',
      price: 20000,
      levelReq: 40,
      def: 10,
      str: 3,
      dex: 3,
      intBonus: 3,
      luk: 3,
    ),
    Equipment(
      name: '传说披风',
      id: 'legend_cape',
      emoji: '🦸',
      slot: EquipmentSlot.cape,
      description: '传说中的披风，蕴含神秘力量',
      price: 50000,
      levelReq: 60,
      def: 18,
      str: 5,
      dex: 5,
      intBonus: 5,
      luk: 5,
    ),
    Equipment(
      name: '勇士手套',
      id: 'warrior_gauntlet',
      emoji: '🥊',
      slot: EquipmentSlot.gloves,
      description: '勇士的钢铁手套',
      price: 8000,
      levelReq: 35,
      atk: 8,
      def: 6,
      str: 4,
    ),
    Equipment(
      name: '魔导手套',
      id: 'mage_gauntlet',
      emoji: '🧤',
      slot: EquipmentSlot.gloves,
      description: '魔导师的法力手套',
      price: 8000,
      levelReq: 35,
      atk: 5,
      intBonus: 6,
    ),
    Equipment(
      name: '疾风手套',
      id: 'archer_gauntlet',
      emoji: '🧤',
      slot: EquipmentSlot.gloves,
      description: '弓箭手的疾风手套',
      price: 8000,
      levelReq: 35,
      atk: 7,
      dex: 5,
    ),
    Equipment(
      name: '暗影手套',
      id: 'thief_gauntlet',
      emoji: '🧤',
      slot: EquipmentSlot.gloves,
      description: '飞侠的暗影手套',
      price: 8000,
      levelReq: 35,
      atk: 6,
      luk: 5,
      crit: 2,
    ),
    Equipment(
      name: '海盗手套',
      id: 'pirate_gauntlet',
      emoji: '🥊',
      slot: EquipmentSlot.gloves,
      description: '海盗的搏击手套',
      price: 8000,
      levelReq: 35,
      atk: 7,
      str: 3,
      dex: 3,
    ),
    // ========== Boss 专属掉落 ==========
    Equipment(
      name: '蘑菇妈妈的皇冠',
      id: 'mushmom_crown',
      emoji: '👑',
      slot: EquipmentSlot.helmet,
      description: '蘑菇妈妈掉落的稀有皇冠，散发着蘑菇的香气',
      price: 50000,
      levelReq: 25,
      def: 20,
      str: 5,
      dex: 5,
    ),
    Equipment(
      name: '巴洛克的利爪',
      id: 'balrog_claw',
      emoji: '🔥',
      slot: EquipmentSlot.weapon,
      description: '巴洛克的烈焰之爪，蕴含着地狱之火',
      price: 100000,
      levelReq: 50,
      atk: 55,
      str: 15,
      crit: 5,
    ),
    Equipment(
      name: '皮亚努斯之鳞',
      id: 'pianus_scale',
      emoji: '🐟',
      slot: EquipmentSlot.armor,
      description: '皮亚努斯的深海之鳞，蕴含海洋之力',
      price: 150000,
      levelReq: 70,
      def: 50,
      str: 10,
      dex: 10,
      intBonus: 10,
      luk: 10,
    ),
  ];

  /// 根据ID获取装备 - O(1) Map 查询
  static final Map<String, Equipment> _byId = {
    for (final eq in equipments) if (eq.id != null) eq.id!: eq,
  };

  static Equipment? getById(String id) => _byId[id];

  /// 商店出售的装备 (缓存)
  static final List<Equipment> _shopEquipments =
      equipments.where((eq) => (eq.levelReq ?? 1) <= 10).toList(growable: false);
  static List<Equipment> getShopEquipments() => _shopEquipments;

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
