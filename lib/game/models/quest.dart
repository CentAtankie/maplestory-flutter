import 'package:flutter/material.dart';
import 'player.dart';

/// 任务类型
enum QuestType {
  jobChange,    // 转职任务
  levelUp,      // 等级任务
  hunt,         // 狩猎任务
  collect,      // 收集任务
}

/// 任务状态
enum QuestStatus {
  available,    // 可接取
  inProgress,   // 进行中
  completed,    // 已完成
  claimed,      // 已领取奖励
}

/// 游戏任务
class GameQuest {
  final String id;
  final String title;
  final String description;
  final QuestType type;
  final int minLevel;           // 最低等级要求
  final Job? requiredJob;       // 要求职业（null表示任何职业）
  final Job? targetJob;         // 转职目标职业
  final String? targetMapId;    // 目标地图ID
  final List<String> targetMobs; // 目标怪物（狩猎任务）
  final int targetCount;        // 目标数量
  int currentCount;             // 当前进度
  QuestStatus status;
  final Map<String, int> rewards; // 奖励: {'meso': 1000, 'exp': 500}

  GameQuest({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    this.minLevel = 1,
    this.requiredJob,
    this.targetJob,
    this.targetMapId,
    this.targetMobs = const [],
    this.targetCount = 0,
    this.currentCount = 0,
    this.status = QuestStatus.available,
    this.rewards = const {},
  });

  /// 检查玩家是否可以接取此任务
  bool canAccept(Player player) {
    if (status != QuestStatus.available) return false;
    if (player.stats.level < minLevel) return false;
    if (requiredJob != null && player.job != requiredJob) return false;
    return true;
  }

  /// 检查任务是否完成
  bool get isCompleted {
    if (type == QuestType.hunt || type == QuestType.collect) {
      return currentCount >= targetCount;
    }
    return status == QuestStatus.completed || status == QuestStatus.claimed;
  }

  /// 获取进度百分比
  double get progressPercent {
    if (targetCount == 0) return 1.0;
    return (currentCount / targetCount).clamp(0.0, 1.0);
  }

  GameQuest copyWith({
    String? id,
    String? title,
    String? description,
    QuestType? type,
    int? minLevel,
    Job? requiredJob,
    Job? targetJob,
    String? targetMapId,
    List<String>? targetMobs,
    int? targetCount,
    int? currentCount,
    QuestStatus? status,
    Map<String, int>? rewards,
  }) {
    return GameQuest(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      minLevel: minLevel ?? this.minLevel,
      requiredJob: requiredJob ?? this.requiredJob,
      targetJob: targetJob ?? this.targetJob,
      targetMapId: targetMapId ?? this.targetMapId,
      targetMobs: targetMobs ?? this.targetMobs,
      targetCount: targetCount ?? this.targetCount,
      currentCount: currentCount ?? this.currentCount,
      status: status ?? this.status,
      rewards: rewards ?? this.rewards,
    );
  }
}

