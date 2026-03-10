import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../game/models/item.dart';
import '../game/models/map.dart';
import '../game/models/mob.dart';
import '../game/models/player.dart';
import '../game/models/mail.dart';
import '../game/models/potential.dart';
import '../game/models/quest.dart';
import '../providers/game_provider.dart';
import 'save_repository.dart';

/// Hive 本地存档实现
class HiveSaveRepository implements SaveRepository {
  static const String _boxName = 'game_saves_v6';  // 升级版本号，避免旧存档冲突
  static const String _saveKey = 'current_save_v6';
  static const String _equipmentKey = 'equipment_instances_v6';

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
      Hive.registerAdapter(StatsAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(JobAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(LogEntryAdapter());
    }
    if (!Hive.isAdapterRegistered(5)) {
      Hive.registerAdapter(LogTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(6)) {
      Hive.registerAdapter(GameMailAdapter());
    }
    if (!Hive.isAdapterRegistered(7)) {
      Hive.registerAdapter(MailAttachmentAdapter());
    }
    if (!Hive.isAdapterRegistered(8)) {
      Hive.registerAdapter(MailAttachmentTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(9)) {
      Hive.registerAdapter(EquipmentSlotAdapter());
    }
    if (!Hive.isAdapterRegistered(10)) {
      Hive.registerAdapter(PotentialGradeAdapter());
    }
    if (!Hive.isAdapterRegistered(11)) {
      Hive.registerAdapter(PotentialTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(12)) {
      Hive.registerAdapter(QuestTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(13)) {
      Hive.registerAdapter(QuestStatusAdapter());
    }
    if (!Hive.isAdapterRegistered(14)) {
      Hive.registerAdapter(GameQuestAdapter());
    }
    
    _box = await Hive.openBox(_boxName);
  }

  @override
  Future<void> saveGame(GameData data, {Map<String, Equipment>? equipmentInstances}) async {
    if (_box == null) await init();

    final saveData = _GameSaveData(
      player: data.player,
      currentMapId: data.currentMap.id,
      logs: data.logs,
      mails: data.mails,
      quests: data.quests,
      timestamp: DateTime.now(),
    );

    await _box!.put(_saveKey, saveData);

    // 保存装备实例
    if (equipmentInstances != null) {
      final equipmentJson = _equipmentInstancesToJson(equipmentInstances);
      await _box!.put(_equipmentKey, equipmentJson);
    }
  }

  @override
  Future<GameData?> loadGame() async {
    if (_box == null) await init();

    try {
      final saveData = _box!.get(_saveKey) as _GameSaveData?;
      if (saveData == null) return null;

      return GameData(
        player: saveData.player,
        currentMap: GameMaps.getMap(saveData.currentMapId),
        gameState: GameState.exploring,
        logs: saveData.logs,
        random: Random(),
        shopCategory: ShopCategory.all,
        mails: saveData.mails,
        quests: saveData.quests,
      );
    } catch (e) {
      print('存档格式不兼容，重置存档: $e');
      await _box!.delete(_saveKey);
      return null;
    }
  }

  @override
  Future<Map<String, Equipment>?> loadEquipmentInstances() async {
    if (_box == null) await init();

    try {
      final equipmentJson = _box!.get(_equipmentKey) as String?;
      if (equipmentJson == null) return null;

      return _equipmentInstancesFromJson(equipmentJson);
    } catch (e) {
      print('装备实例加载失败: $e');
      return null;
    }
  }

  @override
  Future<void> deleteSave() async {
    if (_box == null) await init();
    await _box!.delete(_saveKey);
    await _box!.delete(_equipmentKey);
  }

  @override
  Future<bool> hasSave() async {
    if (_box == null) await init();
    return _box!.containsKey(_saveKey);
  }

  @override
  Future<String> exportToJson(Map<String, Equipment> equipmentInstances) async {
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
      'mails': data.mails.map((mail) => {
        'id': mail.id,
        'title': mail.title,
        'content': mail.content,
        'sender': mail.sender,
        'sentAt': mail.sentAt.toIso8601String(),
        'isRead': mail.isRead,
        'isClaimed': mail.isClaimed,
        'attachments': mail.attachments.map((a) => {
          'type': a.type.index,
          'itemId': a.itemId,
          'equipmentId': a.equipmentId,
          'instanceId': a.instanceId,
          'count': a.count,
          'meso': a.meso,
        }).toList(),
      }).toList(),
      'quests': data.quests.map((quest) => _questToJson(quest)).toList(),
      'equipmentInstances': _equipmentInstancesToJson(equipmentInstances),
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
    final mails = data['mails'] != null
        ? (data['mails'] as List).map((m) => _mailFromJson(m as Map<String, dynamic>)).toList()
        : <GameMail>[];
    final quests = data['quests'] != null
        ? (data['quests'] as List).map((q) => _questFromJson(q as Map<String, dynamic>)).toList()
        : QuestDatabase.getAllQuests();

    final saveData = _GameSaveData(
      player: player,
      currentMapId: currentMapId,
      logs: logs,
      mails: mails,
      quests: quests,
      timestamp: DateTime.now(),
    );

    if (_box == null) await init();
    await _box!.put(_saveKey, saveData);

    // 导入装备实例
    if (data['equipmentInstances'] != null) {
      await _box!.put(_equipmentKey, data['equipmentInstances'] as String);
    }
  }

  // ========== 装备实例序列化 ==========

  String _equipmentInstancesToJson(Map<String, Equipment> instances) {
    final Map<String, dynamic> jsonMap = {};
    for (final entry in instances.entries) {
      jsonMap[entry.key] = _equipmentToJson(entry.value);
    }
    return jsonEncode(jsonMap);
  }

  Map<String, Equipment> _equipmentInstancesFromJson(String json) {
    final Map<String, dynamic> jsonMap = jsonDecode(json) as Map<String, dynamic>;
    final Map<String, Equipment> instances = {};

    for (final entry in jsonMap.entries) {
      final equip = _equipmentFromJson(entry.value as Map<String, dynamic>);
      if (equip != null) {
        instances[entry.key] = equip;
      }
    }
    return instances;
  }

  Map<String, dynamic> _equipmentToJson(Equipment equipment) {
    return {
      'name': equipment.name,
      'id': equipment.id,
      'instanceId': equipment.instanceId,
      'emoji': equipment.emoji,
      'description': equipment.description,
      'slot': equipment.slot.index,
      'atk': equipment.atk,
      'def': equipment.def,
      'str': equipment.str,
      'dex': equipment.dex,
      'intBonus': equipment.intBonus,
      'luk': equipment.luk,
      'price': equipment.price,
      'levelReq': equipment.levelReq,
      'crit': equipment.crit,
      'avoid': equipment.avoid,
      'potential': equipment.potential != null ? _potentialToJson(equipment.potential!) : null,
    };
  }

  Equipment? _equipmentFromJson(Map<String, dynamic> json) {
    try {
      return Equipment(
        name: json['name'] as String,
        id: json['id'] as String?,
        instanceId: json['instanceId'] as String,
        emoji: json['emoji'] as String?,
        description: json['description'] as String?,
        slot: EquipmentSlot.values[json['slot'] as int],
        atk: json['atk'] as int? ?? 0,
        def: json['def'] as int? ?? 0,
        str: json['str'] as int? ?? 0,
        dex: json['dex'] as int? ?? 0,
        intBonus: json['intBonus'] as int? ?? 0,
        luk: json['luk'] as int? ?? 0,
        price: json['price'] as int?,
        levelReq: json['levelReq'] as int?,
        crit: json['crit'] as int?,
        avoid: json['avoid'] as int?,
        potential: json['potential'] != null
            ? _potentialFromJson(json['potential'] as Map<String, dynamic>)
            : null,
      );
    } catch (e) {
      print('装备解析失败: $e');
      return null;
    }
  }

  Map<String, dynamic> _potentialToJson(EquipmentPotential potential) {
    return {
      'grade': potential.grade.index,
      'stats': potential.stats.map((s) => {
        'type': s.type.index,
        'value': s.value,
        'grade': s.grade,
      }).toList(),
    };
  }

  EquipmentPotential _potentialFromJson(Map<String, dynamic> json) {
    return EquipmentPotential(
      grade: PotentialGrade.values[json['grade'] as int],
      stats: (json['stats'] as List).map((s) => PotentialStat(
        type: PotentialType.values[s['type'] as int],
        value: s['value'] as int,
        grade: s['grade'] as String,
      )).toList(),
    );
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
      job: Job.values[json['job'] as int],
      stats: Stats(
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

  // 邮件 JSON 序列化辅助方法
  GameMail _mailFromJson(Map<String, dynamic> json) {
    return GameMail(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      sender: json['sender'] as String,
      sentAt: DateTime.parse(json['sentAt'] as String),
      isRead: json['isRead'] as bool? ?? false,
      isClaimed: json['isClaimed'] as bool? ?? false,
      attachments: (json['attachments'] as List? ?? [])
          .map((a) => _attachmentFromJson(a as Map<String, dynamic>))
          .toList(),
    );
  }

  MailAttachment _attachmentFromJson(Map<String, dynamic> json) {
    return MailAttachment(
      type: MailAttachmentType.values[json['type'] as int],
      itemId: json['itemId'] as String?,
      equipmentId: json['equipmentId'] as String?,
      instanceId: json['instanceId'] as String?,
      count: json['count'] as int?,
      meso: json['meso'] as int?,
    );
  }

  // 任务 JSON 序列化辅助方法
  Map<String, dynamic> _questToJson(GameQuest quest) {
    return {
      'id': quest.id,
      'title': quest.title,
      'description': quest.description,
      'type': quest.type.index,
      'minLevel': quest.minLevel,
      'requiredJob': quest.requiredJob?.index,
      'targetJob': quest.targetJob?.index,
      'targetMapId': quest.targetMapId,
      'targetMobs': quest.targetMobs,
      'targetCount': quest.targetCount,
      'currentCount': quest.currentCount,
      'status': quest.status.index,
      'rewards': quest.rewards,
    };
  }

  GameQuest _questFromJson(Map<String, dynamic> json) {
    return GameQuest(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      type: QuestType.values[json['type'] as int],
      minLevel: json['minLevel'] as int,
      requiredJob: json['requiredJob'] != null ? Job.values[json['requiredJob'] as int] : null,
      targetJob: json['targetJob'] != null ? Job.values[json['targetJob'] as int] : null,
      targetMapId: json['targetMapId'] as String?,
      targetMobs: (json['targetMobs'] as List).cast<String>(),
      targetCount: json['targetCount'] as int,
      currentCount: json['currentCount'] as int,
      status: QuestStatus.values[json['status'] as int],
      rewards: (json['rewards'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, v as int),
      ),
    );
  }
}

/// 存档数据类（用于 Hive 存储）
class _GameSaveData {
  final Player player;
  final String currentMapId;
  final List<LogEntry> logs;
  final List<GameMail> mails;
  final List<GameQuest> quests;
  final DateTime timestamp;

  _GameSaveData({
    required this.player,
    required this.currentMapId,
    required this.logs,
    required this.mails,
    required this.quests,
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
      mails: reader.readList().cast<GameMail>(),
      quests: reader.readList().cast<GameQuest>(),
      timestamp: DateTime.parse(reader.readString()),
    );
  }

  @override
  void write(BinaryWriter writer, _GameSaveData obj) {
    writer.write(obj.player);
    writer.writeString(obj.currentMapId);
    writer.writeList(obj.logs);
    writer.writeList(obj.mails);
    writer.writeList(obj.quests);
    writer.writeString(obj.timestamp.toIso8601String());
  }
}

class PlayerAdapter extends TypeAdapter<Player> {
  @override
  final int typeId = 1;

  @override
  Player read(BinaryReader reader) {
    final name = reader.readString();
    final job = Job.values[reader.readInt()];
    final stats = reader.read() as Stats;
    final meso = reader.readInt();
    final inventory = reader.readList().cast<String>();
    final currentMap = reader.readString();

    // 读取装备（JSON格式）
    final equipmentJson = reader.readString();
    final equipment = _equipmentMapFromJson(equipmentJson);

    return Player(
      name: name,
      job: job,
      stats: stats,
      meso: meso,
      inventory: inventory,
      currentMap: currentMap,
      equipment: equipment,
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
    // 保存装备为JSON
    writer.writeString(_equipmentMapToJson(obj.equipment));
  }

  // 装备Map转JSON
  String _equipmentMapToJson(Map<EquipmentSlot, Equipment?> equipment) {
    final Map<String, dynamic> jsonMap = {};
    for (final entry in equipment.entries) {
      if (entry.value != null) {
        jsonMap[entry.key.index.toString()] = _equipmentToJson(entry.value!);
      }
    }
    return jsonEncode(jsonMap);
  }

  // JSON转装备Map
  Map<EquipmentSlot, Equipment?> _equipmentMapFromJson(String json) {
    if (json.isEmpty) return {};
    try {
      final Map<String, dynamic> jsonMap = jsonDecode(json) as Map<String, dynamic>;
      final Map<EquipmentSlot, Equipment?> equipment = {};
      for (final entry in jsonMap.entries) {
        final slotIndex = int.parse(entry.key);
        final slot = EquipmentSlot.values[slotIndex];
        equipment[slot] = _equipmentFromJson(entry.value as Map<String, dynamic>);
      }
      return equipment;
    } catch (e) {
      print('装备解析失败: $e');
      return {};
    }
  }

  Map<String, dynamic> _equipmentToJson(Equipment equipment) {
    return {
      'name': equipment.name,
      'id': equipment.id,
      'instanceId': equipment.instanceId,
      'emoji': equipment.emoji,
      'description': equipment.description,
      'slot': equipment.slot.index,
      'atk': equipment.atk,
      'def': equipment.def,
      'str': equipment.str,
      'dex': equipment.dex,
      'intBonus': equipment.intBonus,
      'luk': equipment.luk,
      'price': equipment.price,
      'levelReq': equipment.levelReq,
      'crit': equipment.crit,
      'avoid': equipment.avoid,
      'potential': equipment.potential != null ? _potentialToJson(equipment.potential!) : null,
    };
  }

  Equipment? _equipmentFromJson(Map<String, dynamic> json) {
    try {
      return Equipment(
        name: json['name'] as String,
        id: json['id'] as String?,
        instanceId: json['instanceId'] as String,
        emoji: json['emoji'] as String?,
        description: json['description'] as String?,
        slot: EquipmentSlot.values[json['slot'] as int],
        atk: json['atk'] as int? ?? 0,
        def: json['def'] as int? ?? 0,
        str: json['str'] as int? ?? 0,
        dex: json['dex'] as int? ?? 0,
        intBonus: json['intBonus'] as int? ?? 0,
        luk: json['luk'] as int? ?? 0,
        price: json['price'] as int?,
        levelReq: json['levelReq'] as int?,
        crit: json['crit'] as int?,
        avoid: json['avoid'] as int?,
        potential: json['potential'] != null
            ? _potentialFromJson(json['potential'] as Map<String, dynamic>)
            : null,
      );
    } catch (e) {
      print('装备解析失败: $e');
      return null;
    }
  }

  Map<String, dynamic> _potentialToJson(EquipmentPotential potential) {
    return {
      'grade': potential.grade.index,
      'stats': potential.stats.map((s) => {
        'type': s.type.index,
        'value': s.value,
        'grade': s.grade,
      }).toList(),
    };
  }

  EquipmentPotential _potentialFromJson(Map<String, dynamic> json) {
    return EquipmentPotential(
      grade: PotentialGrade.values[json['grade'] as int],
      stats: (json['stats'] as List).map((s) => PotentialStat(
        type: PotentialType.values[s['type'] as int],
        value: s['value'] as int,
        grade: s['grade'] as String,
      )).toList(),
    );
  }
}

class StatsAdapter extends TypeAdapter<Stats> {
  @override
  final int typeId = 2;

  @override
  Stats read(BinaryReader reader) {
    return Stats(
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
  void write(BinaryWriter writer, Stats obj) {
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

class JobAdapter extends TypeAdapter<Job> {
  @override
  final int typeId = 3;

  @override
  Job read(BinaryReader reader) {
    return Job.values[reader.readInt()];
  }

  @override
  void write(BinaryWriter writer, Job obj) {
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

// ========== 邮件系统适配器 ==========

class GameMailAdapter extends TypeAdapter<GameMail> {
  @override
  final int typeId = 6;

  @override
  GameMail read(BinaryReader reader) {
    return GameMail(
      id: reader.readString(),
      title: reader.readString(),
      content: reader.readString(),
      sender: reader.readString(),
      sentAt: DateTime.parse(reader.readString()),
      isRead: reader.readBool(),
      isClaimed: reader.readBool(),
      attachments: reader.readList().cast<MailAttachment>(),
    );
  }

  @override
  void write(BinaryWriter writer, GameMail obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.title);
    writer.writeString(obj.content);
    writer.writeString(obj.sender);
    writer.writeString(obj.sentAt.toIso8601String());
    writer.writeBool(obj.isRead);
    writer.writeBool(obj.isClaimed);
    writer.writeList(obj.attachments);
  }
}

class MailAttachmentAdapter extends TypeAdapter<MailAttachment> {
  @override
  final int typeId = 7;

  @override
  MailAttachment read(BinaryReader reader) {
    return MailAttachment(
      type: MailAttachmentType.values[reader.readInt()],
      itemId: reader.readString(),
      equipmentId: reader.readString(),
      instanceId: reader.readString(),
      count: reader.readInt(),
      meso: reader.readInt(),
    );
  }

  @override
  void write(BinaryWriter writer, MailAttachment obj) {
    writer.writeInt(obj.type.index);
    writer.writeString(obj.itemId ?? '');
    writer.writeString(obj.equipmentId ?? '');
    writer.writeString(obj.instanceId ?? '');
    writer.writeInt(obj.count ?? 0);
    writer.writeInt(obj.meso ?? 0);
  }
}

class MailAttachmentTypeAdapter extends TypeAdapter<MailAttachmentType> {
  @override
  final int typeId = 8;

  @override
  MailAttachmentType read(BinaryReader reader) {
    return MailAttachmentType.values[reader.readInt()];
  }

  @override
  void write(BinaryWriter writer, MailAttachmentType obj) {
    writer.writeInt(obj.index);
  }
}

// ========== 装备系统适配器 ==========

class EquipmentSlotAdapter extends TypeAdapter<EquipmentSlot> {
  @override
  final int typeId = 9;

  @override
  EquipmentSlot read(BinaryReader reader) {
    return EquipmentSlot.values[reader.readInt()];
  }

  @override
  void write(BinaryWriter writer, EquipmentSlot obj) {
    writer.writeInt(obj.index);
  }
}

class PotentialGradeAdapter extends TypeAdapter<PotentialGrade> {
  @override
  final int typeId = 10;

  @override
  PotentialGrade read(BinaryReader reader) {
    return PotentialGrade.values[reader.readInt()];
  }

  @override
  void write(BinaryWriter writer, PotentialGrade obj) {
    writer.writeInt(obj.index);
  }
}

class PotentialTypeAdapter extends TypeAdapter<PotentialType> {
  @override
  final int typeId = 11;

  @override
  PotentialType read(BinaryReader reader) {
    return PotentialType.values[reader.readInt()];
  }

  @override
  void write(BinaryWriter writer, PotentialType obj) {
    writer.writeInt(obj.index);
  }
}

// ========== 任务系统适配器 ==========

class QuestTypeAdapter extends TypeAdapter<QuestType> {
  @override
  final int typeId = 12;

  @override
  QuestType read(BinaryReader reader) {
    return QuestType.values[reader.readInt()];
  }

  @override
  void write(BinaryWriter writer, QuestType obj) {
    writer.writeInt(obj.index);
  }
}

class QuestStatusAdapter extends TypeAdapter<QuestStatus> {
  @override
  final int typeId = 13;

  @override
  QuestStatus read(BinaryReader reader) {
    return QuestStatus.values[reader.readInt()];
  }

  @override
  void write(BinaryWriter writer, QuestStatus obj) {
    writer.writeInt(obj.index);
  }
}

class GameQuestAdapter extends TypeAdapter<GameQuest> {
  @override
  final int typeId = 14;

  @override
  GameQuest read(BinaryReader reader) {
    return GameQuest(
      id: reader.readString(),
      title: reader.readString(),
      description: reader.readString(),
      type: QuestType.values[reader.readInt()],
      minLevel: reader.readInt(),
      requiredJob: reader.readBool() ? Job.values[reader.readInt()] : null,
      targetJob: reader.readBool() ? Job.values[reader.readInt()] : null,
      targetMapId: reader.readString(),
      targetMobs: reader.readList().cast<String>(),
      targetCount: reader.readInt(),
      currentCount: reader.readInt(),
      status: QuestStatus.values[reader.readInt()],
      rewards: Map<String, int>.fromEntries(
        List.generate(reader.readInt(), (_) {
          final key = reader.readString();
          final value = reader.readInt();
          return MapEntry(key, value);
        }),
      ),
    );
  }

  @override
  void write(BinaryWriter writer, GameQuest obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.title);
    writer.writeString(obj.description);
    writer.writeInt(obj.type.index);
    writer.writeInt(obj.minLevel);
    writer.writeBool(obj.requiredJob != null);
    if (obj.requiredJob != null) {
      writer.writeInt(obj.requiredJob!.index);
    }
    writer.writeBool(obj.targetJob != null);
    if (obj.targetJob != null) {
      writer.writeInt(obj.targetJob!.index);
    }
    writer.writeString(obj.targetMapId ?? '');
    writer.writeList(obj.targetMobs);
    writer.writeInt(obj.targetCount);
    writer.writeInt(obj.currentCount);
    writer.writeInt(obj.status.index);
    writer.writeInt(obj.rewards.length);
    obj.rewards.forEach((key, value) {
      writer.writeString(key);
      writer.writeInt(value);
    });
  }
}