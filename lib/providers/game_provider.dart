import 'dart:async';
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../game/models/player.dart';
import '../game/models/mob.dart';
import '../game/models/map.dart';
import '../game/models/item.dart' hide Equipment;
import '../game/models/potential.dart';
import '../game/models/mail.dart';
import '../game/models/quest.dart';
import '../repositories/save_repository.dart';
import '../repositories/hive_save_repository.dart';

// 游戏状态枚举
enum GameState {
  exploring,  // 探索中
  battling,   // 战斗中
  shopping,   // 商店中
  menu,       // 菜单
  gameOver,   // 游戏结束
}

// 商店分类
enum ShopCategory {
  all,        // 全部（购买）
  consumable, // 药水
  scroll,     // 卷轴
  equipment,  // 装备
  special,    // 特殊（魔方等）
  sell,       // 卖出
}

// 游戏日志条目
class LogEntry {
  final String message;
  final DateTime timestamp;
  final LogType type;

  LogEntry({
    required this.message,
    this.type = LogType.normal,
  }) : timestamp = DateTime.now();
}

enum LogType {
  normal,
  success,
  warning,
  error,
  battle,
  reward,
}

// 游戏状态管理
class GameNotifier extends StateNotifier<GameData> {
  final SaveRepository _saveRepository;
  bool _isInitialized = false;

  // 自动战斗定时器 (开关状态在 GameData 中)
  Timer? _autoBattleTimer;

  // 自动存档相关
  Timer? _autoSaveTimer;
  static const Duration _autoSaveDebounce = Duration(seconds: 3);

  // 地图等级要求(传送限制)
  static const _mapLevelRequirements = <String, int>{
    'henesys': 1, 'farm': 1, 'snail_garden': 1, 'lith': 1,
    'henesys_park': 1, 'perion': 1, 'ellinia': 1, 'kerning': 1,
    'nautilus': 1, 'pinkbean_field': 5, 'octopus_beach': 5,
    'slime_tree': 3, 'trail': 6, 'ribbon_meadow': 12,
    'cave': 10, 'perion_field': 15, 'ellinia_field': 15,
    'kerning_swamp': 20, 'ice_lab': 20, 'fire_land1': 25,
    'fire_land2': 28, 'ant_tunnel1': 30, 'ant_tunnel2': 35,
    'mushmom_cave': 25, 'highland1': 35, 'highland2': 40,
    'subway1': 40, 'subway2': 45, 'ludibrium': 1,
    'toy_factory1': 45, 'toy_factory2': 50, 'aqua_road': 50,
    'jungle_path': 55, 'clock_tower': 60,
    'balrog_pit': 50, 'pianus_lair': 70,
  };

  // 战斗特效事件流 (UI 订阅触发动画/震屏)
  final _battleEffects = StreamController<BattleEffect>.broadcast();
  Stream<BattleEffect> get battleEffects => _battleEffects.stream;

  // 装备实例存储（key: instanceId, value: Equipment）
  final Map<String, Equipment> _equipmentInstances = {};

  GameNotifier({SaveRepository? saveRepository})
      : _saveRepository = saveRepository ?? HiveSaveRepository(),
        super(GameData.initial()) {
    // 自动尝试读取存档
    _init();
  }

  bool get isInitialized => _isInitialized;
  bool get isAutoExplore => state.isAutoExplore;
  bool get isAutoBattle => state.isAutoBattle;

  /// 通过instanceId获取装备实例
  Equipment? getEquipmentByInstanceId(String instanceId) {
    return _equipmentInstances[instanceId];
  }

  /// 自动存档:state 变化时 debounce 调度,避免密集写入
  @override
  set state(GameData value) {
    super.state = value;
    _scheduleAutoSave();
  }

  void _scheduleAutoSave() {
    if (!_isInitialized) return;
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(_autoSaveDebounce, _quietSave);
  }

  Future<void> _quietSave() async {
    try {
      await _saveRepository.saveGame(state, equipmentInstances: _equipmentInstances);
    } catch (e) {
      // ignore: avoid_print
      print('自动存档失败: $e');
    }
  }

  /// 立即存档 (用于 app 进入后台/退出前)
  Future<void> flushSave() async {
    _autoSaveTimer?.cancel();
    if (_isInitialized) {
      await _quietSave();
    }
  }

  /// 清理定时器
  @override
  void dispose() {
    _autoBattleTimer?.cancel();
    _autoSaveTimer?.cancel();
    _battleEffects.close();
    super.dispose();
  }

  /// 设置自动探索
  void setAutoExplore(bool value) {
    state = state.copyWith(isAutoExplore: value);
    if (value) {
      addLog('🤖 自动探索已开启', LogType.success);
      _startAutoMode();
    } else {
      addLog('🛑 自动探索已关闭', LogType.warning);
      if (!state.isAutoBattle) {
        _autoBattleTimer?.cancel();
      }
    }
  }

  /// 设置自动战斗
  void setAutoBattle(bool value) {
    state = state.copyWith(isAutoBattle: value);
    if (value) {
      addLog('⚔️ 自动战斗已开启', LogType.success);
      _startAutoMode();
    } else {
      addLog('🛑 自动战斗已关闭', LogType.warning);
      if (!state.isAutoExplore) {
        _autoBattleTimer?.cancel();
      }
    }
  }

  /// 启动自动模式定时器
  void _startAutoMode() {
    _autoBattleTimer?.cancel();
    // 每2秒执行一次自动操作
    _autoBattleTimer = Timer.periodic(const Duration(seconds: 2), (_) => _autoTick());
  }

  /// 单次执行自动动作 (定时器和 kick 共用)
  void _autoTick() {
    if (state.gameState == GameState.battling && state.currentMob != null) {
      if (state.isAutoBattle) attack();
    } else if (state.gameState == GameState.exploring) {
      if (state.isAutoExplore && !state.currentMap.isTown) explore();
    }
  }

  /// 战斗结束后让自动模式快速接续,避免 2s 呆滞
  void _kickAutoSoon() {
    if (!state.isAutoExplore && !state.isAutoBattle) return;
    Future.delayed(const Duration(milliseconds: 600), () {
      if (state.gameState == GameState.gameOver) return;
      _autoTick();
    });
  }

