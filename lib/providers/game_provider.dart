import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../game/models/player.dart';
import '../game/models/mob.dart';
import '../game/models/map.dart';
import '../game/models/item.dart' hide Equipment;
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
  
  // 自动战斗相关
  Timer? _autoBattleTimer;
  bool _isAutoExplore = false;
  bool _isAutoBattle = false;

  GameNotifier({SaveRepository? saveRepository}) 
      : _saveRepository = saveRepository ?? HiveSaveRepository(),
        super(GameData.initial()) {
    // 自动尝试读取存档
    _init();
  }

  bool get isInitialized => _isInitialized;
  bool get isAutoExplore => _isAutoExplore;
  bool get isAutoBattle => _isAutoBattle;
  
  /// 清理定时器
  @override
  void dispose() {
    _autoBattleTimer?.cancel();
    super.dispose();
  }

  /// 设置自动探索
  void setAutoExplore(bool value) {
    _isAutoExplore = value;
    if (value) {
      addLog('🤖 自动探索已开启', LogType.success);
      _startAutoMode();
    } else {
      addLog('🛑 自动探索已关闭', LogType.warning);
      if (!_isAutoBattle) {
        _autoBattleTimer?.cancel();
      }
    }
  }
  
  /// 设置自动战斗
  void setAutoBattle(bool value) {
    _isAutoBattle = value;
    if (value) {
      addLog('⚔️ 自动战斗已开启', LogType.success);
      _startAutoMode();
    } else {
      addLog('🛑 自动战斗已关闭', LogType.warning);
      if (!_isAutoExplore) {
        _autoBattleTimer?.cancel();
      }
    }
  }
  
  /// 启动自动模式定时器
  void _startAutoMode() {
    _autoBattleTimer?.cancel();
    
    // 每2秒执行一次自动操作
    _autoBattleTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (state.gameState == GameState.battling && state.currentMob != null) {
        // 战斗中：自动攻击
        if (_isAutoBattle) {
          attack();
        }
      } else if (state.gameState == GameState.exploring) {
        // 探索中：自动探索
        if (_isAutoExplore && !state.currentMap.isTown) {
          explore();
        }
      }
    });
  }

  /// 设置新玩家（用于创建角色）
  void setNewPlayer(Player player) {
    state = state.copyWith(player: player);
    addLog('🎉 欢迎，${player.name}！冒险开始了！', LogType.success);
    addLog('📝 初始属性: 力量${player.stats.str} 敏捷${player.stats.dex} 智力${player.stats.intStat} 运气${player.stats.luk}');
  }

  /// 初始化 - 自动读取存档
  Future<void> _init() async {
    try {
      final hasSave = await _saveRepository.hasSave();
      if (hasSave) {
        final savedData = await _saveRepository.loadGame();
        if (savedData != null) {
          state = savedData;
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

    final player = state.player;
    final mob = state.currentMob!;
    
    // 玩家攻击
    final playerAtk = player.getAtk();
    final mobDef = mob.def;
    var damage = (playerAtk - mobDef).clamp(1, 9999);
    
    // 暴击判定
    final critRate = player.getCritRate();
    final isCrit = state.random.nextDouble() * 100 < critRate;
    if (isCrit) {
      damage = (damage * 1.5).toInt(); // 暴击1.5倍伤害
      addLog('💥 暴击！你对 ${mob.name} 造成 $damage 点伤害！', LogType.reward);
    } else {
      addLog('⚔️ 你对 ${mob.name} 造成 $damage 点伤害！', LogType.battle);
    }
    
    final newMobHp = mob.hp - damage;

    if (newMobHp <= 0) {
      // 怪物死亡
      _winBattle(mob);
      return;
    }

    // 怪物反击
    final mobNew = mob.copyWith(hp: newMobHp);
    
    // 闪避判定
    final avoidRate = player.getAvoidRate();
    final isAvoided = state.random.nextDouble() * 100 < avoidRate;
    
    if (isAvoided) {
      addLog('💨 你闪避了 ${mob.name} 的攻击！', LogType.success);
      state = state.copyWith(currentMob: mobNew);
      return;
    }
    
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
    
    // 装备掉落（5%概率）
    final droppedEquip = EquipmentDatabase.getRandomDrop(player.stats.level);
    if (droppedEquip != null && droppedEquip.id != null) {
      newInventory.add(droppedEquip.id!);
      addLog('✨ 稀有掉落：${droppedEquip.name}！', LogType.reward);
    }

    // 升级检查
    var updatedPlayer = player.copyWith(
      stats: player.stats.copyWith(exp: newExp),
      meso: newMeso,
      inventory: newInventory,
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
    final newAp = player.stats.ap + 5;  // 获得5点自由属性点
    
    addLog('🆙 升级了！到达 Lv.$newLevel！', LogType.success);
    addLog('💫 获得 5 点属性点，点击角色面板分配', LogType.reward);
    
    return player.copyWith(
      stats: player.stats.copyWith(
        level: newLevel,
        exp: 0,
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
    );
    
    addLog('💀 你被击败了...', LogType.error);
    addLog('💨 被传送回射手村，HP 恢复至 1', LogType.warning);
    if (penalty > 0) {
      addLog('💸 损失 $penalty 金币作为惩罚', LogType.warning);
    }
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

    // 扣除金币，装备直接进背包（简化处理，实际应该装备到身上）
    final newPlayer = state.player.copyWith(
      meso: state.player.meso - price,
      inventory: [...state.player.inventory, equipment.id!],
    );

    state = state.copyWith(player: newPlayer);
    addLog('🛡️ 购买了 ${equipment.name}，已放入背包', LogType.success);
    return true;
  }

  // 装备物品
  bool equipItem(String equipmentId) {
    final equipment = EquipmentDatabase.getById(equipmentId);
    if (equipment == null) {
      addLog('❌ 找不到该装备', LogType.error);
      return false;
    }

    // 检查背包中是否有该装备
    final itemIndex = state.player.inventory.indexOf(equipmentId);
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

    // 从背包中移除装备
    final newInventory = List<String>.from(state.player.inventory);
    newInventory.removeAt(itemIndex);

    // 获取当前已装备的同类装备（如果有）
    final currentEquip = state.player.equipment[equipment.slot];
    
    // 卸下当前装备（如果有）并放入背包
    if (currentEquip != null) {
      final oldEquipId = currentEquip.id ?? currentEquip.name;
      newInventory.add(oldEquipId);
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
    final equipId = currentEquip.id ?? currentEquip.name;
    final newInventory = List<String>.from(state.player.inventory);
    newInventory.add(equipId);

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
  bool sellItem(String itemId, {int quantity = 1}) {
    // 先尝试从普通物品查找
    final item = ShopDatabase.getById(itemId);
    // 再尝试从装备查找
    final equipment = EquipmentDatabase.getById(itemId);
    
    final itemName = item?.name ?? equipment?.name ?? '物品';
    final itemPrice = item?.price ?? equipment?.price ?? 0;

    // 检查背包中是否有足够数量
    final inventoryCount = state.player.inventory.where((id) => id == itemId).length;
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
      if (id == itemId && removed < quantity) {
        removed++;
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

  // ========== 存档功能 ==========
  
  /// 保存游戏
  Future<bool> saveGame() async {
    try {
      await _saveRepository.saveGame(state);
      addLog('💾 游戏已保存', LogType.success);
      return true;
    } catch (e) {
      addLog('❌ 保存失败: $e', LogType.error);
      return false;
    }
  }
  
  /// 读取存档
  Future<bool> loadGame() async {
    try {
      final savedData = await _saveRepository.loadGame();
      if (savedData != null) {
        state = savedData;
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
  
  /// 导出存档为 JSON
  Future<String?> exportToJson() async {
    try {
      return await _saveRepository.exportToJson();
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

  GameData({
    required this.player,
    required this.currentMap,
    required this.gameState,
    this.currentMob,
    required this.logs,
    required this.random,
    this.shopCategory = ShopCategory.all,  // 默认全部
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
    ShopCategory? shopCategory,
  }) {
    return GameData(
      player: player ?? this.player,
      currentMap: currentMap ?? this.currentMap,
      gameState: gameState ?? this.gameState,
      currentMob: currentMob ?? this.currentMob,
      logs: logs ?? this.logs,
      random: random,
      shopCategory: shopCategory ?? this.shopCategory,
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
