import 'dart:math';
import 'status_effect.dart';

/// 怪物元素属性
enum MobElement { neutral, fire, ice, poison, dark }

/// 怪物特性
enum MobTrait {
  shellArmor,      // 首击减伤 50%
  split,           // 死亡分裂
  spore,           // 死亡释放毒雾
  dodgy,           // 高闪避
  thorn,           // 受击反击
  ink,             // 低血降低玩家命中
  woodBody,        // 火弱 (+50% 火伤)
  charge,          // 首击增伤 50%
  gaze,            // 降低玩家闪避
  venom,           // 攻击附带中毒
  flame,           // 攻击附带燃烧
  frost,           // 攻击附带冰冻
  petrify,         // 高防御 + 首击减伤
  manaDrain,       // 攻击吸收 MP
  iceResist,       // 冰抗高 火弱
  fireResist,      // 火抗高 冰弱
  ghostForm,       // 高闪避 + 物理减伤
  lifeSteal,       // 吸血
  lucky,           // 高暴击
  heavyArmor,      // 高防御
  swift,           // 高闪避
  timeStop,        // 每 N 回合眩晕玩家
  summon,          // 低血召唤小怪
  rage,            // 低血攻击力翻倍
  dragonBreath,    // 每 N 回合大范围攻击
}

/// 怪物类型
enum MobType {
  snail('蜗牛', '🐌'),
  blueSnail('蓝蜗牛', '🐚'),
  redSnail('红蜗牛', '🐌'),
  slime('绿水灵', '💧'),
  mushroom('蘑菇仔', '🍄'),
  blueMushroom('蓝蘑菇', '🍄'),
  hornyMushroom('刺蘑菇', '🌵'),
  // 5-15 级低级补足
  pinkBean('粉粉熊', '🐻'),
  octopus('八爪鱼', '🐙'),
  // 10-20级怪物
  woodenMummy('木妖', '🪵'),
  wildBoar('野猪', '🐗'),
  evilEye('独眼兽', '👁️'),
  ribbonPig('丝带猪', '🎀'),
  // 20-30级怪物
  zombieMushroom('僵尸蘑菇', '🧟'),
  fireBoar('火焰野猪', '🐗'),
  iceMaster('冰师傅', '🧊'),
  // 30-40级怪物
  stoneGolem('石头人', '🗿'),
  darkStoneGolem('黑石头人', '🗿'),
  // 40-50级怪物
  iceSentinel('冰独眼兽', '👁️'),
  fireSentinel('火独眼兽', '👁️'),
  wraith('小幽灵', '👻'),
  // 50-80级高级怪物
  darkLeatty('黑色绫翅', '🦇'),
  luckyMonkey('幸运猴', '🐒'),
  crocky('鳄鱼怪', '🐊'),
  jrCelion('小赛罗', '🦊'),
  masterChronos('时间守护者', '⏰'),
  // Boss 怪物
  mushmom('蘑菇妈妈', '👹'),
  balrogJr('小巴洛克', '🦂'),
  pianus('黑龙王', '🐉');

  final String displayName;
  final String emoji;

  const MobType(this.displayName, this.emoji);

  /// 是否是 Boss (用于 UI 区分展示)
  bool get isBoss =>
      this == MobType.mushmom ||
      this == MobType.balrogJr ||
      this == MobType.pianus;
}

/// 掉落物品
class DropItem {
  String itemId;  // 改为物品ID
  double chance;

  DropItem({
    required this.itemId,
    required this.chance,
  });
}

/// 怪物
class Mob {
  String name;
  String emoji;
  int level;
  int hp;
  int maxHp;
  int atk;
  int def;
  int exp;
  List<DropItem> drops;
  MobElement element;
  List<MobTrait> traits;
  List<StatusEffect> statusEffects;

  Mob({
    required this.name,
    required this.emoji,
    required this.level,
    required this.hp,
    required this.maxHp,
    required this.atk,
    this.def = 0,
    required this.exp,
    this.drops = const [],
    this.element = MobElement.neutral,
    this.traits = const [],
    List<StatusEffect>? statusEffects,
  }) : statusEffects = statusEffects ?? [];

