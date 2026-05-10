import 'dart:math';
import 'package:flutter/material.dart';
import 'potential.dart';
import 'status_effect.dart';

/// 职业类型
///
/// 一转: warrior/magician/bowman/thief/pirate (10 级)
/// 二转: fighter/fpMage/hunter/assassin/brawler (30 级)
/// **添加新职业必须 append 到末尾**,否则破坏现有存档 (Job.values[index])
enum Job {
  beginner('新手', '🙂', Color(0xFF9E9E9E)),
  warrior('战士', '⚔️', Color(0xFFE53935)),
  magician('法师', '🔮', Color(0xFF1E88E5)),
  bowman('弓箭手', '🏹', Color(0xFF43A047)),
  thief('飞侠', '🗡️', Color(0xFF8E24AA)),
  pirate('海盗', '⚓', Color(0xFFFDD835)),
  // ===== 二转 =====
  fighter('剑客', '🗡️', Color(0xFFB71C1C)),
  fpMage('火法师', '🔥', Color(0xFFD84315)),
  hunter('猎人', '🎯', Color(0xFF1B5E20)),
  assassin('刺客', '🌑', Color(0xFF4A148C)),
  brawler('拳手', '👊', Color(0xFFF57F17));

  final String displayName;
  final String emoji;
  final Color color;

  const Job(this.displayName, this.emoji, this.color);

  /// 转职等级 (1=新手, 2=一转, 3=二转)
  int get tier {
    switch (this) {
      case Job.beginner:
        return 1;
      case Job.warrior:
      case Job.magician:
      case Job.bowman:
      case Job.thief:
      case Job.pirate:
        return 2;
      case Job.fighter:
      case Job.fpMage:
      case Job.hunter:
      case Job.assassin:
      case Job.brawler:
        return 3;
    }
  }

  /// 主属性 (用于攻击伤害计算)
  JobStat get mainStat {
    switch (this) {
      case Job.beginner:
        return JobStat.str;
      case Job.warrior:
      case Job.fighter:
      case Job.pirate:
      case Job.brawler:
        return JobStat.str;
      case Job.magician:
      case Job.fpMage:
        return JobStat.intStat;
      case Job.bowman:
      case Job.hunter:
        return JobStat.dex;
      case Job.thief:
      case Job.assassin:
        return JobStat.luk;
    }
  }

  /// 副属性
  JobStat get subStat {
    switch (this) {
      case Job.beginner:
        return JobStat.dex;
      case Job.warrior:
      case Job.fighter:
        return JobStat.dex;
      case Job.pirate:
      case Job.brawler:
        return JobStat.dex;
      case Job.magician:
      case Job.fpMage:
        return JobStat.luk;
      case Job.bowman:
      case Job.hunter:
        return JobStat.str;
      case Job.thief:
      case Job.assassin:
        return JobStat.dex;
    }
  }

  /// 升级时 maxHp 增长
  int get hpPerLevel {
    switch (this) {
      case Job.beginner:
        return 10;
      case Job.warrior:
        return 20;
      case Job.fighter:
        return 25;
      case Job.magician:
        return 5;
      case Job.fpMage:
        return 5;
      case Job.bowman:
        return 14;
      case Job.hunter:
        return 18;
      case Job.thief:
        return 12;
      case Job.assassin:
        return 14;
      case Job.pirate:
        return 16;
      case Job.brawler:
        return 20;
    }
  }

  /// 升级时 maxMp 增长
  int get mpPerLevel {
    switch (this) {
      case Job.beginner:
        return 5;
      case Job.warrior:
      case Job.fighter:
        return 3;
      case Job.magician:
        return 14;
      case Job.fpMage:
        return 18;
      case Job.bowman:
        return 8;
      case Job.hunter:
        return 10;
      case Job.thief:
      case Job.assassin:
        return 10;
      case Job.pirate:
        return 6;
      case Job.brawler:
        return 6;
    }
  }

  /// 暴击率加成 (在 LUK 基础上加)
  double get critBonus {
    switch (this) {
      case Job.bowman:
        return 5;
      case Job.hunter:
        return 8;
      case Job.thief:
        return 10;
      case Job.assassin:
        return 15;
      default:
        return 0;
    }
  }

