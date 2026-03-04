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
      },
    ),
    'lith': GameMap(
      id: 'lith',
      name: '明珠港',
      description: '海边港口城市，海盗们聚集的地方。',
      emoji: '⚓',
      mobs: [],
      encounterChance: 0.0,
      exits: {
        '北': 'henesys',
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