  /// 设置新玩家（用于创建角色）
  void setNewPlayer(Player player) {
    state = state.copyWith(player: player);
    addLog('🎉 欢迎，${player.name}！冒险开始了！', LogType.success);
    addLog('📝 初始属性: 力量${player.stats.str} 敏捷${player.stats.dex} 智力${player.stats.intStat} 运气${player.stats.luk}');
  }

  /// 初始化 - 自动读取存档（包含装备实例）
  Future<void> _init() async {
    try {
      final hasSave = await _saveRepository.hasSave();
      if (hasSave) {
        final savedData = await _saveRepository.loadGame();
        final equipmentInstances = await _saveRepository.loadEquipmentInstances();
        
        if (savedData != null) {
          state = savedData;
          
          // 恢复装备实例
          if (equipmentInstances != null) {
            _equipmentInstances.clear();
            _equipmentInstances.addAll(equipmentInstances);
          }
          
          addLog('📂 欢迎回来，${state.player.name}！', LogType.success);
        }
      }
    } catch (e) {
      print('自动读取存档失败: $e');
    }
    _isInitialized = true;
  }

  // 移动
  void move(String direction) {
    final currentMap = state.currentMap;
    final nextMapId = currentMap.exits[direction];

    if (nextMapId == null) {
      addLog('⛔ 这个方向没有路！', LogType.warning);
      return;
    }

    final nextMap = GameMaps.getMap(nextMapId);
    state = state.copyWith(currentMap: nextMap);
    addLog('🚶 你来到了 ${nextMap.name}');
    _autoStopOnTownEntry();
  }

  // 直接传送到指定地图
  void moveToMap(String mapId) {
    // 检查是否在战斗中
    if (state.gameState == GameState.battling) {
      addLog('⛔ 战斗中无法传送！', LogType.error);
      return;
    }

    // 检查是否在商店中
    if (state.gameState == GameState.shopping) {
      addLog('⛔ 请先离开商店', LogType.error);
      return;
    }

    // 获取目标地图
    final targetMap = GameMaps.getMap(mapId);

    // 等级检查
    final reqLevel = _mapLevelRequirements[mapId] ?? 1;
    if (state.player.stats.level < reqLevel) {
      addLog('⛔ 等级不足！需要 Lv.$reqLevel 才能进入 ${targetMap.name}', LogType.error);
      return;
    }

    state = state.copyWith(currentMap: targetMap);
    addLog('✨ 传送到了 ${targetMap.name}！', LogType.success);
    _autoStopOnTownEntry();
  }

  /// 进入城镇时自动关闭自动探索 (按下"自动探索"开关在城镇中没意义)
  void _autoStopOnTownEntry() {
    if (state.currentMap.isTown && state.isAutoExplore) {
      state = state.copyWith(isAutoExplore: false);
      if (!state.isAutoBattle) _autoBattleTimer?.cancel();
      addLog('🏘️ 进入城镇,自动探索已关闭', LogType.warning);
    }
  }

  // 探索（野外随机遭遇）
  void explore() {
    if (state.currentMap.isTown) {
      addLog('⛔ 村庄里很安全，没有什么可探索的', LogType.normal);
      return;
    }

    if (state.currentMap.mobs.isEmpty) {
      addLog('🔍 这片区域很平静，没有发现怪物', LogType.normal);
      return;
    }

    addLog('🔍 正在探索这片区域...', LogType.normal);

    // 50% 概率遇到怪物
    if (state.random.nextDouble() < 0.5) {
      final mobType = state.currentMap.mobs[state.random.nextInt(state.currentMap.mobs.length)];
      startBattle(mobType);
    } else {
      // 探索发现金币或其他东西
      final findGold = state.random.nextInt(10) + 1;
      state = state.copyWith(
        player: state.player.copyWith(meso: state.player.meso + findGold),
      );
      addLog('💰 探索发现 $findGold 金币！', LogType.reward);
    }
  }

  // 开始战斗
  void startBattle(MobType mobType) {
    final mob = Mob.create(mobType);
    state = state.copyWith(
      gameState: GameState.battling,
      currentMob: mob,
    );
    addLog('👹 遭遇 ${mob.name}！', LogType.battle);
  }

  // 攻击
  void attack() {
    if (state.gameState != GameState.battling || state.currentMob == null) return;
    _executePlayerAttack(skillMultiplier: 1.0, mpCost: 0);
  }

  /// 使用职业独享技能。倍率含玩家技能等级加成
  void useSkill() {
    if (state.gameState != GameState.battling || state.currentMob == null) return;

    final skill = state.player.job.skill;
    if (state.player.stats.mp < skill.mpCost) {
      addLog('❌ MP 不足 (需要 ${skill.mpCost})', LogType.error);
      return;
    }
    _executePlayerAttack(
      skillMultiplier: state.player.skillFinalMultiplier,
      mpCost: skill.mpCost,
      isSkill: true,
      skillName: '${skill.emoji} ${skill.name}',
      forceCrit: skill.alwaysCrit,
    );
  }