  /// 闪避率加成 (在 DEX 基础上加)
  double get avoidBonus {
    switch (this) {
      case Job.thief:
        return 5;
      case Job.assassin:
        return 7;
      default:
        return 0;
    }
  }

  /// 推荐主加点提示 (用于 UI)
  String get recommendedStat {
    switch (mainStat) {
      case JobStat.str:
        return '推荐主加 力量(STR)';
      case JobStat.dex:
        return '推荐主加 敏捷(DEX)';
      case JobStat.intStat:
        return '推荐主加 智力(INT)';
      case JobStat.luk:
        return '推荐主加 运气(LUK)';
    }
  }

  /// 是否为 Boss 职业 (二转及以上)
  bool get isAdvanced => tier >= 3;

  // ========== 职业被动 ==========

  /// 受到伤害减免比例 (0.10 = -10% 伤害)
  /// 战士系坦克专属
  double get damageReduction {
    switch (this) {
      case Job.warrior:
        return 0.10;
      case Job.fighter:
        return 0.18;
      default:
        return 0.0;
    }
  }

  /// 击杀怪物后回复 MaxMP 的比例 (0.10 = +10% MaxMP)
  /// 法师系续航专属
  double get mpRegenOnKill {
    switch (this) {
      case Job.magician:
        return 0.10;
      case Job.fpMage:
        return 0.15;
      default:
        return 0.0;
    }
  }

  /// 暴击伤害倍率 (默认 1.5,弓箭手系更高)
  double get critDamageMultiplier {
    switch (this) {
      case Job.bowman:
        return 1.75;
      case Job.hunter:
        return 2.0;
      default:
        return 1.5;
    }
  }

  /// 攻击/技能命中后追加打击的概率 (0.0-1.0)
  /// 海盗系连击专属
  double get extraHitChance {
    switch (this) {
      case Job.pirate:
        return 0.30;
      case Job.brawler:
        return 0.45;
      case Job.assassin:
        return 0.30; // 刺客飞镖追打
      default:
        return 0.0;
    }
  }

  /// 追加打击的伤害比例 (相对于本次伤害)
  double get extraHitDamageRatio {
    switch (this) {
      case Job.pirate:
        return 0.5;
      case Job.brawler:
        return 0.7;
      case Job.assassin:
        return 0.5;
      default:
        return 0.0;
    }
  }

  /// 被动描述 (用于角色面板/任务对话框展示)
  String get passiveDescription {
    final parts = <String>[];
    if (damageReduction > 0) {
      parts.add('🛡️ 受伤减免 -${(damageReduction * 100).toInt()}%');
    }
    if (mpRegenOnKill > 0) {
      parts.add('💧 击杀回复 MP +${(mpRegenOnKill * 100).toInt()}%');
    }
    if (critDamageMultiplier > 1.5) {
      parts.add('💥 暴击伤害 ×${critDamageMultiplier.toStringAsFixed(2)}');
    }
    if (extraHitChance > 0) {
      parts.add('⚡ ${(extraHitChance * 100).toInt()}% 概率追打 (${(extraHitDamageRatio * 100).toInt()}% 伤害)');
    }
    if (critBonus > 0) {
      parts.add('🎯 暴击率 +${critBonus.toInt()}%');
    }
    if (avoidBonus > 0) {
      parts.add('💨 闪避率 +${avoidBonus.toInt()}%');
    }
    return parts.isEmpty ? '无特殊被动' : parts.join('\n');
  }