/// 任务数据库
class QuestDatabase {
  static final List<GameQuest> _quests = [
    // 战士转职任务
    GameQuest(
      id: 'job_warrior',
      title: '战士的意志',
      description: '想要成为战士吗？请前往勇士部落，找到武术教练完成转职。战士以力量和体力见长，是近战专家。',
      type: QuestType.jobChange,
      minLevel: 10,
      requiredJob: Job.beginner,
      targetJob: Job.warrior,
      targetMapId: 'perion',
      rewards: {'meso': 2000, 'exp': 500},
    ),
    // 法师转职任务
    GameQuest(
      id: 'job_magician',
      title: '魔法之道',
      description: '想要掌握魔法的力量吗？请前往魔法密林，找到汉斯完成转职。法师以智力和魔力见长，是远程魔法专家。',
      type: QuestType.jobChange,
      minLevel: 10,
      requiredJob: Job.beginner,
      targetJob: Job.magician,
      targetMapId: 'ellinia',
      rewards: {'meso': 2000, 'exp': 500},
    ),
    // 弓箭手转职任务
    GameQuest(
      id: 'job_bowman',
      title: '精准射击',
      description: '想要成为弓箭手吗？请前往射手村公园，找到赫丽娜完成转职。弓箭手以敏捷和精准见长，是远程物理专家。',
      type: QuestType.jobChange,
      minLevel: 10,
      requiredJob: Job.beginner,
      targetJob: Job.bowman,
      targetMapId: 'henesys_park',
      rewards: {'meso': 2000, 'exp': 500},
    ),
    // 飞侠转职任务
    GameQuest(
      id: 'job_thief',
      title: '暗影之路',
      description: '想要成为飞侠吗？请前往废弃都市，找到达克鲁完成转职。飞侠以运气和速度见长，是高爆发专家。',
      type: QuestType.jobChange,
      minLevel: 10,
      requiredJob: Job.beginner,
      targetJob: Job.thief,
      targetMapId: 'kerning',
      rewards: {'meso': 2000, 'exp': 500},
    ),
    // 海盗转职任务
    GameQuest(
      id: 'job_pirate',
      title: '海盗精神',
      description: '想要成为海盗吗？请前往诺特勒斯号，找到凯琳完成转职。海盗以力量和敏捷见长，是多面手专家。',
      type: QuestType.jobChange,
      minLevel: 10,
      requiredJob: Job.beginner,
      targetJob: Job.pirate,
      targetMapId: 'nautilus',
      rewards: {'meso': 2000, 'exp': 500},
    ),
    // ========== 二转任务 (30 级) ==========
    GameQuest(
      id: 'job2_fighter',
      title: '剑客的觉醒',
      description: '战士进阶之路！等级 30 以上,前往勇士部落与武术教练对话,觉醒为剑客。剑客拥有更强的力量和 HP 增长。',
      type: QuestType.jobChange,
      minLevel: 30,
      requiredJob: Job.warrior,
      targetJob: Job.fighter,
      targetMapId: 'perion',
      rewards: {'meso': 8000, 'exp': 3000},
    ),
    GameQuest(
      id: 'job2_fp_mage',
      title: '火元素的领悟',
      description: '法师进阶之路！等级 30 以上,前往魔法密林研习火属性魔法,觉醒为火法师。火法师释放的火球术伤害极高。',
      type: QuestType.jobChange,
      minLevel: 30,
      requiredJob: Job.magician,
      targetJob: Job.fpMage,
      targetMapId: 'ellinia',
      rewards: {'meso': 8000, 'exp': 3000},
    ),
    GameQuest(
      id: 'job2_hunter',
      title: '猎人的契约',
      description: '弓箭手进阶之路！等级 30 以上,前往射手村公园,与赫丽娜签订猎人契约。猎人的三连射可造成多段伤害。',
      type: QuestType.jobChange,
      minLevel: 30,
      requiredJob: Job.bowman,
      targetJob: Job.hunter,
      targetMapId: 'henesys_park',
      rewards: {'meso': 8000, 'exp': 3000},
    ),
    GameQuest(
      id: 'job2_assassin',
      title: '刺客的暗影',
      description: '飞侠进阶之路！等级 30 以上,前往废弃都市,接受达克鲁的考验,觉醒为刺客。刺客的幸运七必定暴击。',
      type: QuestType.jobChange,
      minLevel: 30,
      requiredJob: Job.thief,
      targetJob: Job.assassin,
      targetMapId: 'kerning',
      rewards: {'meso': 8000, 'exp': 3000},
    ),
    GameQuest(
      id: 'job2_brawler',
      title: '拳手的狂怒',
      description: '海盗进阶之路！等级 30 以上,前往诺特勒斯号,与凯琳交手,觉醒为拳手。拳手以双拳粉碎一切。',
      type: QuestType.jobChange,
      minLevel: 30,
      requiredJob: Job.pirate,
      targetJob: Job.brawler,
      targetMapId: 'nautilus',
      rewards: {'meso': 8000, 'exp': 3000},
    ),
    // ========== 高级等级任务 ==========
    // 20级任务
    GameQuest(
      id: 'level_20_milestone',
      title: '成长的证明',
      description: '你的实力正在飞速提升！达到20级，证明你的成长。',
      type: QuestType.levelUp,
      minLevel: 20,
      requiredJob: null,
      rewards: {'meso': 5000, 'exp': 1000},
    ),
    // 30级任务
    GameQuest(
      id: 'level_30_milestone',
      title: '中级冒险家',
      description: '你已经不再是新手了！达到30级，成为中级冒险家。',
      type: QuestType.levelUp,
      minLevel: 30,
      requiredJob: null,
      rewards: {'meso': 10000, 'exp': 3000},
    ),
    // 40级任务
    GameQuest(
      id: 'level_40_milestone',
      title: '高级冒险家',
      description: '你的名字开始被人传颂！达到40级，成为高级冒险家。',
      type: QuestType.levelUp,
      minLevel: 40,
      requiredJob: null,
      rewards: {'meso': 20000, 'exp': 8000},
    ),
    // 50级任务
    GameQuest(
      id: 'level_50_milestone',
      title: '传说冒险家',
      description: '你已经站在了冒险岛的顶端！达到50级，成为传说中的冒险家。',
      type: QuestType.levelUp,
      minLevel: 50,
      requiredJob: null,
      rewards: {'meso': 50000, 'exp': 20000},
    ),
    // ========== 狩猎任务 ==========
    // 野猪狩猎任务
    GameQuest(
      id: 'hunt_wild_boar',
      title: '野猪大作战',
      description: '勇士部落附近的野猪太多了！去西部荒野消灭30只野猪。',
      type: QuestType.hunt,
      minLevel: 15,
      requiredJob: null,
      targetMobs: ['野猪'],
      targetCount: 30,
      rewards: {'meso': 3000, 'exp': 1500},
    ),
    // 石头人狩猎任务
    GameQuest(
      id: 'hunt_stone_golem',
      title: '粉碎石头人',
      description: '高原上的石头人威胁着冒险者的安全！消灭20只石头人。',
      type: QuestType.hunt,
      minLevel: 35,
      requiredJob: null,
      targetMobs: ['石头人', '黑石头人'],
      targetCount: 20,
      rewards: {'meso': 15000, 'exp': 5000},
    ),
    // 幽灵狩猎任务
    GameQuest(
      id: 'hunt_wraith',
      title: '地铁清理行动',
      description: '废弃都市地铁深处出现了大量幽灵！消灭25只小幽灵。',
      type: QuestType.hunt,
      minLevel: 45,
      requiredJob: null,
      targetMobs: ['小幽灵'],
      targetCount: 25,
      rewards: {'meso': 25000, 'exp': 10000},
    ),
    // ========== 三转觉醒任务 (70 级) ==========
    GameQuest(
      id: 'awaken_fighter',
      title: '剑圣的觉醒',
      description: '剑客进阶之路的终点！等级 70 以上，前往勇士部落完成最终觉醒，成为剑圣。觉醒后所有基础属性+10，HP/MP大幅提升，并获得终极觉醒技能。',
      type: QuestType.jobChange,
      minLevel: 70,
      requiredJob: Job.fighter,
      targetJob: Job.fighter,
      targetMapId: 'perion',
      rewards: {'meso': 50000, 'exp': 20000},
    ),
    GameQuest(
      id: 'awaken_fp_mage',
      title: '大魔导师的觉醒',
      description: '火法师进阶之路的终点！等级 70 以上，前往魔法密林完成最终觉醒，成为大魔导师。觉醒后所有基础属性+10，HP/MP大幅提升，并获得终极觉醒技能。',
      type: QuestType.jobChange,
      minLevel: 70,
      requiredJob: Job.fpMage,
      targetJob: Job.fpMage,
      targetMapId: 'ellinia',
      rewards: {'meso': 50000, 'exp': 20000},
    ),
    GameQuest(
      id: 'awaken_hunter',
      title: '箭神的觉醒',
      description: '猎人进阶之路的终点！等级 70 以上，前往射手村公园完成最终觉醒，成为箭神。觉醒后所有基础属性+10，HP/MP大幅提升，并获得终极觉醒技能。',
      type: QuestType.jobChange,
      minLevel: 70,
      requiredJob: Job.hunter,
      targetJob: Job.hunter,
      targetMapId: 'henesys_park',
      rewards: {'meso': 50000, 'exp': 20000},
    ),
    GameQuest(
      id: 'awaken_assassin',
      title: '夜行者的觉醒',
      description: '刺客进阶之路的终点！等级 70 以上，前往废弃都市完成最终觉醒，成为夜行者。觉醒后所有基础属性+10，HP/MP大幅提升，并获得终极觉醒技能。',
      type: QuestType.jobChange,
      minLevel: 70,
      requiredJob: Job.assassin,
      targetJob: Job.assassin,
      targetMapId: 'kerning',
      rewards: {'meso': 50000, 'exp': 20000},
    ),
    GameQuest(
      id: 'awaken_brawler',
      title: '冲锋队长的觉醒',
      description: '拳手进阶之路的终点！等级 70 以上，前往诺特勒斯号完成最终觉醒，成为冲锋队长。觉醒后所有基础属性+10，HP/MP大幅提升，并获得终极觉醒技能。',
      type: QuestType.jobChange,
      minLevel: 70,
      requiredJob: Job.brawler,
      targetJob: Job.brawler,
      targetMapId: 'nautilus',
      rewards: {'meso': 50000, 'exp': 20000},
    ),
  ];

  /// 获取所有任务
  static List<GameQuest> getAllQuests() {
    return _quests;
  }

  /// 获取转职任务
  static List<GameQuest> getJobChangeQuests() {
    return _quests.where((q) => q.type == QuestType.jobChange).toList();
  }

  /// 根据ID获取任务 - O(1) Map 查询
  static final Map<String, GameQuest> _byId = {
    for (final q in _quests) q.id: q,
  };

  static GameQuest? getQuestById(String id) => _byId[id];

  /// 获取适合玩家的可接任务
  static List<GameQuest> getAvailableQuestsForPlayer(Player player) {
    return _quests.where((q) => q.canAccept(player)).toList();
  }
}