  /// 玩家攻击的统一入口: 普攻和技能共用,保证暴击/闪避规则一致
  void _executePlayerAttack({
    required double skillMultiplier,
    required int mpCost,
    bool isSkill = false,
    String? skillName,
    bool forceCrit = false,
  }) {
    final player = state.player;
    final mob = state.currentMob!;

    // 玩家命中
    final hit = _rollPlayerHit(player, mob, multiplier: skillMultiplier, forceCrit: forceCrit);
    _battleEffects.add(BattleEffect(
      target: BattleEffectTarget.mob,
      damage: hit.damage,
      isCrit: hit.isCrit,
    ));

    if (isSkill) {
      final label = skillName ?? '✨ 技能';
      addLog(
        hit.isCrit
            ? '$label 暴击！对 ${mob.name} 造成 ${hit.damage} 点伤害！'
            : '$label 对 ${mob.name} 造成 ${hit.damage} 点伤害！',
        LogType.battle,
      );
    } else {
      addLog(
        hit.isCrit
            ? '💥 暴击！你对 ${mob.name} 造成 ${hit.damage} 点伤害！'
            : '⚔️ 你对 ${mob.name} 造成 ${hit.damage} 点伤害！',
        hit.isCrit ? LogType.reward : LogType.battle,
      );
    }

    // 海盗/拳手/刺客追打被动: 概率触发额外打击
    int extraDamage = 0;
    if (player.job.extraHitChance > 0) {
      if (state.random.nextDouble() < player.job.extraHitChance) {
        extraDamage = (hit.damage * player.job.extraHitDamageRatio).toInt();
        if (extraDamage > 0) {
          _battleEffects.add(BattleEffect(
            target: BattleEffectTarget.mob,
            damage: extraDamage,
            isCrit: false,
            isExtraHit: true,
          ));
          addLog('⚡ 追加打击！再造成 $extraDamage 伤害', LogType.reward);
        }
      }
    }

    final totalDamage = hit.damage + extraDamage;
    final newMobHp = mob.hp - totalDamage;

    // 怪物死亡
    if (newMobHp <= 0) {
      _battleEffects.add(BattleEffect(
        target: BattleEffectTarget.mob,
        damage: hit.damage,
        isFatal: true,
      ));
      _winBattle(mob);
      return;
    }

    // 扣除 MP (技能消耗)
    final mobAlive = mob.copyWith(hp: newMobHp);
    final playerAfterMp = mpCost > 0
        ? player.copyWith(stats: player.stats.copyWith(mp: player.stats.mp - mpCost))
        : player;

    // 怪物反击 (闪避检定)
    final counter = _rollMobHit(playerAfterMp, mobAlive);
    _battleEffects.add(BattleEffect(
      target: BattleEffectTarget.player,
      damage: counter.damage,
      isAvoided: counter.isAvoided,
      isReduced: !counter.isAvoided && playerAfterMp.job.damageReduction > 0,
    ));
    if (counter.isAvoided) {
      addLog('💨 你闪避了 ${mob.name} 的攻击！', LogType.success);
      state = state.copyWith(currentMob: mobAlive, player: playerAfterMp);
      return;
    }

    final newPlayerHp = playerAfterMp.stats.hp - counter.damage;
    addLog('💥 ${mob.name} 对你造成 ${counter.damage} 点伤害！', LogType.warning);

    if (newPlayerHp <= 0) {
      _battleEffects.add(BattleEffect(
        target: BattleEffectTarget.player,
        damage: counter.damage,
        isFatal: true,
      ));
      _gameOver();
      return;
    }

    state = state.copyWith(
      currentMob: mobAlive,
      player: playerAfterMp.copyWith(
        stats: playerAfterMp.stats.copyWith(hp: newPlayerHp),
      ),
    );
  }

  _PlayerHit _rollPlayerHit(Player player, Mob mob, {double multiplier = 1.0, bool forceCrit = false}) {
    final base = (player.getAtk() * multiplier - mob.def).clamp(1, 9999).toInt();
    final critRate = player.getCritRate();
    final isCrit = forceCrit || state.random.nextDouble() * 100 < critRate;
    // 暴击倍率按职业不同 (弓箭手系更高)
    final critMult = player.job.critDamageMultiplier;
    final damage = isCrit ? (base * critMult).toInt() : base;
    return _PlayerHit(damage: damage, isCrit: isCrit);
  }

  _MobHit _rollMobHit(Player player, Mob mob) {
    final avoidRate = player.getAvoidRate();
    final isAvoided = state.random.nextDouble() * 100 < avoidRate;
    if (isAvoided) {
      return const _MobHit(damage: 0, isAvoided: true);
    }
    var damage = (mob.atk - player.getDef()).clamp(1, 9999).toInt();
    // 战士系减伤被动
    if (player.job.damageReduction > 0) {
      damage = (damage * (1 - player.job.damageReduction)).toInt().clamp(1, 9999);
    }
    return _MobHit(damage: damage, isAvoided: false);
  }

  // 逃跑
  void flee() {
    if (state.gameState != GameState.battling) return;

    if (state.random.nextDouble() < 0.5) {
      addLog('🏃 逃跑成功！', LogType.success);
      state = state.copyWith(
        gameState: GameState.exploring,
        currentMob: null,
      );
      _kickAutoSoon();
    } else {
      addLog('❌ 逃跑失败！', LogType.error);
      // 怪物反击
      _mobCounterAttack();
    }
  }

  // 休息恢复
  void rest() {
    if (!state.currentMap.isTown) {
      addLog('⛔ 只能在村庄休息！', LogType.warning);
      return;
    }

    final player = state.player;
    final newHp = (player.stats.hp + player.stats.maxHp ~/ 2).clamp(0, player.stats.maxHp);
    final newMp = (player.stats.mp + player.stats.maxMp ~/ 2).clamp(0, player.stats.maxMp);

    state = state.copyWith(
      player: player.copyWith(
        stats: player.stats.copyWith(hp: newHp, mp: newMp),
      ),
    );
    addLog('💤 休息了一会儿，HP 和 MP 恢复了！', LogType.success);
  }

  // 战斗胜利
  void _winBattle(Mob mob) {
    final player = state.player;
    final newExp = player.stats.exp + mob.exp;
    final newMeso = player.meso + mob.exp * 5;

    addLog('🎉 击败了 ${mob.name}！', LogType.success);
    addLog('💰 获得 ${mob.exp * 5} 金币，${mob.exp} 经验值！', LogType.reward);

    // 获取掉落物品ID列表
    final dropIds = mob.getDrops();
    final newInventory = List<String>.from(player.inventory);

    for (final itemId in dropIds) {
      final item = ShopDatabase.getById(itemId);
      if (item != null) {
        newInventory.add(itemId);
        addLog('📦 获得掉落：${item.name}！', LogType.reward);
      }
    }

    // 装备掉落（5%概率）- 生成带UUID的装备实例
    final droppedEquip = EquipmentDatabase.getRandomDrop(player.stats.level);
    if (droppedEquip != null) {
      // 创建带唯一instanceId的装备副本
      final equipInstance = droppedEquip.copyWithInstanceId();
      final instanceId = equipInstance.instanceId!;
      newInventory.add(instanceId);
      // 将装备实例存入临时存储（用于后续查找）
      _equipmentInstances[instanceId] = equipInstance;
      addLog('✨ 稀有掉落：${equipInstance.name}！', LogType.reward);
    }

    // 更新任务进度（如果有狩猎任务）
    updateQuestProgress(mob.name);

    // 升级检查(循环处理连续升级,保留溢出经验)
    var updatedPlayer = player.copyWith(
      stats: player.stats.copyWith(exp: newExp),
      meso: newMeso,
      inventory: newInventory,
    );

    while (updatedPlayer.stats.exp >= updatedPlayer.stats.maxExp) {
      updatedPlayer = _levelUp(updatedPlayer);
    }

    // 每次击杀获得 1 SP (技能点)
    updatedPlayer = updatedPlayer.copyWith(
      stats: updatedPlayer.stats.copyWith(sp: updatedPlayer.stats.sp + 1),
    );
    addLog('⭐ 获得 1 SP (当前 ${updatedPlayer.stats.sp})', LogType.reward);

    // 法师系击杀回 MP 被动
    final mpRegen = updatedPlayer.job.mpRegenOnKill;
    if (mpRegen > 0) {
      final regenAmount = (updatedPlayer.stats.maxMp * mpRegen).toInt();
      if (regenAmount > 0) {
        final newMp = (updatedPlayer.stats.mp + regenAmount).clamp(0, updatedPlayer.stats.maxMp);
        updatedPlayer = updatedPlayer.copyWith(
          stats: updatedPlayer.stats.copyWith(mp: newMp),
        );
        addLog('💧 击杀回复 $regenAmount MP', LogType.success);
        // 飘字提示
        _battleEffects.add(BattleEffect(
          target: BattleEffectTarget.player,
          damage: 0,
          mpRegenAmount: regenAmount,
        ));
      }
    }

    state = state.copyWith(
      gameState: GameState.exploring,
      currentMob: null,
      player: updatedPlayer,
    );

    // 战斗胜利后,如果开了自动探索,立即触发下一次探索 (而非等 2s)
    _kickAutoSoon();
  }

