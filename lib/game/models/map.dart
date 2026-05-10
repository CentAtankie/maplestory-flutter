import 'mob.dart';

/// 游戏地图
class GameMap {
  String id;
  String name;
  String description;
  String emoji;
  List<MobType> mobs;
  double encounterChance;
  Map<String, String> exits;
  bool isTown;

  GameMap({
    required this.id,
    required this.name,
    required this.description,
    this.emoji = '🗺️',
    this.mobs = const [],
    this.encounterChance = 0.5,
    required this.exits,
    this.isTown = false,
  });
}

/// 地图数据库
class GameMaps {
  static final Map<String, GameMap> _maps = {
    'henesys': GameMap(
      id: 'henesys',
      name: '射手村',
      description: '热闹的村庄，到处可见弓箭手公会的人。这里有温暖的阳光和清新的空气。',
      emoji: '🏘️',
      mobs: [],
      encounterChance: 0.0,
      exits: {
        '东': 'farm',
        '南': 'lith',
        '北': 'perion',
        '西': 'ellinia',
        '公园': 'henesys_park',
      },
      isTown: true,
    ),
    'farm': GameMap(
      id: 'farm',
      name: '射手村东部平原',
      description: '一片绿油油的草地，蜗牛在这里悠闲地爬行。',
      emoji: '🌾',
      mobs: [MobType.snail, MobType.blueSnail, MobType.redSnail],
      encounterChance: 0.6,
      exits: {
        '西': 'henesys',
        '北': 'trail',
        '粉粉熊草原': 'pinkbean_field',
        '丝带乐园': 'ribbon_meadow',
      },
    ),
    'trail': GameMap(
      id: 'trail',
      name: '射手村北部小路',
      description: '蜿蜒的小路旁长满了奇怪的蘑菇。',
      emoji: '🌲',
      mobs: [MobType.mushroom, MobType.blueMushroom],
      encounterChance: 0.5,
      exits: {
        '南': 'farm',
        '东': 'cave',
      },
    ),
    'cave': GameMap(
      id: 'cave',
      name: '树洞',
      description: '阴森的树洞里传来奇怪的声音...',
      emoji: '🕳️',
      mobs: [MobType.hornyMushroom],
      encounterChance: 0.4,
      exits: {
        '西': 'trail',
        '蘑菇妈妈': 'mushmom_cave',
      },
    ),
    'lith': GameMap(
      id: 'lith',
      name: '明珠港',
      description: '海边港口城市，海盗们聚集的地方。从这里可以乘船前往诺特勒斯号。',
      emoji: '⚓',
      mobs: [],
      encounterChance: 0.0,
      exits: {
        '北': 'henesys',
        '船': 'nautilus',
        '海滩': 'octopus_beach',
      },
      isTown: true,
    ),
    'slime_tree': GameMap(
      id: 'slime_tree',
      name: '绿水灵树洞',
      description: '一个充满粘液的大树下，聚集着许多绿水灵。',
      emoji: '🌳',
      mobs: [MobType.slime],
      encounterChance: 0.7,
      exits: {
        '南': 'farm',
        '丝带乐园': 'ribbon_meadow',
      },
    ),
    // 转职地图
    'perion': GameMap(
      id: 'perion',
      name: '勇士部落',
      description: '战士们的聚集地，这里充满了热血与力量。武术教练在这里等待有潜力的冒险家。',
      emoji: '⛺',
      mobs: [],
      encounterChance: 0.0,
      exits: {
        '南': 'henesys',
        '西': 'perion_field',
      },
      isTown: true,
    ),
    'ellinia': GameMap(
      id: 'ellinia',
      name: '魔法密林',
      description: '被魔法笼罩的神秘森林，大魔法师汉斯在这里传授魔法知识。',
      emoji: '🌲',
      mobs: [],
      encounterChance: 0.0,
      exits: {
        '东': 'henesys',
        '东北': 'ellinia_field',
      },
      isTown: true,
    ),
    'henesys_park': GameMap(
      id: 'henesys_park',
      name: '射手村公园',
      description: '射手村的训练场，弓箭手导师赫丽娜在这里指导新手。',
      emoji: '🎯',
      mobs: [],
      encounterChance: 0.0,
      exits: {
        '西': 'henesys',
        '蜗牛花园': 'snail_garden',
      },
      isTown: true,
    ),
    'kerning': GameMap(
      id: 'kerning',
      name: '废弃都市',
      description: '一个充满活力的城市，飞侠导师达克鲁在这里训练暗影行者。',
      emoji: '🏙️',
      mobs: [],
      encounterChance: 0.0,
      exits: {
        '北': 'henesys',
        '南': 'kerning_swamp',
      },
      isTown: true,
    ),
    'nautilus': GameMap(
      id: 'nautilus',
      name: '诺特勒斯号',
      description: '一艘巨大的海盗船，海盗导师凯琳在这里训练海盗新兵。',
      emoji: '⚓',
      mobs: [],
      encounterChance: 0.0,
      exits: {
        '西': 'lith',
      },
      isTown: true,
    ),
    // ========== 勇士部落周边 ==========
    'perion_field': GameMap(
      id: 'perion_field',
      name: '勇士部落西部荒野',
      description: '荒芜的土地，野猪群在这里游荡。',
      emoji: '🏜️',
      mobs: [MobType.wildBoar, MobType.woodenMummy],
      encounterChance: 0.6,
      exits: {
        '东': 'perion',
        '北': 'fire_land1',
      },
    ),
    'fire_land1': GameMap(
      id: 'fire_land1',
      name: '火焰之地I',
      description: '炎热的荒地，木妖和花蘑菇在这里共存。',
      emoji: '🔥',
      mobs: [MobType.woodenMummy, MobType.evilEye],
      encounterChance: 0.65,
      exits: {
        '南': 'perion_field',
        '东': 'fire_land2',
        '北': 'highland1',
      },
    ),
    'fire_land2': GameMap(
      id: 'fire_land2',
      name: '火焰之地II',
      description: '更深入的火焰之地，僵尸蘑菇开始出现。',
      emoji: '🔥',
      mobs: [MobType.evilEye, MobType.zombieMushroom],
      encounterChance: 0.7,
      exits: {
        '西': 'fire_land1',
      },
    ),
    // ========== 魔法密林周边 ==========
    'ellinia_field': GameMap(
      id: 'ellinia_field',
      name: '魔法森林',
      description: '被魔法笼罩的森林深处，奇怪的生物在这里出没。',
      emoji: '🌲',
      mobs: [MobType.woodenMummy, MobType.evilEye],
      encounterChance: 0.6,
      exits: {
        '西': 'ellinia',
        '东': 'ant_tunnel1',
        '北': 'highland1',
      },
    ),
    'ant_tunnel1': GameMap(
      id: 'ant_tunnel1',
      name: '蚂蚁洞入口',
      description: '阴暗潮湿的洞穴入口，僵尸蘑菇在这里滋生。',
      emoji: '🐜',
      mobs: [MobType.zombieMushroom, MobType.fireBoar],
      encounterChance: 0.7,
      exits: {
        '西': 'ellinia_field',
        '东': 'ant_tunnel2',
      },
    ),
    'ant_tunnel2': GameMap(
      id: 'ant_tunnel2',
      name: '蚂蚁洞深处',
      description: '洞穴深处，更强的怪物在这里栖息。',
      emoji: '🐜',
      mobs: [MobType.fireBoar, MobType.stoneGolem],
      encounterChance: 0.75,
      exits: {
        '西': 'ant_tunnel1',
        '冰窟': 'ice_lab',
      },
    ),
    // ========== 废弃都市周边 ==========
    'kerning_swamp': GameMap(
      id: 'kerning_swamp',
      name: '沼泽地',
      description: '废弃都市外围的沼泽，野猪和绿水灵在这里游荡。',
      emoji: '🐸',
      mobs: [MobType.wildBoar, MobType.slime],
      encounterChance: 0.6,
      exits: {
        '北': 'kerning',
        '东': 'subway1',
      },
    ),
    'subway1': GameMap(
      id: 'subway1',
      name: '地铁入口',
      description: '废弃的地铁站入口，黑暗中有蝙蝠怪出没。',
      emoji: '🚇',
      mobs: [MobType.fireBoar, MobType.wraith],
      encounterChance: 0.7,
      exits: {
        '西': 'kerning_swamp',
        '东': 'subway2',
      },
    ),
    'subway2': GameMap(
      id: 'subway2',
      name: '地铁深处',
      description: '地铁深处充满了幽灵，非常危险。',
      emoji: '🚇',
      mobs: [MobType.wraith, MobType.darkStoneGolem],
      encounterChance: 0.8,
      exits: {
        '西': 'subway1',
        '北': 'highland2',
      },
    ),
    // ========== 高级地图 ==========
    'highland1': GameMap(
      id: 'highland1',
      name: '高原I',
      description: '危险的岩石高原，巨大的石头人在此徘徊。',
      emoji: '⛰️',
      mobs: [MobType.stoneGolem, MobType.darkStoneGolem],
      encounterChance: 0.75,
      exits: {
        '南': 'fire_land1',
        '西': 'ellinia_field',
        '东': 'highland2',
      },
    ),
    'highland2': GameMap(
      id: 'highland2',
      name: '高原II',
      description: '更高的海拔，元素生物在这里游荡。',
      emoji: '⛰️',
      mobs: [MobType.iceSentinel, MobType.fireSentinel],
      encounterChance: 0.8,
      exits: {
        '西': 'highland1',
        '南': 'subway2',
        '玩具城': 'ludibrium',
      },
    ),

    // ========== 低级补足地图 ==========
    'snail_garden': GameMap(
      id: 'snail_garden',
      name: '蜗牛花园',
      description: '射手村公园后方的小花园,蜗牛在花丛中悠闲爬行,适合新手练手。',
      emoji: '🌷',
      mobs: [MobType.snail, MobType.blueSnail],
      encounterChance: 0.7,
      exits: {
        '南': 'henesys_park',
      },
    ),
    'pinkbean_field': GameMap(
      id: 'pinkbean_field',
      name: '粉粉熊草原',
      description: '阳光明媚的草原,可爱的粉粉熊在这里跑来跑去。',
      emoji: '🌸',
      mobs: [MobType.pinkBean, MobType.redSnail],
      encounterChance: 0.6,
      exits: {
        '西': 'farm',
        '南': 'octopus_beach',
      },
    ),
    'octopus_beach': GameMap(
      id: 'octopus_beach',
      name: '八爪鱼海滩',
      description: '明珠港旁的沙滩,八爪鱼从浅水中爬上岸。',
      emoji: '🏖️',
      mobs: [MobType.octopus, MobType.pinkBean],
      encounterChance: 0.65,
      exits: {
        '北': 'pinkbean_field',
        '西': 'lith',
      },
    ),
    'ribbon_meadow': GameMap(
      id: 'ribbon_meadow',
      name: '丝带乐园',
      description: '丝带猪们结伴出没,空气里飘着甜甜的味道。',
      emoji: '🎀',
      mobs: [MobType.ribbonPig, MobType.slime],
      encounterChance: 0.65,
      exits: {
        '北': 'slime_tree',
        '东': 'farm',
      },
    ),
    'ice_lab': GameMap(
      id: 'ice_lab',
      name: '冰师傅实验室',
      description: '蚂蚁洞深处的隐秘冰窟,寒气逼人。',
      emoji: '🧊',
      mobs: [MobType.iceMaster, MobType.zombieMushroom],
      encounterChance: 0.7,
      exits: {
        '西': 'ant_tunnel2',
      },
    ),

    // ========== 玩具城 (高级 hub) ==========
    'ludibrium': GameMap(
      id: 'ludibrium',
      name: '玩具城',
      description: '飘浮在云层之上的玩具王国,机械与魔法交织,高级冒险家的中转站。',
      emoji: '🎪',
      mobs: [],
      encounterChance: 0.0,
      exits: {
        '高原': 'highland2',
        '工厂': 'toy_factory1',
        '钟楼': 'clock_tower',
        '丛林': 'jungle_path',
        '港口': 'aqua_road',
      },
      isTown: true,
    ),

    // ========== 玩具城周边 (50-75 级) ==========
    'toy_factory1': GameMap(
      id: 'toy_factory1',
      name: '玩具工厂 I',
      description: '吱嘎作响的传送带,黑色绫翅在通风管道中乱窜。',
      emoji: '🏭',
      mobs: [MobType.darkLeatty, MobType.wraith],
      encounterChance: 0.75,
      exits: {
        '玩具城': 'ludibrium',
        '深处': 'toy_factory2',
      },
    ),
    'toy_factory2': GameMap(
      id: 'toy_factory2',
      name: '玩具工厂 II',
      description: '工厂深处,大量幸运猴躲在堆积的玩具盒里偷袭。',
      emoji: '🏭',
      mobs: [MobType.luckyMonkey, MobType.darkLeatty],
      encounterChance: 0.8,
      exits: {
        '入口': 'toy_factory1',
      },
    ),
    'aqua_road': GameMap(
      id: 'aqua_road',
      name: '水上街道',
      description: '玩具城下方的海洋街区,鳄鱼怪在水道中潜伏。',
      emoji: '🌊',
      mobs: [MobType.crocky, MobType.luckyMonkey],
      encounterChance: 0.75,
      exits: {
        '玩具城': 'ludibrium',
        '深海': 'pianus_lair',
      },
    ),
    'jungle_path': GameMap(
      id: 'jungle_path',
      name: '神秘丛林',
      description: '玩具城南面的原始丛林,小赛罗群在树梢间穿梭。',
      emoji: '🌴',
      mobs: [MobType.jrCelion, MobType.crocky],
      encounterChance: 0.78,
      exits: {
        '玩具城': 'ludibrium',
        '深处': 'clock_tower',
      },
    ),
    'clock_tower': GameMap(
      id: 'clock_tower',
      name: '钟楼地下',
      description: '钟摆的滴答声回荡,时间守护者审视着每一个闯入者。',
      emoji: '⏰',
      mobs: [MobType.masterChronos, MobType.jrCelion],
      encounterChance: 0.82,
      exits: {
        '玩具城': 'ludibrium',
        '丛林': 'jungle_path',
        '深渊': 'balrog_pit',
      },
    ),

    // ========== Boss 地图 (单怪高 HP / 高奖励) ==========
    'mushmom_cave': GameMap(
      id: 'mushmom_cave',
      name: '蘑菇妈妈巢穴',
      description: '⚠️ Boss 关:树洞最深处,蘑菇妈妈在此守护幼崽。建议 25 级以上挑战。',
      emoji: '👹',
      mobs: [MobType.mushmom],
      encounterChance: 1.0,
      exits: {
        '树洞': 'cave',
      },
    ),
    'balrog_pit': GameMap(
      id: 'balrog_pit',
      name: '巴洛克之坑',
      description: '⚠️ Boss 关:钟楼下方的火山深渊,小巴洛克在此沉睡。建议 50 级以上挑战。',
      emoji: '🦂',
      mobs: [MobType.balrogJr],
      encounterChance: 1.0,
      exits: {
        '钟楼': 'clock_tower',
      },
    ),
    'pianus_lair': GameMap(
      id: 'pianus_lair',
      name: '黑龙王洞',
      description: '⚠️ Boss 关:水上街道尽头的海底洞穴,黑龙王在此盘踞。建议 75 级以上挑战。',
      emoji: '🐉',
      mobs: [MobType.pianus],
      encounterChance: 1.0,
      exits: {
        '水上街道': 'aqua_road',
      },
    ),
  };

  /// 获取地图
  static GameMap getMap(String id) {
    return _maps[id] ?? _maps['henesys']!;
  }

  /// 获取所有地图
  static List<GameMap> getAllMaps() {
    return _maps.values.toList();
  }

  /// 获取所有城镇
  static List<GameMap> getTowns() {
    return _maps.values.where((m) => m.isTown).toList();
  }

  /// 获取所有野外地图
  static List<GameMap> getFields() {
    return _maps.values.where((m) => !m.isTown).toList();
  }
}
