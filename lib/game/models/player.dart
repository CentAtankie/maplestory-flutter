import 'dart:math';
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
  int ap;  // 自由属性点 (Ability Points)

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
    this.ap = 0,  // 初始没有自由属性点
  });

  /// 计算暴击率 (基于运气, 最高40%)
  double getCritRate() {
    return (luk * 0.3).clamp(0, 40);
  }

  /// 计算闪避率 (基于敏捷, 最高40%)
  double getAvoidRate() {
    return (dex * 0.3).clamp(0, 40);
  }

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
    int? ap,
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
      ap: ap ?? this.ap,
    );
  }
}

/// 装备槽位
enum EquipmentSlot {
  weapon,   // 武器
  helmet,   // 头盔
  armor,    // 衣服
  pants,    // 裤子
  shoes,    // 鞋子
  cape,     // 披风
  shield,   // 盾牌
  gloves,   // 手套
}

/// 装备
class Equipment {
  String name;
  String? id;           // 装备类型ID
  String instanceId;    // 装备实例唯一ID (UUID) - 必须有值
  String? emoji;
  String? description;
  EquipmentSlot slot;
  int atk;
  int def;
  int str;
  int dex;
  int intBonus;
  int luk;
  int? price;
  int? levelReq;
  int? crit;     // 暴击率加成
  int? avoid;    // 闪避率加成

  Equipment({
    required this.name,
    this.id,
    String? instanceId,  // 可选参数，不传则自动生成
    this.emoji,
    this.description,
    required this.slot,
    this.atk = 0,
    this.def = 0,
    this.str = 0,
    this.dex = 0,
    this.intBonus = 0,
    this.luk = 0,
    this.price,
    this.levelReq,
    this.crit,
    this.avoid,
  }) : instanceId = instanceId ?? _generateUuid();  // 自动分配UUID

  /// 获取装备属性描述
  String get stats {
    final statsList = <String>[];
    if (atk > 0) statsList.add('攻击+$atk');
    if (def > 0) statsList.add('防御+$def');
    if (str > 0) statsList.add('力量+$str');
    if (dex > 0) statsList.add('敏捷+$dex');
    if (intBonus > 0) statsList.add('智力+$intBonus');
    if (luk > 0) statsList.add('运气+$luk');
    if (crit != null && crit! > 0) statsList.add('暴击+$crit%');
    if (avoid != null && avoid! > 0) statsList.add('闪避+$avoid%');
    return statsList.join(', ');
  }

  /// 复制装备并生成新的实例ID
  Equipment copyWithInstanceId({String? newInstanceId}) {
    return Equipment(
      name: name,
      id: id,
      instanceId: newInstanceId ?? _generateUuid(),
      emoji: emoji,
      description: description,
      slot: slot,
      atk: atk,
      def: def,
      str: str,
      dex: dex,
      intBonus: intBonus,
      luk: luk,
      price: price,
      levelReq: levelReq,
      crit: crit,
      avoid: avoid,
    );
  }

  /// 生成简单的UUID
  static String _generateUuid() {
    final random = Random();
    return '${_randomHex(random, 8)}-${_randomHex(random, 4)}-${_randomHex(random, 4)}-${_randomHex(random, 4)}-${_randomHex(random, 12)}';
  }

  static String _randomHex(Random random, int length) {
    const chars = '0123456789abcdef';
    return List.generate(length, (_) => chars[random.nextInt(16)]).join();
  }
}

/// 装备数据库
final Map<String, Equipment> equipmentDb = {
  'beginner_sword': Equipment(
    id: 'beginner_sword',
    name: '新手短剑',
    slot: EquipmentSlot.weapon,
    atk: 3,
  ),
  'wooden_staff': Equipment(
    id: 'wooden_staff',
    name: '木质短杖',
    slot: EquipmentSlot.weapon,
    atk: 5,
  ),
  'beginner_bow': Equipment(
    id: 'beginner_bow',
    name: '新手弓',
    slot: EquipmentSlot.weapon,
    atk: 4,
  ),
  'snail_shell_helmet': Equipment(
    id: 'snail_shell_helmet',
    name: '蜗牛壳',
    slot: EquipmentSlot.helmet,
    def: 1,
  ),
  'old_cape': Equipment(
    id: 'old_cape',
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
          EquipmentSlot.weapon: equipmentDb['beginner_sword'],
          EquipmentSlot.helmet: null,
          EquipmentSlot.armor: null,
          EquipmentSlot.pants: null,
          EquipmentSlot.shoes: null,
          EquipmentSlot.cape: null,
        },
        inventory = inventory ?? [];

  /// 创建新玩家 - 投骰子决定初始属性 (总25点，每个4-13)
  factory Player.create(String name, {Random? random}) {
    final rnd = random ?? Random();
    
    // 分配25点属性，每个属性4-13点
    final stats = _distributeStats(rnd);
    
    return Player(
      name: name,
      job: Job.beginner,
      stats: Stats(
        str: stats[0],
        dex: stats[1],
        intStat: stats[2],
        luk: stats[3],
        hp: 50,
        maxHp: 50,
        mp: 5,
        maxMp: 5,
        level: 1,
        exp: 0,
        maxExp: 15,
        ap: 0,
      ),
    );
  }
  
  /// 分配25点属性，每个属性4-13点
  static List<int> _distributeStats(Random random) {
    // 先给每个属性分配最低4点 (共16点)
    var remaining = 9; // 25 - 16 = 9点需要分配
    
    // 随机分配剩余点数，确保类型为int
    var strBonus = random.nextInt(remaining + 1);
    if (strBonus > 9) strBonus = 9;
    remaining -= strBonus;
    
    var dexBonus = random.nextInt(remaining + 1);
    if (dexBonus > 9) dexBonus = 9;
    remaining -= dexBonus;
    
    var intBonus = random.nextInt(remaining + 1);
    if (intBonus > 9) intBonus = 9;
    remaining -= intBonus;
    
    // 剩余全给运气
    var lukBonus = remaining;
    if (lukBonus > 9) lukBonus = 9;
    
    return [
      4 + strBonus,
      4 + dexBonus,
      4 + intBonus,
      4 + lukBonus,
    ];
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

  /// 获取暴击率 (基础 + 装备加成, 最高50%)
  double getCritRate() {
    final baseCrit = stats.getCritRate();
    final equipCrit = equipment.values
        .where((e) => e != null)
        .fold(0, (sum, e) => sum + (e!.crit ?? 0));
    return (baseCrit + equipCrit).clamp(0, 50);
  }

  /// 获取闪避率 (基础 + 装备加成, 最高50%)
  double getAvoidRate() {
    final baseAvoid = stats.getAvoidRate();
    final equipAvoid = equipment.values
        .where((e) => e != null)
        .fold(0, (sum, e) => sum + (e!.avoid ?? 0));
    return (baseAvoid + equipAvoid).clamp(0, 50);
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