  // 升级
  Player _levelUp(Player player) {
    final newLevel = player.stats.level + 1;
    final newMaxExp = (player.stats.maxExp * 1.5).toInt();
    // 职业差异化: HP/MP 按职业不同
    final newMaxHp = player.stats.maxHp + player.job.hpPerLevel;
    final newMaxMp = player.stats.maxMp + player.job.mpPerLevel;
    final newAp = player.stats.ap + 5;  // 获得5点自由属性点
    // 保留溢出经验
    final overflowExp = player.stats.exp - player.stats.maxExp;

    addLog('🆙 升级了！到达 Lv.$newLevel！', LogType.success);
    addLog('💫 +${player.job.hpPerLevel} HP / +${player.job.mpPerLevel} MP / +5 AP (${player.job.recommendedStat})', LogType.reward);

    // 检查任务解锁
    checkQuestUnlock();

    return player.copyWith(
      stats: player.stats.copyWith(
        level: newLevel,
        exp: overflowExp,
        maxExp: newMaxExp,
        maxHp: newMaxHp,
        maxMp: newMaxMp,
        hp: newMaxHp,
        mp: newMaxMp,
        ap: newAp,  // 增加属性点，不加固定属性
      ),
    );
  }

  // 怪物反击
  void _mobCounterAttack() {
    if (state.currentMob == null) return;

    final player = state.player;
    final mob = state.currentMob!;
    final damage = (mob.atk - player.getDef()).clamp(1, 9999);
    final newHp = player.stats.hp - damage;

    addLog('💥 ${mob.name} 造成 $damage 点伤害！', LogType.warning);

    if (newHp <= 0) {
      _gameOver();
      return;
    }

    state = state.copyWith(
      player: player.copyWith(
        stats: player.stats.copyWith(hp: newHp),
      ),
    );
  }

  // 游戏结束 - 死亡回到射手村
  void _gameOver() {
    final player = state.player;
    final henesys = GameMaps.getMap('henesys');

    // 扣除10%金币作为惩罚
    final penalty = (player.meso * 0.1).toInt();
    final newMeso = player.meso - penalty;

    state = state.copyWith(
      gameState: GameState.exploring,
      currentMob: null,
      currentMap: henesys,
      player: player.copyWith(
        currentMap: 'henesys',
        meso: newMeso,
        stats: player.stats.copyWith(
          hp: 1,  // 剩1点血
        ),
      ),
      isAutoExplore: false,
      isAutoBattle: false,
    );
    _autoBattleTimer?.cancel();

    addLog('💀 你被击败了...', LogType.error);
    addLog('💨 被传送回射手村，HP 恢复至 1', LogType.warning);
    if (penalty > 0) {
      addLog('💸 损失 $penalty 金币作为惩罚', LogType.warning);
    }
    addLog('🛑 自动模式已关闭', LogType.warning);
    addLog('🏥 去找治疗师休息恢复吧！', LogType.success);
  }

  // 重新开始
  void restart() {
    state = GameData.initial();
    addLog('🎮 新的开始！欢迎来到冒险岛世界！');
  }

  // 购买物品
  bool buyItem(GameItem item) {
    if (state.player.meso < item.price) {
      addLog('❌ 金币不足，无法购买 ${item.name}', LogType.error);
      return false;
    }

    // 扣除金币
    final newPlayer = state.player.copyWith(
      meso: state.player.meso - item.price,
      inventory: [...state.player.inventory, item.id],
    );

    state = state.copyWith(player: newPlayer);
    addLog('🛒 购买了 ${item.name}，花费 ${item.price} 金币', LogType.success);
    return true;
  }

  // 使用物品
  bool useItem(String itemId) {
    final item = ShopDatabase.getById(itemId);
    if (item == null) return false;

    // 检查背包中是否有该物品
    final itemIndex = state.player.inventory.indexOf(itemId);
    if (itemIndex == -1) {
      addLog('❌ 背包中没有 ${item.name}', LogType.error);
      return false;
    }

    // 使用物品效果
    final newPlayer = item.use(state.player);

    // 从背包中移除一个
    final newInventory = List<String>.from(state.player.inventory);
    newInventory.removeAt(itemIndex);

    state = state.copyWith(
      player: newPlayer.copyWith(inventory: newInventory),
    );

    String effectMsg = '';
    switch (item.effect?.type) {
      case 'heal_hp':
        effectMsg = '恢复了 ${item.effect?.value} 点 HP';
        break;
      case 'heal_mp':
        effectMsg = '恢复了 ${item.effect?.value} 点 MP';
        break;
      case 'teleport':
        effectMsg = '使用回城卷轴回到了射手村';
        break;
    }

    addLog('✨ 使用了 ${item.name}，$effectMsg', LogType.success);
    return true;
  }

