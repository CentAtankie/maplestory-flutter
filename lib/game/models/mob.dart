import 'dart:math';
import 'item.dart';

/// 怪物类型
enum MobType {
  snail('蜗牛', '🐌'),
  blueSnail('蓝蜗牛', '🐚'),
  redSnail('红蜗牛', '🐌'),
  slime('绿水灵', '💧'),
  mushroom('蘑菇仔', '🍄'),
  blueMushroom('蓝蘑菇', '🍄'),
  hornyMushroom('刺蘑菇', '🌵'),
  // 10-20级怪物
  woodenMummy('木妖', '🪵'),
  wildBoar('野猪', '🐗'),
  evilEye('独眼兽', '👁️'),
  // 20-30级怪物
  zombieMushroom('僵尸蘑菇', '🧟'),
  fireBoar('火焰野猪', '🐗'),
  // 30-40级怪物
  stoneGolem('石头人', '🗿'),
  darkStoneGolem('黑石头人', '🗿'),
  // 40-50级怪物
  iceSentinel('冰独眼兽', '👁️'),
  fireSentinel('火独眼兽', '👁️'),
  wraith('小幽灵', '👻');

  final String displayName;
  final String emoji;

  const MobType(this.displayName, this.emoji);
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
  });

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
    );
  }

  /// 获取掉落（材料和装备）
  List<String> getDrops() {
    final random = Random();
    final result = <String>[];
    
    // 掉落材料
    for (final drop in drops) {
      if (random.nextDouble() < drop.chance) {
        result.add(drop.itemId);
      }
    }
    
    // 小概率掉落装备 (5% - 15% 根据怪物等级)
    final equipDropChance = 0.05 + (level * 0.01); // 5% - 17%
    if (random.nextDouble() < equipDropChance) {
      // 根据怪物等级选择合适等级的装备
      final minEquipLevel = (level / 2).floor().clamp(1, 20);
      final maxEquipLevel = level.clamp(1, 20);
      final possibleEquipments = EquipmentDatabase.getByLevelRange(minEquipLevel, maxEquipLevel);
      
      if (possibleEquipments.isNotEmpty) {
        final equipment = possibleEquipments[random.nextInt(possibleEquipments.length)];
        if (equipment.id != null) {
          result.add(equipment.id!);
        }
      }
    }
    
    return result;
  }
}
