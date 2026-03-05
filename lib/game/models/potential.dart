import 'dart:math';

/// 潜能等级
enum PotentialGrade {
  none,     // 无潜能
  rare,     // 紫色 - B级 (1条A + 2条B)
  epic,     // 黄色 - A级 (1条S + 2条A)
  unique,   // 绿色 - S级 (1条SS + 2条S)
}

/// 潜能属性类型
enum PotentialType {
  str,      // 力量
  dex,      // 敏捷
  intStat,  // 智力
  luk,      // 运气
  maxHp,    // 最大HP
  maxMp,    // 最大MP
  atk,      // 攻击力
  def,      // 防御力
  critRate, // 暴击率
  avoidRate,// 闪避率
}

/// 潜能属性
class PotentialStat {
  final PotentialType type;
  final int value;
  final String grade; // 'B', 'A', 'S', 'SS'

  PotentialStat({
    required this.type,
    required this.value,
    required this.grade,
  });

  String get typeName {
    switch (type) {
      case PotentialType.str: return '力量';
      case PotentialType.dex: return '敏捷';
      case PotentialType.intStat: return '智力';
      case PotentialType.luk: return '运气';
      case PotentialType.maxHp: return '最大HP';
      case PotentialType.maxMp: return '最大MP';
      case PotentialType.atk: return '攻击力';
      case PotentialType.def: return '防御力';
      case PotentialType.critRate: return '暴击率';
      case PotentialType.avoidRate: return '闪避率';
    }
  }

  String get displayText {
    if (type == PotentialType.critRate || type == PotentialType.avoidRate) {
      return '$typeName +$value%';
    }
    return '$typeName +$value';
  }
}

/// 装备潜能
class EquipmentPotential {
  PotentialGrade grade;
  List<PotentialStat> stats;

  EquipmentPotential({
    this.grade = PotentialGrade.none,
    this.stats = const [],
  });

  /// 生成初始紫色A潜能
  factory EquipmentPotential.generateRare() {
    final random = Random();
    
    // 1条A级属性
    final aStat = _generateStat('A', random);
    // 2条B级属性
    final bStat1 = _generateStat('B', random);
    final bStat2 = _generateStat('B', random);
    
    return EquipmentPotential(
      grade: PotentialGrade.rare,
      stats: [aStat, bStat1, bStat2],
    );
  }

  /// 生成黄色S潜能
  factory EquipmentPotential.generateEpic() {
    final random = Random();
    
    // 1条S级属性
    final sStat = _generateStat('S', random);
    // 2条A级属性
    final aStat1 = _generateStat('A', random);
    final aStat2 = _generateStat('A', random);
    
    return EquipmentPotential(
      grade: PotentialGrade.epic,
      stats: [sStat, aStat1, aStat2],
    );
  }

  /// 生成绿色SS潜能
  factory EquipmentPotential.generateUnique() {
    final random = Random();
    
    // 1条SS级属性
    final ssStat = _generateStat('SS', random);
    // 2条S级属性
    final sStat1 = _generateStat('S', random);
    final sStat2 = _generateStat('S', random);
    
    return EquipmentPotential(
      grade: PotentialGrade.unique,
      stats: [ssStat, sStat1, sStat2],
    );
  }

  /// 随机生成一条属性
  static PotentialStat _generateStat(String grade, Random random) {
    final types = PotentialType.values;
    final type = types[random.nextInt(types.length)];
    
    int value;
    switch (grade) {
      case 'B':
        value = type == PotentialType.critRate || type == PotentialType.avoidRate
            ? random.nextInt(3) + 1  // 1-3%
            : random.nextInt(5) + 1;  // 1-5
        break;
      case 'A':
        value = type == PotentialType.critRate || type == PotentialType.avoidRate
            ? random.nextInt(3) + 3  // 3-5%
            : random.nextInt(5) + 5;  // 5-9
        break;
      case 'S':
        value = type == PotentialType.critRate || type == PotentialType.avoidRate
            ? random.nextInt(3) + 5  // 5-7%
            : random.nextInt(5) + 10; // 10-14
        break;
      case 'SS':
        value = type == PotentialType.critRate || type == PotentialType.avoidRate
            ? random.nextInt(3) + 8  // 8-10%
            : random.nextInt(5) + 15; // 15-19
        break;
      default:
        value = 1;
    }
    
    return PotentialStat(
      type: type,
      value: value,
      grade: grade,
    );
  }

  /// 重新随机当前等级的属性
  void reroll() {
    final random = Random();
    switch (grade) {
      case PotentialGrade.rare:
        stats = [
          _generateStat('A', random),
          _generateStat('B', random),
          _generateStat('B', random),
        ];
        break;
      case PotentialGrade.epic:
        stats = [
          _generateStat('S', random),
          _generateStat('A', random),
          _generateStat('A', random),
        ];
        break;
      case PotentialGrade.unique:
        stats = [
          _generateStat('SS', random),
          _generateStat('S', random),
          _generateStat('S', random),
        ];
        break;
      default:
        stats = [];
    }
  }

  /// 获取潜能颜色
  String get gradeColor {
    switch (grade) {
      case PotentialGrade.none: return '#808080';
      case PotentialGrade.rare: return '#9B59B6'; // 紫色
      case PotentialGrade.epic: return '#F39C12'; // 黄色
      case PotentialGrade.unique: return '#27AE60'; // 绿色
    }
  }

  String get gradeName {
    switch (grade) {
      case PotentialGrade.none: return '无潜能';
      case PotentialGrade.rare: return '稀有(A)';
      case PotentialGrade.epic: return '史诗(S)';
      case PotentialGrade.unique: return '传说(SS)';
    }
  }
}