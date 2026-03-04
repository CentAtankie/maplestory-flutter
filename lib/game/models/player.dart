import 'package:flutter/material.dart';

/// 职业类型
enum Job {
  beginner('新手', '🙂', Color(0xFF9E9E9E)),
  warrior('战士', '⚔️', Color(0xFFE53935)),
  magician('法师', '🔮', Color(0xFF1E88E5)),
  bowman('弓箭手', '🏹', Color(0xFF43A047)),
  thief('飞侠', '🗡️', Color(0xFF8E24AA)),
  pirate('海盗', '⚓', Color(0xFFFDD835));

  final String displayName;
  final String emoji;
  final Color color;

  const Job(this.displayName, this.emoji, this.color);
}

/// 玩家属性
class Stats {
  int str;
  int dex;
  int intStat;
  int luk;
  int hp;
  int maxHp;
  int mp;
  int maxMp;
  int level;
  int exp;
  int maxExp;

  Stats({
    this.str = 12,
    this.dex = 5,
    this.intStat = 4,
    this.luk = 4,
    this.hp = 50,
    this.maxHp = 50,
    this.mp = 5,
    this.maxMp = 5,
    this.level = 1,
    this.exp = 0,
    this.maxExp = 15,
  });

  Stats copyWith({
    int? str,
    int? dex,
    int? intStat,
    int? luk,
    int? hp,
    int? maxHp,
    int? mp,
    int? maxMp,
    int? level,
    int? exp,
    int? maxExp,
  }) {
    return Stats(
      str: str ?? this.str,
      dex: dex ?? this.dex,
      intStat: intStat ?? this.intStat,
      luk: luk ?? this.luk,
      hp: hp ?? this.hp,
      maxHp: maxHp ?? this.maxHp,
      mp: mp ?? this.mp,
      maxMp: maxMp ?? this.maxMp,
      level: level ?? this.level,
      exp: exp ?? this.exp,
      maxExp: maxExp ?? this.maxExp,
    );
  }
}

/// 装备槽位
enum EquipmentSlot {
  weapon,
  helmet,
  armor,
  pants,
  shoes,
  cape,
}

/// 装备
class Equipment {
  String name;
  EquipmentSlot slot;
  int atk;
  int def;
  int str;
  int dex;
  int intBonus;
  int luk;

  Equipment({
    required this.name,
    required this.slot,
    this.atk = 0,
    this.def = 0,
    this.str = 0,
    this.dex = 0,
    this.intBonus = 0,
    this.luk = 0,
  });
}

/// 装备数据库
final Map<String, Equipment> equipmentDb = {
  '新手短剑': Equipment(
    name: '新手短剑',
    slot: EquipmentSlot.weapon,
    atk: 3,
  ),
  '木质短杖': Equipment(
    name: '木质短杖',
    slot: EquipmentSlot.weapon,
    atk: 5,
  ),
  '新手弓': Equipment(
    name: '新手弓',
    slot: EquipmentSlot.weapon,
    atk: 4,
  ),
  '蜗牛壳': Equipment(
    name: '蜗牛壳',
    slot: EquipmentSlot.helmet,
    def: 1,
  ),
  '旧披风': Equipment(
    name: '旧披风',
    slot: EquipmentSlot.cape,
    def: 1,
  ),
};

/// 玩家
class Player {
  String name;
  Job job;
  Stats stats;
  Map<EquipmentSlot, Equipment?> equipment;
  List<String> inventory;
  String currentMap;
  int meso;

  Player({
    required this.name,
    this.job = Job.beginner,
    required this.stats,
    Map<EquipmentSlot, Equipment?>? equipment,
    List<String>? inventory,
    this.currentMap = 'henesys',
    this.meso = 0,
  })  : equipment = equipment ?? {
          EquipmentSlot.weapon: equipmentDb['新手短剑'],
          EquipmentSlot.helmet: null,
          EquipmentSlot.armor: null,
          EquipmentSlot.pants: null,
          EquipmentSlot.shoes: null,
          EquipmentSlot.cape: null,
        },
        inventory = inventory ?? [];

  /// 创建新玩家
  factory Player.create(String name) {
    return Player(
      name: name,
      job: Job.beginner,
      stats: Stats(),
    );
  }

  /// 获取基础攻击力
  int get baseAtk => stats.str ~/ 5 + stats.dex ~/ 5;

  /// 获取总攻击力
  int getAtk() {
    final weaponAtk = equipment[EquipmentSlot.weapon]?.atk ?? 0;
    return baseAtk + weaponAtk;
  }

  /// 获取总防御力
  int getDef() {
    return equipment.values
        .where((e) => e != null)
        .fold(0, (sum, e) => sum + e!.def);
  }

  /// 复制玩家
  Player copyWith({
    String? name,
    Job? job,
    Stats? stats,
    Map<EquipmentSlot, Equipment?>? equipment,
    List<String>? inventory,
    String? currentMap,
    int? meso,
  }) {
    return Player(
      name: name ?? this.name,
      job: job ?? this.job,
      stats: stats ?? this.stats,
      equipment: equipment ?? this.equipment,
      inventory: inventory ?? this.inventory,
      currentMap: currentMap ?? this.currentMap,
      meso: meso ?? this.meso,
    );
  }
}