  /// 职业独享主动技能
  JobSkill get skill {
    switch (this) {
      case Job.beginner:
        return const JobSkill(
          name: '挥拳',
          emoji: '✊',
          multiplier: 1.4,
          mpCost: 3,
          description: '新手的微弱一击',
        );
      case Job.warrior:
        return const JobSkill(
          name: '重击',
          emoji: '💥',
          multiplier: 2.5,
          mpCost: 5,
          description: '战士的近战重击',
        );
      case Job.fighter:
        return const JobSkill(
          name: '旋风斩',
          emoji: '🌀',
          multiplier: 3.5,
          mpCost: 8,
          description: '剑客的范围斩击',
        );
      case Job.magician:
        return const JobSkill(
          name: '魔法弹',
          emoji: '✨',
          multiplier: 2.5,
          mpCost: 8,
          description: '法师的元素弹',
        );
      case Job.fpMage:
        return const JobSkill(
          name: '火球术',
          emoji: '🔥',
          multiplier: 3.8,
          mpCost: 14,
          description: '火法师的烈焰冲击',
        );
      case Job.bowman:
        return const JobSkill(
          name: '多重射击',
          emoji: '🏹',
          multiplier: 2.8,
          mpCost: 10,
          description: '弓箭手的连射',
        );
      case Job.hunter:
        return const JobSkill(
          name: '三连射',
          emoji: '🎯',
          multiplier: 4.0,
          mpCost: 15,
          description: '猎人的三段连射',
        );
      case Job.thief:
        return const JobSkill(
          name: '暗杀',
          emoji: '🌑',
          multiplier: 2.0,
          mpCost: 12,
          alwaysCrit: true,
          description: '飞侠的必暴击攻击',
        );
      case Job.assassin:
        return const JobSkill(
          name: '幸运七',
          emoji: '🎴',
          multiplier: 2.8,
          mpCost: 16,
          alwaysCrit: true,
          description: '刺客的双飞镖必杀',
        );
      case Job.pirate:
        return const JobSkill(
          name: '回旋踢',
          emoji: '🦵',
          multiplier: 2.6,
          mpCost: 8,
          description: '海盗的旋风踢',
        );
      case Job.brawler:
        return const JobSkill(
          name: '裂拳',
          emoji: '👊',
          multiplier: 3.6,
          mpCost: 12,
          description: '拳手的爆裂连击',
        );
    }
  }

  /// 第二技能 (Buff / Utility)
  JobSkill? get secondSkill {
    switch (this) {
      case Job.beginner:
        return null;
      case Job.warrior:
        return const JobSkill(
          name: '钢铁意志',
          emoji: '🛡️',
          multiplier: 0,
          mpCost: 8,
          description: '3回合内防御力+50%',
          effectType: SkillEffectType.buff,
        );
      case Job.fighter:
        return const JobSkill(
          name: '战吼',
          emoji: '📢',
          multiplier: 0,
          mpCost: 10,
          description: '3回合内攻击力+30%',
          effectType: SkillEffectType.buff,
        );
      case Job.magician:
        return const JobSkill(
          name: '魔法盾',
          emoji: '🔮',
          multiplier: 0,
          mpCost: 12,
          description: '3回合内受到伤害优先扣除MP',
          effectType: SkillEffectType.buff,
        );
      case Job.fpMage:
        return const JobSkill(
          name: '火墙',
          emoji: '🔥',
          multiplier: 0,
          mpCost: 15,
          description: '下回合攻击必定附带燃烧',
          effectType: SkillEffectType.special,
        );
      case Job.bowman:
        return const JobSkill(
          name: '蓄力',
          emoji: '🏹',
          multiplier: 0,
          mpCost: 8,
          description: '下回合攻击必定暴击',
          effectType: SkillEffectType.special,
        );
      case Job.hunter:
        return const JobSkill(
          name: '鹰眼',
          emoji: '👁️',
          multiplier: 0,
          mpCost: 10,
          description: '3回合内暴击率+15%',
          effectType: SkillEffectType.buff,
        );
      case Job.thief:
        return const JobSkill(
          name: '隐身',
          emoji: '🌑',
          multiplier: 0,
          mpCost: 10,
          description: '下回合必定闪避怪物攻击',
          effectType: SkillEffectType.special,
        );
      case Job.assassin:
        return const JobSkill(
          name: '暗影步',
          emoji: '💨',
          multiplier: 0,
          mpCost: 14,
          description: '下回合连续攻击2次',
          effectType: SkillEffectType.special,
        );
      case Job.pirate:
        return const JobSkill(
          name: '霸气',
          emoji: '💪',
          multiplier: 0,
          mpCost: 8,
          description: '3回合内攻击力+20%',
          effectType: SkillEffectType.buff,
        );
      case Job.brawler:
        return const JobSkill(
          name: '铁布衫',
          emoji: '🛡️',
          multiplier: 0,
          mpCost: 12,
          description: '3回合内防御+30%且反弹20%伤害',
          effectType: SkillEffectType.buff,
        );
    }
  }

