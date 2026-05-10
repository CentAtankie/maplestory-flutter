/// 状态效果类型
enum StatusType {
  burn,      // 燃烧: 每回合结束受到火焰伤害
  poison,    // 中毒: 每回合结束受到毒伤害
  freeze,    // 冰冻: 无法行动 (跳过回合)
  stun,      // 眩晕: 无法行动 (跳过回合)
  bleed,     // 流血: 每回合结束受到物理伤害
  atkUp,     // 攻击提升
  defUp,     // 防御提升
  spdUp,     // 速度/闪避提升
  nextCrit,  // 下回合必定暴击
  nextDodge, // 下回合必定闪避
  magicGuard,// 魔法盾: 伤害优先扣 MP
}

/// 状态效果
class StatusEffect {
  final StatusType type;
  final int value;      // 伤害值或增益数值
  int remainingTurns;   // 剩余回合数

  StatusEffect({
    required this.type,
    required this.value,
    required this.remainingTurns,
  });

  StatusEffect copyWith({
    StatusType? type,
    int? value,
    int? remainingTurns,
  }) {
    return StatusEffect(
      type: type ?? this.type,
      value: value ?? this.value,
      remainingTurns: remainingTurns ?? this.remainingTurns,
    );
  }

  String get displayName {
    switch (type) {
      case StatusType.burn: return '燃烧';
      case StatusType.poison: return '中毒';
      case StatusType.freeze: return '冰冻';
      case StatusType.stun: return '眩晕';
      case StatusType.bleed: return '流血';
      case StatusType.atkUp: return '攻击提升';
      case StatusType.defUp: return '防御提升';
      case StatusType.spdUp: return '敏捷提升';
      case StatusType.nextCrit: return '必定暴击';
      case StatusType.nextDodge: return '必定闪避';
      case StatusType.magicGuard: return '魔法盾';
    }
  }

  String get emoji {
    switch (type) {
      case StatusType.burn: return '🔥';
      case StatusType.poison: return '☠️';
      case StatusType.freeze: return '❄️';
      case StatusType.stun: return '💫';
      case StatusType.bleed: return '🩸';
      case StatusType.atkUp: return '⚔️';
      case StatusType.defUp: return '🛡️';
      case StatusType.spdUp: return '💨';
      case StatusType.nextCrit: return '💥';
      case StatusType.nextDodge: return '💨';
      case StatusType.magicGuard: return '🔮';
    }
  }

  bool get isDebuff => type == StatusType.burn || type == StatusType.poison ||
      type == StatusType.freeze || type == StatusType.stun || type == StatusType.bleed;

  bool get isActionBlocked => type == StatusType.freeze || type == StatusType.stun;
}