  // 打开商店
  void openShop() {
    if (!state.currentMap.isTown) {
      addLog('⛔ 只能在村庄进入商店！', LogType.warning);
      return;
    }
    state = state.copyWith(
      gameState: GameState.shopping,
      shopCategory: ShopCategory.all,  // 重置分类为全部
    );
    addLog('🏪 进入了商店');
  }

  // 购买装备
  bool buyEquipment(Equipment equipment) {
    final price = equipment.price ?? 0;
    final levelReq = equipment.levelReq ?? 1;

    if (state.player.meso < price) {
      addLog('❌ 金币不足，无法购买 ${equipment.name}', LogType.error);
      return false;
    }

    if (state.player.stats.level < levelReq) {
      addLog('❌ 等级不足，需要 Lv.$levelReq 才能装备 ${equipment.name}', LogType.error);
      return false;
    }

    // 生成新的装备实例（带唯一ID）
    final newEquipment = equipment.copyWithInstanceId();
    final String newInstanceId = newEquipment.instanceId;  // 显式转换为非空

    // 将装备实例存入映射表
    _equipmentInstances[newInstanceId] = newEquipment;

    // 扣除金币，装备直接进背包
    final newPlayer = state.player.copyWith(
      meso: state.player.meso - price,
      inventory: [...state.player.inventory, newInstanceId],
    );

    state = state.copyWith(player: newPlayer);
    addLog('🛡️ 购买了 ${equipment.name}，已放入背包', LogType.success);
    return true;
  }

  // 装备物品
  bool equipItem(String equipmentIdOrInstanceId) {
    // 先尝试从实例存储中查找（用于掉落/购买的装备）
    Equipment? equipment = _equipmentInstances[equipmentIdOrInstanceId];

    // 如果没找到，尝试从装备数据库查找（用于旧存档兼容）
    equipment ??= EquipmentDatabase.getById(equipmentIdOrInstanceId);

    if (equipment == null) {
      addLog('❌ 找不到该装备', LogType.error);
      return false;
    }

    // 检查背包中是否有该装备（匹配 instanceId 或 equipment.id）
    final String? equipId = equipment.id;
    final itemIndex = state.player.inventory.indexWhere(
      (id) => id == equipmentIdOrInstanceId || (equipId != null && id == equipId)
    );

    if (itemIndex == -1) {
      addLog('❌ 背包中没有 ${equipment.name}', LogType.error);
      return false;
    }

    // 检查等级要求
    final levelReq = equipment.levelReq ?? 1;
    if (state.player.stats.level < levelReq) {
      addLog('❌ 等级不足，需要 Lv.$levelReq 才能装备 ${equipment.name}', LogType.error);
      return false;
    }

    // 从背包中移除装备（移除实际存储的ID）
    final newInventory = List<String>.from(state.player.inventory);
    final removedId = newInventory.removeAt(itemIndex);

    // 获取当前已装备的同类装备（如果有）
    final currentEquip = state.player.equipment[equipment.slot];

    // 卸下当前装备（如果有）并放入背包
    if (currentEquip != null) {
      // 已装备的装备使用 instanceId 放回背包
      final String instanceToAdd = currentEquip.instanceId;  // 现在 instanceId 是非空的
      newInventory.add(instanceToAdd);
      addLog('📦 自动卸下 ${currentEquip.name}', LogType.normal);
    }

    // 装备新装备
    final newEquipment = Map<EquipmentSlot, Equipment?>.from(state.player.equipment);
    newEquipment[equipment.slot] = equipment;

    // 更新玩家状态
    final newPlayer = state.player.copyWith(
      inventory: newInventory,
      equipment: newEquipment,
    );

    state = state.copyWith(player: newPlayer);
    addLog('✨ 装备了 ${equipment.name}！${equipment.stats}', LogType.success);
    return true;
  }

  // 分配属性点
  bool allocateStat(String statType) {
    if (state.player.stats.ap <= 0) {
      addLog('❌ 没有可用的属性点', LogType.error);
      return false;
    }

    final currentStats = state.player.stats;
    int newStr = currentStats.str;
    int newDex = currentStats.dex;
    int newInt = currentStats.intStat;
    int newLuk = currentStats.luk;

    switch (statType) {
      case 'str':
        newStr++;
        addLog('💪 力量 +1', LogType.success);
        break;
      case 'dex':
        newDex++;
        addLog('🏃 敏捷 +1', LogType.success);
        break;
      case 'int':
        newInt++;
        addLog('🧠 智力 +1', LogType.success);
        break;
      case 'luk':
        newLuk++;
        addLog('🍀 运气 +1', LogType.success);
        break;
      default:
        return false;
    }

    state = state.copyWith(
      player: state.player.copyWith(
        stats: currentStats.copyWith(
          str: newStr,
          dex: newDex,
          intStat: newInt,
          luk: newLuk,
          ap: currentStats.ap - 1,
        ),
      ),
    );
    return true;
  }

  // 卸下装备
  bool unequipItem(EquipmentSlot slot) {
    final currentEquip = state.player.equipment[slot];
    if (currentEquip == null) {
      addLog('❌ 该位置没有装备', LogType.error);
      return false;
    }

    // 从装备槽移除
    final newEquipment = Map<EquipmentSlot, Equipment?>.from(state.player.equipment);
    newEquipment[slot] = null;

    // 将装备放回背包
    final newInventory = List<String>.from(state.player.inventory);
    newInventory.add(currentEquip.instanceId);
    
    // 确保装备实例在映射表中
    _equipmentInstances[currentEquip.instanceId] = currentEquip;

    // 更新玩家状态
    final newPlayer = state.player.copyWith(
      inventory: newInventory,
      equipment: newEquipment,
    );

    state = state.copyWith(player: newPlayer);
    addLog('📦 卸下了 ${currentEquip.name}', LogType.success);
    return true;
  }

  // 设置商店分类
  void setShopCategory(ShopCategory category) {
    state = state.copyWith(shopCategory: category);
  }