  /// 觉醒技能 - 三转后的强化版技能
  /// 仅二转职业有觉醒技能，基础职业返回null
  JobSkill? get awakenedSkill {
    switch (this) {
      case Job.beginner:
      case Job.warrior:
      case Job.magician:
      case Job.bowman:
      case Job.thief:
      case Job.pirate:
        return null;
      case Job.fighter:
        return const JobSkill(
          name: '终极剑气',
          emoji: '⚡',
          multiplier: 5.5,
          mpCost: 20,
          description: '觉醒！释放毁灭性剑气，无视防御',
        );
      case Job.fpMage:
        return const JobSkill(
          name: '陨石术',
          emoji: '☄️',
          multiplier: 6.0,
          mpCost: 25,
          description: '觉醒！召唤陨石毁灭一切',
        );
      case Job.hunter:
        return const JobSkill(
          name: '箭雨',
          emoji: '🌧️',
          multiplier: 5.2,
          mpCost: 22,
          description: '觉醒！万箭齐发，覆盖全场',
        );
      case Job.assassin:
        return const JobSkill(
          name: '暗影风暴',
          emoji: '🌑',
          multiplier: 4.5,
          mpCost: 24,
          alwaysCrit: true,
          description: '觉醒！暗影分身同时攻击',
        );
      case Job.brawler:
        return const JobSkill(
          name: '海啸拳',
          emoji: '🌊',
          multiplier: 5.0,
          mpCost: 20,
          description: '觉醒！拳劲如海啸般席卷',
        );
    }
  }
}

/// 主属性枚举
enum JobStat { str, dex, intStat, luk }

/// 技能效果类型
enum SkillEffectType { damage, buff, special }

/// 职业独享技能描述
class JobSkill {
  final String name;
  final String emoji;
  final double multiplier;
  final int mpCost;
  final bool alwaysCrit;
  final String description;
  final SkillEffectType effectType;

  const JobSkill({
    required this.name,
    required this.emoji,
    required this.multiplier,
    required this.mpCost,
    this.alwaysCrit = false,
    required this.description,
    this.effectType = SkillEffectType.damage,
  });
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
  int sp;  // 技能点 (Skill Points) - 升级技能用

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
    this.ap = 0,
    this.sp = 0,
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
    int? sp,
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
      sp: sp ?? this.sp,
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
  EquipmentPotential? potential; // 潜能属性
  String? setName; // 装备套装名称

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
    this.potential,
    this.setName,
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
      potential: potential,
      setName: setName,
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
  Map<String, int> skillLevels; // key: Job.name, value: 0-10 技能等级
  List<StatusEffect> statusEffects; // 战斗中的状态效果
  bool isAwakened; // 三转觉醒状态

  /// 最大技能等级
  static const int maxSkillLevel = 10;

  /// 升级技能所需 SP (从当前级到下一级)
  static int skillUpgradeCost(int currentLevel) => currentLevel + 1;

  /// 当前职业的技能等级
  int get currentSkillLevel => skillLevels[job.name] ?? 0;

  /// 当前职业技能的最终倍率 (基础 + 等级加成)
  /// 每级 +5% 基础倍率,10 级 +50%
  double get skillFinalMultiplier =>
      job.skill.multiplier * (1 + currentSkillLevel * 0.05);

  Player({
    required this.name,
    this.job = Job.beginner,
    required this.stats,
    Map<EquipmentSlot, Equipment?>? equipment,
    List<String>? inventory,
    this.currentMap = 'henesys',
    this.meso = 0,
    Map<String, int>? skillLevels,
    List<StatusEffect>? statusEffects,
    this.isAwakened = false,
  })  : equipment = equipment ?? {
          EquipmentSlot.weapon: equipmentDb['beginner_sword'],
          EquipmentSlot.helmet: null,
          EquipmentSlot.armor: null,
          EquipmentSlot.pants: null,
          EquipmentSlot.shoes: null,
          EquipmentSlot.cape: null,
        },
        inventory = inventory ?? [],
        skillLevels = skillLevels ?? {},
        statusEffects = statusEffects ?? [];

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

