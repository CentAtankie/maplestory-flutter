import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../game/models/player.dart';
import '../game/models/mob.dart';
import '../game/models/map.dart';

// 游戏状态枚举
enum GameState {
  exploring,  // 探索中
  battling,   // 战斗中
  menu,       // 菜单
  gameOver,   // 游戏结束
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
  GameNotifier() : super(GameData.initial());

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
    
    // 检查是否遇到怪物
    _checkRandomEncounter();
  }

  // 检查随机遭遇
  void _checkRandomEncounter() {
    if (state.currentMap.mobs.isEmpty) return;
    
    final chance = state.currentMap.encounterChance;
    if (state.random.nextDouble() < chance) {
      final mobType = state.currentMap.mobs[state.random.nextInt(state.currentMap.mobs.length)];
      startBattle(mobType);
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

    final player = state.player;
    final mob = state.currentMob!;
    
    // 玩家攻击
    final playerAtk = player.getAtk();
    final mobDef = mob.def;
    final damage = (playerAtk - mobDef).clamp(1, 9999);
    
    final newMobHp = mob.hp - damage;
    addLog('⚔️ 你对 ${mob.name} 造成 $damage 点伤害！', LogType.battle);

    if (newMobHp <= 0) {
      // 怪物死亡
      _winBattle(mob);
      return;
    }

    // 怪物反击
    final mobNew = mob.copyWith(hp: newMobHp);
    final mobDamage = (mob.atk - player.getDef()).clamp(1, 9999);
    final newPlayerHp = player.stats.hp - mobDamage;
    
    addLog('💥 ${mob.name} 对你造成 $mobDamage 点伤害！', LogType.warning);

    if (newPlayerHp <= 0) {
      _gameOver();
      return;
    }

    state = state.copyWith(
      currentMob: mobNew,
      player: player.copyWith(
        stats: player.stats.copyWith(hp: newPlayerHp),
      ),
    );
  }

  // 使用技能
  void useSkill() {
    if (state.gameState != GameState.battling || state.currentMob == null) return;
    
    final player = state.player;
    if (player.stats.mp < 5) {
      addLog('❌ MP 不足！', LogType.error);
      return;
    }

    final mob = state.currentMob!;
    final damage = (player.getAtk() * 2 - mob.def).clamp(1, 9999);
    final newMobHp = mob.hp - damage;
    
    addLog('✨ 技能攻击！对 ${mob.name} 造成 $damage 点伤害！', LogType.battle);

    if (newMobHp <= 0) {
      _winBattle(mob);
      return;
    }

    state = state.copyWith(
      currentMob: mob.copyWith(hp: newMobHp),
      player: player.copyWith(
        stats: player.stats.copyWith(
          mp: player.stats.mp - 5,
        ),
      ),
    );
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

    // 处理掉落
    for (final drop in mob.drops) {
      if (state.random.nextDouble() < drop.chance) {
        addLog('📦 获得掉落：${drop.name}！', LogType.reward);
      }
    }

    // 升级检查
    var updatedPlayer = player.copyWith(
      stats: player.stats.copyWith(exp: newExp),
      meso: newMeso,
    );

    if (newExp >= player.stats.maxExp) {
      updatedPlayer = _levelUp(updatedPlayer);
    }

    state = state.copyWith(
      gameState: GameState.exploring,
      currentMob: null,
      player: updatedPlayer,
    );
  }

  // 升级
  Player _levelUp(Player player) {
    final newLevel = player.stats.level + 1;
    final newMaxExp = (player.stats.maxExp * 1.5).toInt();
    final newMaxHp = player.stats.maxHp + 10;
    final newMaxMp = player.stats.maxMp + 5;
    
    addLog('🆙 升级了！到达 Lv.$newLevel！', LogType.success);
    
    return player.copyWith(
      stats: player.stats.copyWith(
        level: newLevel,
        exp: 0,
        maxExp: newMaxExp,
        maxHp: newMaxHp,
        maxMp: newMaxMp,
        hp: newMaxHp,
        mp: newMaxMp,
        str: player.stats.str + 2,
        dex: player.stats.dex + 2,
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

  // 游戏结束
  void _gameOver() {
    state = state.copyWith(gameState: GameState.gameOver);
    addLog('💀 你被击败了...游戏结束', LogType.error);
  }

  // 重新开始
  void restart() {
    state = GameData.initial();
    addLog('🎮 新的开始！欢迎来到冒险岛世界！');
  }

  // 添加日志
  void addLog(String message, [LogType type = LogType.normal]) {
    final newLogs = [...state.logs, LogEntry(message: message, type: type)];
    if (newLogs.length > 100) {
      newLogs.removeAt(0);
    }
    state = state.copyWith(logs: newLogs);
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

  GameData({
    required this.player,
    required this.currentMap,
    required this.gameState,
    this.currentMob,
    required this.logs,
    required this.random,
  });

  factory GameData.initial() {
    return GameData(
      player: Player.create('冒险家'),
      currentMap: GameMaps.getMap('henesys'),
      gameState: GameState.exploring,
      currentMob: null,
      logs: [LogEntry(message: '🎮 欢迎来到冒险岛世界！')],
      random: Random(),
    );
  }

  GameData copyWith({
    Player? player,
    GameMap? currentMap,
    GameState? gameState,
    Mob? currentMob,
    List<LogEntry>? logs,
  }) {
    return GameData(
      player: player ?? this.player,
      currentMap: currentMap ?? this.currentMap,
      gameState: gameState ?? this.gameState,
      currentMob: currentMob ?? this.currentMob,
      logs: logs ?? this.logs,
      random: random,
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