  // 卖出物品（支持批量）
  bool sellItem(String itemIdOrInstanceId, {int quantity = 1}) {
    // 先尝试从装备实例存储中查找（用于掉落/购买的装备）
    Equipment? equipment = _equipmentInstances[itemIdOrInstanceId];

    // 再尝试从普通物品查找
    final item = ShopDatabase.getById(itemIdOrInstanceId);

    // 再尝试从装备数据库查找（兼容旧存档）
    equipment ??= EquipmentDatabase.getById(itemIdOrInstanceId);

    final itemName = item?.name ?? equipment?.name ?? '物品';
    final itemPrice = item?.price ?? equipment?.price ?? 0;

    // 检查背包中是否有足够数量（匹配 instanceId 或 equipment.id）
    final equipId = equipment?.id;
    final inventoryCount = state.player.inventory.where(
      (id) => id == itemIdOrInstanceId || (equipId != null && id == equipId)
    ).length;

    if (inventoryCount < quantity) {
      addLog('❌ 背包中 $itemName 数量不足', LogType.error);
      return false;
    }

    // 卖出价格（原价的50%）
    final sellPrice = (itemPrice * 0.5).toInt();
    final totalPrice = sellPrice * quantity;

    // 从背包中移除指定数量
    final newInventory = List<String>.from(state.player.inventory);
    int removed = 0;
    newInventory.removeWhere((id) {
      if ((id == itemIdOrInstanceId || (equipId != null && id == equipId)) && removed < quantity) {
        removed++;
        // 如果是装备实例，从映射表中移除
        if (_equipmentInstances.containsKey(id)) {
          _equipmentInstances.remove(id);
        }
        return true;
      }
      return false;
    });

    // 增加金币
    state = state.copyWith(
      player: state.player.copyWith(
        meso: state.player.meso + totalPrice,
        inventory: newInventory,
      ),
    );

    addLog('💰 卖出 $itemName x$quantity，获得 $totalPrice 金币', LogType.success);
    return true;
  }

  // 关闭商店
  void closeShop() {
    state = state.copyWith(gameState: GameState.exploring);
    addLog('👋 离开了商店');
  }

  // 修改玩家名字
  bool changePlayerName(String newName) {
    if (newName.trim().isEmpty) {
      addLog('❌ 名字不能为空', LogType.error);
      return false;
    }
    
    if (newName.length > 10) {
      addLog('❌ 名字不能超过10个字符', LogType.error);
      return false;
    }

    final oldName = state.player.name;
    state = state.copyWith(
      player: state.player.copyWith(name: newName.trim()),
    );
    addLog('✨ $oldName 改名为 $newName！', LogType.success);
    return true;
  }

  // 更新装备潜能
  void updateEquipmentPotential(String equipmentInstanceId, EquipmentPotential potential) {
    // 更新装备实例映射
    final equipment = _equipmentInstances[equipmentInstanceId];
    if (equipment != null) {
      _equipmentInstances[equipmentInstanceId] = Equipment(
        name: equipment.name,
        id: equipment.id,
        instanceId: equipment.instanceId,
        emoji: equipment.emoji,
        description: equipment.description,
        slot: equipment.slot,
        atk: equipment.atk,
        def: equipment.def,
        str: equipment.str,
        dex: equipment.dex,
        intBonus: equipment.intBonus,
        luk: equipment.luk,
        price: equipment.price,
        levelReq: equipment.levelReq,
        crit: equipment.crit,
        avoid: equipment.avoid,
        potential: potential,
      );
    }

    // 如果装备当前已装备，更新玩家状态
    final currentEquip = state.player.equipment.values
        .firstWhere((e) => e?.instanceId == equipmentInstanceId, orElse: () => null);
    
    if (currentEquip != null) {
      final newEquipment = Map<EquipmentSlot, Equipment?>.from(state.player.equipment);
      for (final entry in newEquipment.entries) {
        if (entry.value?.instanceId == equipmentInstanceId) {
          newEquipment[entry.key] = _equipmentInstances[equipmentInstanceId];
          break;
        }
      }
      
      state = state.copyWith(
        player: state.player.copyWith(equipment: newEquipment),
      );
    }
  }

  // ========== 存档功能 ==========

  /// 保存游戏（包含装备实例）
  Future<bool> saveGame() async {
    try {
      await _saveRepository.saveGame(state, equipmentInstances: _equipmentInstances);
      addLog('💾 游戏已保存', LogType.success);
      return true;
    } catch (e) {
      addLog('❌ 保存失败: $e', LogType.error);
      return false;
    }
  }

  /// 读取存档（包含装备实例）
  Future<bool> loadGame() async {
    try {
      final savedData = await _saveRepository.loadGame();
      final equipmentInstances = await _saveRepository.loadEquipmentInstances();
      
      if (savedData != null) {
        state = savedData;
        
        // 恢复装备实例
        if (equipmentInstances != null) {
          _equipmentInstances.clear();
          _equipmentInstances.addAll(equipmentInstances);
        }
        
        addLog('📂 存档已读取', LogType.success);
        return true;
      } else {
        addLog('⚠️ 没有找到存档', LogType.warning);
        return false;
      }
    } catch (e) {
      addLog('❌ 读取失败: $e', LogType.error);
      return false;
    }
  }

  /// 检查是否有存档
  Future<bool> hasSave() async {
    return await _saveRepository.hasSave();
  }

  /// 删除存档
  Future<bool> deleteSave() async {
    try {
      await _saveRepository.deleteSave();
      addLog('🗑️ 存档已删除', LogType.success);
      return true;
    } catch (e) {
      addLog('❌ 删除失败: $e', LogType.error);
      return false;
    }
  }

  /// 导出存档为 JSON（包含装备实例）
  Future<String?> exportToJson() async {
    try {
      return await _saveRepository.exportToJson(_equipmentInstances);
    } catch (e) {
      addLog('❌ 导出失败: $e', LogType.error);
      return null;
    }
  }

  /// 从 JSON 导入存档
  Future<bool> importFromJson(String json) async {
    try {
      await _saveRepository.importFromJson(json);
      // 重新加载
      final savedData = await _saveRepository.loadGame();
      if (savedData != null) {
        state = savedData;
        addLog('📥 存档已导入', LogType.success);
        return true;
      }
      return false;
    } catch (e) {
      addLog('❌ 导入失败: $e', LogType.error);
      return false;
    }
  }

  // 添加日志
  void addLog(String message, [LogType type = LogType.normal]) {
    final newLogs = [...state.logs, LogEntry(message: message, type: type)];
    if (newLogs.length > 100) {
      newLogs.removeAt(0);
    }
    state = state.copyWith(logs: newLogs);
  }