  /// 创建怪物
  factory Mob.create(MobType type) {
    switch (type) {
      case MobType.snail:
        return Mob(
          name: '蜗牛',
          emoji: '🐌',
          level: 1,
          hp: 15,
          maxHp: 15,
          atk: 3,
          exp: 2,
          drops: [
            DropItem(itemId: 'snail_shell', chance: 0.3),
            DropItem(itemId: 'red_potion', chance: 0.1),
          ],
        );
      case MobType.blueSnail:
        return Mob(
          name: '蓝蜗牛',
          emoji: '🐚',
          level: 2,
          hp: 20,
          maxHp: 20,
          atk: 5,
          exp: 3,
          drops: [
            DropItem(itemId: 'snail_shell', chance: 0.4),
            DropItem(itemId: 'blue_snail_shell', chance: 0.2),
          ],
        );
      case MobType.redSnail:
        return Mob(
          name: '红蜗牛',
          emoji: '🐌',
          level: 3,
          hp: 30,
          maxHp: 30,
          atk: 8,
          exp: 5,
          drops: [
            DropItem(itemId: 'red_snail_shell', chance: 0.3),
            DropItem(itemId: 'orange_potion', chance: 0.15),
          ],
          traits: [MobTrait.shellArmor],
        );
      case MobType.slime:
        return Mob(
          name: '绿水灵',
          emoji: '💧',
          level: 4,
          hp: 40,
          maxHp: 40,
          atk: 12,
          exp: 8,
          drops: [
            DropItem(itemId: 'slime_bubble', chance: 0.25),
            DropItem(itemId: 'blue_potion', chance: 0.1),
          ],
        );
      case MobType.mushroom:
        return Mob(
          name: '蘑菇仔',
          emoji: '🍄',
          level: 6,
          hp: 60,
          maxHp: 60,
          atk: 15,
          exp: 12,
          drops: [
            DropItem(itemId: 'mushroom_cap', chance: 0.2),
            DropItem(itemId: 'orange_potion', chance: 0.15),
          ],
          traits: [MobTrait.spore],
        );
      case MobType.blueMushroom:
        return Mob(
          name: '蓝蘑菇',
          emoji: '🍄',
          level: 8,
          hp: 80,
          maxHp: 80,
          atk: 20,
          exp: 18,
          drops: [
            DropItem(itemId: 'blue_mushroom_cap', chance: 0.2),
            DropItem(itemId: 'blue_potion', chance: 0.2),
          ],
          traits: [MobTrait.dodgy],
        );
      case MobType.hornyMushroom:
        return Mob(
          name: '刺蘑菇',
          emoji: '🌵',
          level: 12,
          hp: 120,
          maxHp: 120,
          atk: 30,
          exp: 28,
          drops: [
            DropItem(itemId: 'horny_mushroom_cap', chance: 0.15),
            DropItem(itemId: 'red_potion_large', chance: 0.1),
          ],
          traits: [MobTrait.thorn],
        );
      // 10-20级怪物
      case MobType.woodenMummy:
        return Mob(
          name: '木妖',
          emoji: '🪵',
          level: 15,
          hp: 180,
          maxHp: 180,
          atk: 38,
          exp: 40,
          drops: [
            DropItem(itemId: 'wood_piece', chance: 0.25),
            DropItem(itemId: 'red_potion_large', chance: 0.15),
          ],
          element: MobElement.neutral,
          traits: [MobTrait.woodBody],
        );
      case MobType.wildBoar:
        return Mob(
          name: '野猪',
          emoji: '🐗',
          level: 18,
          hp: 250,
          maxHp: 250,
          atk: 45,
          exp: 55,
          drops: [
            DropItem(itemId: 'boar_tooth', chance: 0.3),
            DropItem(itemId: 'white_potion', chance: 0.15),
          ],
          traits: [MobTrait.charge],
        );
      case MobType.evilEye:
        return Mob(
          name: '独眼兽',
          emoji: '👁️',
          level: 20,
          hp: 300,
          maxHp: 300,
          atk: 50,
          exp: 65,
          drops: [
            DropItem(itemId: 'evil_eye_tail', chance: 0.25),
            DropItem(itemId: 'white_potion', chance: 0.2),
          ],
          traits: [MobTrait.gaze],
        );
      // 20-30级怪物
      case MobType.zombieMushroom:
        return Mob(
          name: '僵尸蘑菇',
          emoji: '🧟',
          level: 24,
          hp: 400,
          maxHp: 400,
          atk: 60,
          exp: 85,
          drops: [
            DropItem(itemId: 'zombie_mushroom_cap', chance: 0.25),
            DropItem(itemId: 'white_potion', chance: 0.2),
          ],
          element: MobElement.poison,
          traits: [MobTrait.venom],
        );
      case MobType.fireBoar:
        return Mob(
          name: '火焰野猪',
          emoji: '🔥',
          level: 28,
          hp: 520,
          maxHp: 520,
          atk: 72,
          exp: 110,
          drops: [
            DropItem(itemId: 'fire_boar_tooth', chance: 0.3),
            DropItem(itemId: 'blue_potion_large', chance: 0.2),
          ],
          element: MobElement.fire,
          traits: [MobTrait.flame],
        );
      // 30-40级怪物
      case MobType.stoneGolem:
        return Mob(
          name: '石头人',
          emoji: '🗿',
          level: 35,
          hp: 800,
          maxHp: 800,
          atk: 95,
          exp: 160,
          drops: [
            DropItem(itemId: 'golem_stone', chance: 0.25),
            DropItem(itemId: 'red_potion_large', chance: 0.25),
          ],
          traits: [MobTrait.petrify],
        );
      case MobType.darkStoneGolem:
        return Mob(
          name: '黑石头人',
          emoji: '🗿',
          level: 40,
          hp: 1100,
          maxHp: 1100,
          atk: 120,
          exp: 220,
          drops: [
            DropItem(itemId: 'dark_golem_stone', chance: 0.25),
            DropItem(itemId: 'blue_potion_large', chance: 0.25),
          ],
          element: MobElement.dark,
          traits: [MobTrait.manaDrain],
        );
      // 40-50级怪物
      case MobType.iceSentinel:
        return Mob(
          name: '冰独眼兽',
          emoji: '❄️',
          level: 45,
          hp: 1500,
          maxHp: 1500,
          atk: 150,
          exp: 300,
          drops: [
            DropItem(itemId: 'ice_piece', chance: 0.2),
            DropItem(itemId: 'white_potion', chance: 0.3),
          ],
          element: MobElement.ice,
          traits: [MobTrait.iceResist],
        );
      case MobType.fireSentinel:
        return Mob(
          name: '火独眼兽',
          emoji: '🔥',
          level: 48,
          hp: 1800,
          maxHp: 1800,
          atk: 170,
          exp: 380,
          drops: [
            DropItem(itemId: 'fire_piece', chance: 0.2),
            DropItem(itemId: 'white_potion', chance: 0.3),
          ],
          element: MobElement.fire,
          traits: [MobTrait.fireResist],
        );
      case MobType.wraith:
        return Mob(
          name: '小幽灵',
          emoji: '👻',
          level: 50,
          hp: 2200,
          maxHp: 2200,
          atk: 200,
          exp: 500,
          drops: [
            DropItem(itemId: 'wraith_cloth', chance: 0.2),
            DropItem(itemId: 'blue_potion_large', chance: 0.3),
          ],
          element: MobElement.dark,
          traits: [MobTrait.ghostForm],
        );

      // ===== 5-15 级低级补足 =====
      case MobType.pinkBean:
        return Mob(
          name: '粉粉熊',
          emoji: '🐻',
          level: 5,
          hp: 50,
          maxHp: 50,
          atk: 13,
          exp: 10,
          drops: [
            DropItem(itemId: 'orange_potion', chance: 0.2),
          ],
        );
      case MobType.octopus:
        return Mob(
          name: '八爪鱼',
          emoji: '🐙',
          level: 7,
          hp: 70,
          maxHp: 70,
          atk: 18,
          exp: 14,
          drops: [
            DropItem(itemId: 'orange_potion', chance: 0.2),
            DropItem(itemId: 'blue_potion', chance: 0.1),
          ],
        );
      case MobType.ribbonPig:
        return Mob(
          name: '丝带猪',
          emoji: '🎀',
          level: 16,
          hp: 200,
          maxHp: 200,
          atk: 42,
          exp: 50,
          drops: [
            DropItem(itemId: 'red_potion_large', chance: 0.25),
          ],
        );
      case MobType.iceMaster:
        return Mob(
          name: '冰师傅',
          emoji: '🧊',
          level: 22,
          hp: 350,
          maxHp: 350,
          atk: 55,
          exp: 75,
          drops: [
            DropItem(itemId: 'white_potion', chance: 0.25),
          ],
          element: MobElement.ice,
          traits: [MobTrait.frost],
        );

      // ===== 50-80 级高级怪物 =====
      case MobType.darkLeatty:
        return Mob(
          name: '黑色绫翅',
          emoji: '🦇',
          level: 55,
          hp: 2800,
          maxHp: 2800,
          atk: 220,
          def: 30,
          exp: 600,
          drops: [
            DropItem(itemId: 'wraith_cloth', chance: 0.25),
            DropItem(itemId: 'blue_potion_large', chance: 0.3),
          ],
          element: MobElement.dark,
          traits: [MobTrait.lifeSteal],
        );
      case MobType.luckyMonkey:
        return Mob(
          name: '幸运猴',
          emoji: '🐒',
          level: 60,
          hp: 3500,
          maxHp: 3500,
          atk: 250,
          def: 40,
          exp: 750,
          drops: [
            DropItem(itemId: 'wraith_cloth', chance: 0.2),
            DropItem(itemId: 'blue_potion_large', chance: 0.3),
            DropItem(itemId: 'white_potion', chance: 0.4),
          ],
          traits: [MobTrait.lucky],
        );
      case MobType.crocky:
        return Mob(
          name: '鳄鱼怪',
          emoji: '🐊',
          level: 65,
          hp: 4500,
          maxHp: 4500,
          atk: 290,
          def: 55,
          exp: 950,
          drops: [
            DropItem(itemId: 'fire_piece', chance: 0.15),
            DropItem(itemId: 'blue_potion_large', chance: 0.35),
          ],
          traits: [MobTrait.heavyArmor],
        );
      case MobType.jrCelion:
        return Mob(
          name: '小赛罗',
          emoji: '🦊',
          level: 70,
          hp: 5500,
          maxHp: 5500,
          atk: 330,
          def: 70,
          exp: 1200,
          drops: [
            DropItem(itemId: 'ice_piece', chance: 0.18),
            DropItem(itemId: 'fire_piece', chance: 0.18),
            DropItem(itemId: 'white_potion', chance: 0.4),
          ],
          traits: [MobTrait.swift],
        );
      case MobType.masterChronos:
        return Mob(
          name: '时间守护者',
          emoji: '⏰',
          level: 75,
          hp: 7000,
          maxHp: 7000,
          atk: 380,
          def: 90,
          exp: 1500,
          drops: [
            DropItem(itemId: 'ice_piece', chance: 0.2),
            DropItem(itemId: 'fire_piece', chance: 0.2),
            DropItem(itemId: 'wraith_cloth', chance: 0.3),
          ],
          traits: [MobTrait.timeStop],
        );

      // ===== Boss 怪物 (高 HP / 高奖励,单怪 boss 关) =====
      case MobType.mushmom:
        return Mob(
          name: '蘑菇妈妈',
          emoji: '👹',
          level: 30,
          hp: 5000,
          maxHp: 5000,
          atk: 100,
          def: 25,
          exp: 800,
          drops: [
            DropItem(itemId: 'horny_mushroom_cap', chance: 1.0),
            DropItem(itemId: 'red_potion_large', chance: 0.6),
            DropItem(itemId: 'white_potion', chance: 0.4),
          ],
          element: MobElement.poison,
          traits: [MobTrait.summon, MobTrait.venom],
        );
      case MobType.balrogJr:
        return Mob(
          name: '小巴洛克',
          emoji: '🦂',
          level: 55,
          hp: 12000,
          maxHp: 12000,
          atk: 250,
          def: 60,
          exp: 2500,
          drops: [
            DropItem(itemId: 'fire_piece', chance: 1.0),
            DropItem(itemId: 'blue_potion_large', chance: 0.7),
            DropItem(itemId: 'wraith_cloth', chance: 0.5),
          ],
          element: MobElement.fire,
          traits: [MobTrait.rage, MobTrait.flame],
        );
      case MobType.pianus:
        return Mob(
          name: '黑龙王',
          emoji: '🐉',
          level: 80,
          hp: 25000,
          maxHp: 25000,
          atk: 500,
          def: 120,
          exp: 5000,
          drops: [
            DropItem(itemId: 'ice_piece', chance: 1.0),
            DropItem(itemId: 'fire_piece', chance: 1.0),
            DropItem(itemId: 'wraith_cloth', chance: 0.8),
            DropItem(itemId: 'white_potion', chance: 0.6),
          ],
          element: MobElement.dark,
          traits: [MobTrait.dragonBreath, MobTrait.rage],
        );
    }
  }

  /// 复制怪物
  Mob copyWith({
    String? name,
    String? emoji,
    int? level,
    int? hp,
    int? maxHp,
    int? atk,
    int? def,
    int? exp,
    List<DropItem>? drops,
    MobElement? element,
    List<MobTrait>? traits,
    List<StatusEffect>? statusEffects,
  }) {
    return Mob(
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      level: level ?? this.level,
      hp: hp ?? this.hp,
      maxHp: maxHp ?? this.maxHp,
      atk: atk ?? this.atk,
      def: def ?? this.def,
      exp: exp ?? this.exp,
      drops: drops ?? this.drops,
      element: element ?? this.element,
      traits: traits ?? this.traits,
      statusEffects: statusEffects ?? this.statusEffects,
    );
  }

  /// 获取掉落（材料）
  List<String> getDrops() {
    final random = Random();
    final result = <String>[];

    // 掉落材料
    for (final drop in drops) {
      if (random.nextDouble() < drop.chance) {
        result.add(drop.itemId);
      }
    }

    return result;
  }
}
