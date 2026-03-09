import 'package:flutter/material.dart';
import '../game/models/player.dart';

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
  ];

  /// 获取所有任务
  static List<GameQuest> getAllQuests() {
    return _quests;
  }

  /// 获取转职任务
  static List<GameQuest> getJobChangeQuests() {
    return _quests.where((q) => q.type == QuestType.jobChange).toList();
  }

  /// 根据ID获取任务
  static GameQuest? getQuestById(String id) {
    try {
      return _quests.firstWhere((q) => q.id == id);
    } catch (e) {
      return null;
    }
  }

  /// 获取适合玩家的可接任务
  static List<GameQuest> getAvailableQuestsForPlayer(Player player) {
    return _quests.where((q) => q.canAccept(player)).toList();
  }
}