  // ========== 邮件系统 ==========

  /// 标记邮件为已读
  void markMailAsRead(String mailId) {
    final newMails = state.mails.map((mail) {
      if (mail.id == mailId) {
        return mail.copyWith(isRead: true);
      }
      return mail;
    }).toList();
    state = state.copyWith(mails: newMails);
  }

  /// 领取邮件附件
  bool claimMailAttachments(String mailId) {
    final mail = state.mails.firstWhere((m) => m.id == mailId);
    if (mail.isClaimed || mail.attachments.isEmpty) {
      return false;
    }

    // 添加附件到背包
    final newInventory = [...state.player.inventory];
    for (final attachment in mail.attachments) {
      switch (attachment.type) {
        case MailAttachmentType.item:
          if (attachment.itemId != null && attachment.count != null) {
            for (int i = 0; i < attachment.count!; i++) {
              newInventory.add(attachment.itemId!);
            }
          }
          break;
        case MailAttachmentType.meso:
          // 金币直接加到玩家身上
          if (attachment.meso != null) {
            state = state.copyWith(
              player: state.player.copyWith(
                meso: state.player.meso + attachment.meso!,
              ),
            );
          }
          break;
        case MailAttachmentType.equipment:
          if (attachment.equipmentId != null) {
            // 通过装备ID生成装备实例
            final equipment = EquipmentDatabase.getById(attachment.equipmentId!);
            if (equipment != null) {
              final equipInstance = equipment.copyWithInstanceId();
              final instanceId = equipInstance.instanceId;
              _equipmentInstances[instanceId] = equipInstance;
              newInventory.add(instanceId);
            }
          } else if (attachment.instanceId != null) {
            newInventory.add(attachment.instanceId!);
          }
          break;
      }
    }

    // 更新玩家背包和邮件状态
    state = state.copyWith(
      player: state.player.copyWith(inventory: newInventory),
      mails: state.mails.map((m) {
        if (m.id == mailId) {
          return m.copyWith(isClaimed: true, isRead: true);
        }
        return m;
      }).toList(),
    );

    addLog('📧 已领取邮件附件', LogType.success);
    return true;
  }

  /// 删除邮件
  void deleteMail(String mailId) {
    final newMails = state.mails.where((m) => m.id != mailId).toList();
    state = state.copyWith(mails: newMails);
  }

  /// 发送邮件（用于系统邮件）
  void sendSystemMail(GameMail mail) {
    state = state.copyWith(
      mails: [...state.mails, mail],
    );
    addLog('📧 收到新邮件：${mail.title}', LogType.success);
  }

  // ========== 任务系统 ==========

  /// 接受任务
  void acceptQuest(String questId) {
    final quest = state.quests.firstWhere((q) => q.id == questId);
    
    // 检查是否是转职任务
    if (quest.type == QuestType.jobChange) {
      // 检查是否已有进行中的转职任务
      final activeJobQuest = state.quests.firstWhere(
        (q) => q.type == QuestType.jobChange && q.status == QuestStatus.inProgress,
        orElse: () => quest, // 如果没有找到，返回当前任务（避免null）
      );
      
      // 如果已有进行中的转职任务且不是同一个任务，放弃之前的
      if (activeJobQuest.id != questId && activeJobQuest.status == QuestStatus.inProgress) {
        // 放弃之前的转职任务
        final abandonedQuests = state.quests.map((q) {
          if (q.id == activeJobQuest.id) {
            return q.copyWith(status: QuestStatus.available, currentCount: 0);
          }
          return q;
        }).toList();
        
        state = state.copyWith(quests: abandonedQuests);
        addLog('❌ 已放弃任务：${activeJobQuest.title}', LogType.warning);
      }
    }
    
    // 接受新任务
    final newQuests = state.quests.map((q) {
      if (q.id == questId) {
        return q.copyWith(status: QuestStatus.inProgress);
      }
      return q;
    }).toList();
    state = state.copyWith(quests: newQuests);
  }

  /// 更新任务进度（狩猎/收集）
  void updateQuestProgress(String mobId) {
    final newQuests = state.quests.map((quest) {
      if (quest.status == QuestStatus.inProgress &&
          quest.targetMobs.contains(mobId)) {
        final newCount = quest.currentCount + 1;
        if (newCount >= quest.targetCount) {
          addLog('✅ 任务完成：${quest.title}', LogType.success);
          return quest.copyWith(
            currentCount: newCount,
            status: QuestStatus.completed,
          );
        }
        return quest.copyWith(currentCount: newCount);
      }
      return quest;
    }).toList();
    state = state.copyWith(quests: newQuests);
  }

  /// 领取任务奖励
  void claimQuestReward(String questId) {
    final quest = state.quests.firstWhere((q) => q.id == questId);
    if (quest.status != QuestStatus.completed) return;

    // 发放奖励
    int mesoReward = quest.rewards['meso'] ?? 0;
    int expReward = quest.rewards['exp'] ?? 0;

    final newQuests = state.quests.map((q) {
      if (q.id == questId) {
        return q.copyWith(status: QuestStatus.claimed);
      }
      return q;
    }).toList();

    // 更新玩家数据
    var newPlayer = state.player;
    if (mesoReward > 0) {
      newPlayer = newPlayer.copyWith(meso: newPlayer.meso + mesoReward);
    }
    if (expReward > 0) {
      newPlayer = newPlayer.copyWith(
        stats: newPlayer.stats.copyWith(exp: newPlayer.stats.exp + expReward),
      );
      // 循环处理连续升级(保留溢出经验)
      while (newPlayer.stats.exp >= newPlayer.stats.maxExp) {
        newPlayer = _levelUp(newPlayer);
      }
    }

    state = state.copyWith(
      quests: newQuests,
      player: newPlayer,
    );
  }

  /// 完成转职
  void completeJobChange(String questId, Job newJob) {
    final quest = state.quests.firstWhere((q) => q.id == questId);
    if (quest.status != QuestStatus.inProgress) return;

    // 更新任务状态为已完成
    final newQuests = state.quests.map((q) {
      if (q.id == questId) {
        return q.copyWith(status: QuestStatus.completed);
      }
      return q;
    }).toList();

    // 更新玩家职业
    final newPlayer = state.player.copyWith(job: newJob);

    state = state.copyWith(
      quests: newQuests,
      player: newPlayer,
    );

    // 领取转职奖励
    claimQuestReward(questId);
  }

