import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../game/models/item.dart';
import '../game/models/map.dart';
import '../game/models/mob.dart';
import '../game/models/player.dart';
import '../providers/game_provider.dart';
import 'save_repository.dart';

/// Hive 本地存档实现
class HiveSaveRepository implements SaveRepository {
  static const String _boxName = 'game_saves';
  static const String _saveKey = 'current_save';
  
  Box? _box;
  
  /// 初始化 Hive
  Future<void> init() async {
    await Hive.initFlutter();
    
    // 注册适配器
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(GameDataAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(PlayerAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(PlayerStatsAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(JobTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(LogEntryAdapter());
    }
    if (!Hive.isAdapterRegistered(5)) {
      Hive.registerAdapter(LogTypeAdapter());
    }
    
    _box = await Hive.openBox(_boxName);
  }
  
  @override
  Future<void> saveGame(GameData data) async {
    if (_box == null) await init();
    
    final saveData = _GameSaveData(
      player: data.player,
      currentMapId: data.currentMap.id,
      logs: data.logs,
      timestamp: DateTime.now(),
    );
    
    await _box!.put(_saveKey, saveData);
  }
  
  @override
  Future<GameData?> loadGame() async {
    if (_box == null) await init();
    
    final saveData = _box!.get(_saveKey) as _GameSaveData?;
    if (saveData == null) return null;
    
    return GameData(
      player: saveData.player,
      currentMap: GameMaps.getMap(saveData.currentMapId),
      gameState: GameState.exploring,
      logs: saveData.logs,
      random: Random(),
      shopCategory: ShopCategory.all,
    );
  }
  
  @override
  Future<void> deleteSave() async {
    if (_box == null) await init();
    await _box!.delete(_saveKey);
  }
  
  @override
  Future<bool> hasSave() async {
    if (_box == null) await init();
    return _box!.containsKey(_saveKey);
  }
  
  @override
  Future<String> exportToJson() async {
    final data = await loadGame();
    if (data == null) throw Exception('没有存档可导出');
    
    final exportData = {
      'player': _playerToJson(data.player),
      'currentMapId': data.currentMap.id,
      'logs': data.logs.map((log) => {
        'message': log.message,
        'type': log.type.index,
        'timestamp': log.timestamp.toIso8601String(),
      }).toList(),
      'exportedAt': DateTime.now().toIso8601String(),
    };
    
    return jsonEncode(exportData);
  }
  
  @override
  Future<void> importFromJson(String json) async {
    final data = jsonDecode(json) as Map<String, dynamic>;
    
    final player = _playerFromJson(data['player'] as Map<String, dynamic>);
    final currentMapId = data['currentMapId'] as String;
    final logs = (data['logs'] as List).map((log) => LogEntry(
      message: log['message'] as String,
      type: LogType.values[log['type'] as int],
    )).toList();
    
    final saveData = _GameSaveData(
      player: player,
      currentMapId: currentMapId,
      logs: logs,
      timestamp: DateTime.now(),
    );
    
    if (_box == null) await init();
    await _box!.put(_saveKey, saveData);
  }
  
  // JSON 序列化辅助方法
  Map<String, dynamic> _playerToJson(Player player) {
    return {
      'name': player.name,
      'job': player.job.index,
      'stats': {
        'level': player.stats.level,
        'hp': player.stats.hp,
        'maxHp': player.stats.maxHp,
        'mp': player.stats.mp,
        'maxMp': player.stats.maxMp,
        'exp': player.stats.exp,
        'maxExp': player.stats.maxExp,
        'str': player.stats.str,
        'dex': player.stats.dex,
        'int': player.stats.intStat,
        'luk': player.stats.luk,
      },
      'meso': player.meso,
      'inventory': player.inventory,
      'currentMap': player.currentMap,
    };
  }
  
  Player _playerFromJson(Map<String, dynamic> json) {
    final statsJson = json['stats'] as Map<String, dynamic>;
    return Player(
      name: json['name'] as String,
      job: JobType.values[json['job'] as int],
      stats: PlayerStats(
        level: statsJson['level'] as int,
        hp: statsJson['hp'] as int,
        maxHp: statsJson['maxHp'] as int,
        mp: statsJson['mp'] as int,
        maxMp: statsJson['maxMp'] as int,
        exp: statsJson['exp'] as int,
        maxExp: statsJson['maxExp'] as int,
        str: statsJson['str'] as int,
        dex: statsJson['dex'] as int,
        intStat: statsJson['int'] as int,
        luk: statsJson['luk'] as int,
      ),
      meso: json['meso'] as int,
      inventory: List<String>.from(json['inventory'] as List),
      currentMap: json['currentMap'] as String,
    );
  }
}

/// 存档数据类（用于 Hive 存储）
class _GameSaveData {
  final Player player;
  final String currentMapId;
  final List<LogEntry> logs;
  final DateTime timestamp;

  _GameSaveData({
    required this.player,
    required this.currentMapId,
    required this.logs,
    required this.timestamp,
  });
}

/// Hive 适配器
class GameDataAdapter extends TypeAdapter<_GameSaveData> {
  @override
  final int typeId = 0;

  @override
  _GameSaveData read(BinaryReader reader) {
    return _GameSaveData(
      player: reader.read() as Player,
      currentMapId: reader.readString(),
      logs: reader.readList().cast<LogEntry>(),
      timestamp: DateTime.parse(reader.readString()),
    );
  }

  @override
  void write(BinaryWriter writer, _GameSaveData obj) {
    writer.write(obj.player);
    writer.writeString(obj.currentMapId);
    writer.writeList(obj.logs);
    writer.writeString(obj.timestamp.toIso8601String());
  }
}

class PlayerAdapter extends TypeAdapter<Player> {
  @override
  final int typeId = 1;

  @override
  Player read(BinaryReader reader) {
    return Player(
      name: reader.readString(),
      job: JobType.values[reader.readInt()],
      stats: reader.read() as PlayerStats,
      meso: reader.readInt(),
      inventory: reader.readList().cast<String>(),
      currentMap: reader.readString(),
    );
  }

  @override
  void write(BinaryWriter writer, Player obj) {
    writer.writeString(obj.name);
    writer.writeInt(obj.job.index);
    writer.write(obj.stats);
    writer.writeInt(obj.meso);
    writer.writeList(obj.inventory);
    writer.writeString(obj.currentMap);
  }
}

class PlayerStatsAdapter extends TypeAdapter<PlayerStats> {
  @override
  final int typeId = 2;

  @override
  PlayerStats read(BinaryReader reader) {
    return PlayerStats(
      level: reader.readInt(),
      hp: reader.readInt(),
      maxHp: reader.readInt(),
      mp: reader.readInt(),
      maxMp: reader.readInt(),
      exp: reader.readInt(),
      maxExp: reader.readInt(),
      str: reader.readInt(),
      dex: reader.readInt(),
      intStat: reader.readInt(),
      luk: reader.readInt(),
    );
  }

  @override
  void write(BinaryWriter writer, PlayerStats obj) {
    writer.writeInt(obj.level);
    writer.writeInt(obj.hp);
    writer.writeInt(obj.maxHp);
    writer.writeInt(obj.mp);
    writer.writeInt(obj.maxMp);
    writer.writeInt(obj.exp);
    writer.writeInt(obj.maxExp);
    writer.writeInt(obj.str);
    writer.writeInt(obj.dex);
    writer.writeInt(obj.intStat);
    writer.writeInt(obj.luk);
  }
}

class JobTypeAdapter extends TypeAdapter<JobType> {
  @override
  final int typeId = 3;

  @override
  JobType read(BinaryReader reader) {
    return JobType.values[reader.readInt()];
  }

  @override
  void write(BinaryWriter writer, JobType obj) {
    writer.writeInt(obj.index);
  }
}

class LogEntryAdapter extends TypeAdapter<LogEntry> {
  @override
  final int typeId = 4;

  @override
  LogEntry read(BinaryReader reader) {
    return LogEntry(
      message: reader.readString(),
      type: LogType.values[reader.readInt()],
    );
  }

  @override
  void write(BinaryWriter writer, LogEntry obj) {
    writer.writeString(obj.message);
    writer.writeInt(obj.type.index);
  }
}

class LogTypeAdapter extends TypeAdapter<LogType> {
  @override
  final int typeId = 5;

  @override
  LogType read(BinaryReader reader) {
    return LogType.values[reader.readInt()];
  }

  @override
  void write(BinaryWriter writer, LogType obj) {
    writer.writeInt(obj.index);
  }
}