  /// 获取基础攻击力 - 按职业主属性计算
  int get baseAtk {
    final main = _totalForStat(job.mainStat);
    final sub = _totalForStat(job.subStat);
    return main ~/ 4 + sub ~/ 8;
  }

  /// 根据 JobStat 取出 base + 装备总值
  int _totalForStat(JobStat stat) {
    switch (stat) {
      case JobStat.str:
        return totalStr;
      case JobStat.dex:
        return totalDex;
      case JobStat.intStat:
        return totalInt;
      case JobStat.luk:
        return totalLuk;
    }
  }
  
  /// 获取装备攻击加成（武器基础+潜能）
  int get equipAtk {
    int bonus = 0;
    // 武器基础攻击
    bonus += equipment[EquipmentSlot.weapon]?.atk ?? 0;
    // 所有装备潜能攻击加成
    for (final equip in equipment.values.where((e) => e != null)) {
      bonus += equip!.potential?.stats
          .where((s) => s.type == PotentialType.atk)
          .fold<int>(0, (sum, s) => sum + (s.value ?? 0)) ?? 0;
    }
    return bonus;
  }

  /// 获取总攻击力
  int getAtk() => baseAtk + equipAtk;

  /// 获取基础防御力
  int get baseDef => 0;
  
  /// 获取装备防御加成（基础+潜能）
  int get equipDef {
    int bonus = 0;
    // 装备基础防御
    bonus += equipment.values
        .where((e) => e != null)
        .fold<int>(0, (sum, e) => sum + (e!.def));
    // 潜能防御加成
    for (final equip in equipment.values.where((e) => e != null)) {
      bonus += equip!.potential?.stats
          .where((s) => s.type == PotentialType.def)
          .fold<int>(0, (sum, s) => sum + (s.value ?? 0)) ?? 0;
    }
    return bonus;
  }

  /// 获取总防御力
  int getDef() => baseDef + equipDef;

  /// 获取基础力量
  int get baseStr => stats.str;
  
  /// 获取装备力量加成（基础+潜能）
  int get equipStr {
    int bonus = 0;
    for (final equip in equipment.values.where((e) => e != null)) {
      bonus += equip!.str;
      bonus += equip.potential?.stats
          .where((s) => s.type == PotentialType.str)
          .fold<int>(0, (sum, s) => sum + (s.value ?? 0)) ?? 0;
    }
    return bonus;
  }
  
  /// 获取总力量
  int get totalStr => baseStr + equipStr;
  
  /// 获取基础敏捷
  int get baseDex => stats.dex;
  
  /// 获取装备敏捷加成
  int get equipDex {
    int bonus = 0;
    for (final equip in equipment.values.where((e) => e != null)) {
      bonus += equip!.dex;
      bonus += equip.potential?.stats
          .where((s) => s.type == PotentialType.dex)
          .fold<int>(0, (sum, s) => sum + (s.value ?? 0)) ?? 0;
    }
    return bonus;
  }
  
  /// 获取总敏捷
  int get totalDex => baseDex + equipDex;
  
  /// 获取基础智力
  int get baseInt => stats.intStat;
  
  /// 获取装备智力加成
  int get equipInt {
    int bonus = 0;
    for (final equip in equipment.values.where((e) => e != null)) {
      bonus += equip!.intBonus;
      bonus += equip.potential?.stats
          .where((s) => s.type == PotentialType.intStat)
          .fold<int>(0, (sum, s) => sum + (s.value ?? 0)) ?? 0;
    }
    return bonus;
  }
  
  /// 获取总智力
  int get totalInt => baseInt + equipInt;
  
  /// 获取基础运气
  int get baseLuk => stats.luk;
  
  /// 获取装备运气加成
  int get equipLuk {
    int bonus = 0;
    for (final equip in equipment.values.where((e) => e != null)) {
      bonus += equip!.luk;
      bonus += equip.potential?.stats
          .where((s) => s.type == PotentialType.luk)
          .fold<int>(0, (sum, s) => sum + (s.value ?? 0)) ?? 0;
    }
    return bonus;
  }
  
  /// 获取总运气
  int get totalLuk => baseLuk + equipLuk;