  /// 升级职业技能 (花费 SP)
  bool upgradeSkill() {
    final player = state.player;
    final currentLevel = player.currentSkillLevel;
    final cost = Player.skillUpgradeCost(currentLevel);

    if (currentLevel >= Player.maxSkillLevel) {
      addLog('❌ ${player.job.skill.name} 已达最高等级 Lv.${Player.maxSkillLevel}', LogType.warning);
      return false;
    }

    if (player.stats.sp < cost) {
      addLog('❌ SP 不足 (需要 $cost SP, 当前 ${player.stats.sp})', LogType.error);
      return false;
    }

    final newLevel = currentLevel + 1;
    final newSkillLevels = Map<String, int>.from(player.skillLevels)
      ..[player.job.name] = newLevel;

    final newSkill = player.job.skill;
    final newMult = newSkill.multiplier * (1 + newLevel * 0.05);

    state = state.copyWith(
      player: player.copyWith(
        stats: player.stats.copyWith(sp: player.stats.sp - cost),
        skillLevels: newSkillLevels,
      ),
    );

    addLog(
      '🎯 ${newSkill.emoji} ${newSkill.name} 升级至 Lv.$newLevel！(消耗 $cost SP)',
      LogType.success,
    );
    addLog(
      '⚡ 技能倍率: ${newSkill.multiplier.toStringAsFixed(1)}× → ${newMult.toStringAsFixed(2)}×',
      LogType.reward,
    );
    return true;
  }

  /// 检查并解锁新任务（升级时调用）
  void checkQuestUnlock() {
    final player = state.player;
    final newQuests = state.quests.map((quest) {
      if (quest.status == QuestStatus.available && quest.canAccept(player)) {
        addLog('📜 新任务可用：${quest.title}', LogType.success);
      }
      return quest;
    }).toList();
    state = state.copyWith(quests: newQuests);
  }
}

// 游戏数据
class GameData {
  final Player player;
  final GameMap currentMap;
  final GameState gameState;
  final Mob? currentMob;
  final List<LogEntry> logs;
  final Random random;
  final ShopCategory shopCategory;  // 当前商店分类
  final List<GameMail> mails;       // 邮件列表
  final List<GameQuest> quests;     // 任务列表
  final bool isAutoExplore;         // 自动探索开关
  final bool isAutoBattle;          // 自动战斗开关

  GameData({
    required this.player,
    required this.currentMap,
    required this.gameState,
    this.currentMob,
    required this.logs,
    required this.random,
    this.shopCategory = ShopCategory.all,
    this.mails = const [],
    this.quests = const [],
    this.isAutoExplore = false,
    this.isAutoBattle = false,
  });

  factory GameData.initial() {
    // 创建新玩家并发送新手邮件
    final newPlayer = Player.create('冒险家');
    final welcomeMails = [
      MailTemplates.welcomeMail(),
      MailTemplates.newPlayerGift(),
    ];
    // 加载任务数据库
    final initialQuests = QuestDatabase.getAllQuests();
    
    return GameData(
      player: newPlayer,
      currentMap: GameMaps.getMap('henesys'),
      gameState: GameState.exploring,
      currentMob: null,
      logs: [LogEntry(message: '🎮 欢迎来到冒险岛世界！')],
      random: Random(),
      mails: welcomeMails,
      quests: initialQuests,
    );
  }

  /// 获取未读邮件数量
  int get unreadMailCount => mails.where((m) => !m.isRead).length;

  /// 获取有未领取附件的邮件数量
  int get unclaimedAttachmentCount => 
      mails.where((m) => m.hasUnclaimedAttachments).length;

  /// 获取进行中的任务数量
  int get activeQuestCount => quests.where((q) => q.status == QuestStatus.inProgress).length;

  /// 获取可接取的任务数量
  int get availableQuestCount => quests.where((q) => q.status == QuestStatus.available).toList().length;

  GameData copyWith({
    Player? player,
    GameMap? currentMap,
    GameState? gameState,
    Mob? currentMob,
    List<LogEntry>? logs,
    ShopCategory? shopCategory,
    List<GameMail>? mails,
    List<GameQuest>? quests,
    bool? isAutoExplore,
    bool? isAutoBattle,
  }) {
    return GameData(
      player: player ?? this.player,
      currentMap: currentMap ?? this.currentMap,
      gameState: gameState ?? this.gameState,
      currentMob: currentMob ?? this.currentMob,
      logs: logs ?? this.logs,
      random: random,
      shopCategory: shopCategory ?? this.shopCategory,
      mails: mails ?? this.mails,
      quests: quests ?? this.quests,
      isAutoExplore: isAutoExplore ?? this.isAutoExplore,
      isAutoBattle: isAutoBattle ?? this.isAutoBattle,
    );
  }
}

// Provider 定义
final gameProvider = StateNotifierProvider<GameNotifier, GameData>((ref) {
  return GameNotifier();
});

// 辅助类
class Random {
  final _random = math.Random();

  double nextDouble() => _random.nextDouble();
  int nextInt(int max) => _random.nextInt(max);
}

/// 玩家命中结果 (含暴击信息)
class _PlayerHit {
  final int damage;
  final bool isCrit;
  const _PlayerHit({required this.damage, required this.isCrit});
}

/// 怪物命中结果 (含闪避信息)
class _MobHit {
  final int damage;
  final bool isAvoided;
  const _MobHit({required this.damage, required this.isAvoided});
}

/// 战斗特效事件 (UI 订阅触发飘字/震屏)
enum BattleEffectTarget { mob, player }

class BattleEffect {
  final BattleEffectTarget target;
  final int damage;
  final bool isCrit;
  final bool isAvoided;
  final bool isFatal; // 死亡特效
  final bool isExtraHit; // 追加打击 (海盗/拳手/刺客被动)
  final bool isReduced; // 减伤被动 (战士系)
  final int mpRegenAmount; // MP 回复 (法师系) - >0 时显示为 +N MP
  const BattleEffect({
    required this.target,
    required this.damage,
    this.isCrit = false,
    this.isAvoided = false,
    this.isFatal = false,
    this.isExtraHit = false,
    this.isReduced = false,
    this.mpRegenAmount = 0,
  });
}