  /// 获取基础暴击率
  double get baseCritRate => stats.getCritRate();
  
  /// 获取装备暴击率加成
  int get equipCritRate {
    int bonus = 0;
    // 装备基础暴击
    bonus += equipment.values
        .where((e) => e != null)
        .fold<int>(0, (sum, e) => sum + (e!.crit ?? 0));
    // 潜能暴击加成
    for (final equip in equipment.values.where((e) => e != null)) {
      bonus += equip!.potential?.stats
          .where((s) => s.type == PotentialType.critRate)
          .fold<int>(0, (sum, s) => sum + (s.value ?? 0)) ?? 0;
    }
    return bonus;
  }

  /// 获取总暴击率 (最高50%) - 含职业加成
  double getCritRate() => (baseCritRate + equipCritRate + job.critBonus).clamp(0, 50);

  /// 获取基础闪避率
  double get baseAvoidRate => stats.getAvoidRate();
  
  /// 获取装备闪避率加成
  int get equipAvoidRate {
    int bonus = 0;
    // 装备基础闪避
    bonus += equipment.values
        .where((e) => e != null)
        .fold<int>(0, (sum, e) => sum + (e!.avoid ?? 0));
    // 潜能闪避加成
    for (final equip in equipment.values.where((e) => e != null)) {
      bonus += equip!.potential?.stats
          .where((s) => s.type == PotentialType.avoidRate)
          .fold<int>(0, (sum, s) => sum + (s.value ?? 0)) ?? 0;
    }
    return bonus;
  }

  /// 获取总闪避率 (最高50%) - 含职业加成
  double getAvoidRate() => (baseAvoidRate + equipAvoidRate + job.avoidBonus).clamp(0, 50);

  /// 获取套装加成
  /// 返回 Map<bonusType, bonusValue>，bonusType 为 'atkPercent', 'defPercent', 'mpPercent'
  Map<String, int> get setBonus {
    final bonus = <String, int>{};

    // 按 setName 分组统计已装备件数
    final setCounts = <String, int>{};
    for (final equip in equipment.values.where((e) => e != null)) {
      final set = equip!.setName;
      if (set != null && set.isNotEmpty) {
        setCounts[set] = (setCounts[set] ?? 0) + 1;
      }
    }

    for (final entry in setCounts.entries) {
      final setName = entry.key;
      final count = entry.value;

      switch (setName) {
        case 'Iron Set':
          // 2件: +10% DEF
          if (count >= 2) {
            bonus['defPercent'] = (bonus['defPercent'] ?? 0) + 10;
          }
        case 'Mage Set':
          // 2件: +10% MP
          if (count >= 2) {
            bonus['mpPercent'] = (bonus['mpPercent'] ?? 0) + 10;
          }
        case 'Adventurer Set':
          // 3件: +5% ATK
          if (count >= 3) {
            bonus['atkPercent'] = (bonus['atkPercent'] ?? 0) + 5;
          }
      }
    }

    return bonus;
  }

  /// 觉醒 - 三转系统
  /// 提升基础属性并获得觉醒技能
  Player awaken() {
    if (isAwakened) return this;

    final newStats = stats.copyWith(
      str: stats.str + 10,
      dex: stats.dex + 10,
      intStat: stats.intStat + 10,
      luk: stats.luk + 10,
      maxHp: stats.maxHp + 200,
      maxMp: stats.maxMp + 100,
      hp: stats.maxHp + 200,
      mp: stats.maxMp + 100,
    );

    return copyWith(
      stats: newStats,
      isAwakened: true,
    );
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
    Map<String, int>? skillLevels,
    List<StatusEffect>? statusEffects,
    bool? isAwakened,
  }) {
    return Player(
      name: name ?? this.name,
      job: job ?? this.job,
      stats: stats ?? this.stats,
      equipment: equipment ?? this.equipment,
      inventory: inventory ?? this.inventory,
      currentMap: currentMap ?? this.currentMap,
      meso: meso ?? this.meso,
      skillLevels: skillLevels ?? this.skillLevels,
      statusEffects: statusEffects ?? this.statusEffects,
      isAwakened: isAwakened ?? this.isAwakened,
    );
  }
}
