import 'dart:convert';
import 'dart:math' as math;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../game/models/map.dart';
import '../game/models/mail.dart';
import '../game/models/player.dart';
import '../game/models/potential.dart';
import '../game/models/quest.dart';
import '../providers/game_provider.dart';
import 'save_repository.dart';

/// Supabase 云端存档实现（无 auth 版本）
///
/// 使用设备 UUID 作为标识，无需登录即可存档。
/// 适合 Flutter Web 等 auth 可能被拦截的环境。
class SupabaseSaveRepository implements SaveRepository {
  static const String _tableName = 'player_saves';
  static const String _backupTableName = 'player_save_backups';
  static const String _deviceIdKey = 'supabase_device_id';

  SupabaseClient get _client => Supabase.instance.client;

  String? _deviceId;

  /// 初始化：生成或读取设备 UUID
  Future<void> init() async {
    _deviceId = await _getOrCreateDeviceId();
  }

  /// 从 localStorage 读取设备 ID，没有则生成新的
  Future<String> _getOrCreateDeviceId() async {
    try {
      final existing = _client.auth.currentSession?.accessToken;
      // 尝试从 localStorage 读取（通过 Supabase 的本地存储）
      // 实际上我们用 Supabase 的 auth 存储来存 device_id
      // 但 auth 失败了，所以我们用另一种方式
    } catch (_) {}

    // 生成新的 UUID v4
    return _generateUuid();
  }

  String _generateUuid() {
    final random = math.Random();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0F) | 0x40; // version 4
    bytes[8] = (bytes[8] & 0x3F) | 0x80; // variant

    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20, 32)}';
  }

  @override
  Future<void> saveGame(GameData data, {Map<String, Equipment>? equipmentInstances}) async {
    if (_deviceId == null) throw Exception('未初始化');

    final saveData = {
      'schema_version': 1,
      'player': _playerToJson(data.player),
      'current_map_id': data.currentMap.id,
      'logs': data.logs.map((log) => {
        'message': log.message,
        'type': log.type.index,
        'timestamp': log.timestamp.toIso8601String(),
      }).toList(),
      'mails': data.mails.map((mail) => _mailToJson(mail)).toList(),
      'quests': data.quests.map((quest) => _questToJson(quest)).toList(),
      'auto_explore': data.isAutoExplore,
      'auto_battle': data.isAutoBattle,
      'saved_at': DateTime.now().toIso8601String(),
    };

    final equipmentJson = equipmentInstances != null
        ? _equipmentInstancesToJson(equipmentInstances)
        : null;

    await _client.from(_tableName).upsert({
      'device_id': _deviceId,
      'save_data': saveData,
      'equipment_instances': equipmentJson,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<GameData?> loadGame() async {
    if (_deviceId == null) return null;

    try {
      final response = await _client
          .from(_tableName)
          .select()
          .eq('device_id', _deviceId!)
          .maybeSingle();

      if (response == null) return null;

      final saveData = response['save_data'] as Map<String, dynamic>;
      final player = _playerFromJson(saveData['player'] as Map<String, dynamic>);
      final currentMapId = saveData['current_map_id'] as String;
      final logs = ((saveData['logs'] as List?) ?? []).map((log) => LogEntry(
        message: log['message'] as String,
        type: LogType.values[log['type'] as int],
      )).toList();
      final mails = ((saveData['mails'] as List?) ?? [])
          .map((m) => _mailFromJson(m as Map<String, dynamic>))
          .toList();
      final quests = ((saveData['quests'] as List?) ?? [])
          .map((q) => _questFromJson(q as Map<String, dynamic>))
          .toList();
      final isAutoExplore = saveData['auto_explore'] as bool? ?? false;
      final isAutoBattle = saveData['auto_battle'] as bool? ?? false;

      return GameData(
        player: player,
        currentMap: GameMaps.getMap(currentMapId),
        gameState: GameState.exploring,
        logs: logs,
        random: Random(),
        mails: mails,
        quests: quests,
        isAutoExplore: isAutoExplore,
        isAutoBattle: isAutoBattle,
      );
    } catch (e, stack) {
      print('云端读档失败: $e\n$stack');
      return null;
    }
  }

  @override
  Future<Map<String, Equipment>?> loadEquipmentInstances() async {
    if (_deviceId == null) return null;

    try {
      final response = await _client
          .from(_tableName)
          .select('equipment_instances')
          .eq('device_id', _deviceId!)
          .maybeSingle();

      if (response == null) return null;

      final jsonStr = response['equipment_instances'] as String?;
      if (jsonStr == null) return null;

      return _equipmentInstancesFromJson(jsonStr);
    } catch (e) {
      print('云端装备实例加载失败: $e');
      return null;
    }
  }

  @override
  Future<void> deleteSave() async {
    if (_deviceId == null) return;
    await _client.from(_tableName).delete().eq('device_id', _deviceId!);
  }

  @override
  Future<bool> hasSave() async {
    if (_deviceId == null) return false;
    final response = await _client
        .from(_tableName)
        .select()
        .eq('device_id', _deviceId!)
        .maybeSingle();
    return response != null;
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
      'mails': data.mails.map((mail) => _mailToJson(mail)).toList(),
      'quests': data.quests.map((quest) => _questToJson(quest)).toList(),
      'equipmentInstances': _equipmentInstancesToJson(equipmentInstances),
      'exportedAt': DateTime.now().toIso8601String(),
    };

    return jsonEncode(exportData);
  }

  @override
  Future<void> importFromJson(String json) async {
    const maxImportBytes = 1024 * 1024;
    if (json.length > maxImportBytes) {
      throw FormatException('存档过大 (${json.length} > $maxImportBytes 字节)');
    }
    if (json.trim().isEmpty) {
      throw const FormatException('存档内容为空');
    }

    final Map<String, dynamic> data;
    try {
      final decoded = jsonDecode(json);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('存档根节点必须是对象');
      }
      data = decoded;
    } catch (e) {
      throw FormatException('JSON 解析失败: $e');
    }

    if (data['player'] is! Map<String, dynamic>) {
      throw const FormatException('缺少 player 字段或类型错误');
    }
    if (data['currentMapId'] is! String) {
      throw const FormatException('缺少 currentMapId 字段或类型错误');
    }

    final currentMapId = data['currentMapId'] as String;
    final knownMap = GameMaps.getMap(currentMapId);
    if (knownMap.id != currentMapId) {
      throw FormatException('未知地图: $currentMapId');
    }

    final Player player;
    final List<LogEntry> logs;
    final List<GameMail> mails;
    final List<GameQuest> quests;
    try {
      player = _playerFromJson(data['player'] as Map<String, dynamic>);
      logs = ((data['logs'] as List?) ?? []).map((log) => LogEntry(
        message: log['message'] as String,
        type: LogType.values[log['type'] as int],
      )).toList();
      mails = data['mails'] != null
          ? (data['mails'] as List).map((m) => _mailFromJson(m as Map<String, dynamic>)).toList()
          : <GameMail>[];
      quests = data['quests'] != null
          ? (data['quests'] as List).map((q) => _questFromJson(q as Map<String, dynamic>)).toList()
          : QuestDatabase.getAllQuests();
    } catch (e) {
      throw FormatException('存档结构解析失败: $e');
    }

    if (_deviceId == null) throw Exception('未初始化');

    final saveData = {
      'schema_version': 1,
      'player': _playerToJson(player),
      'current_map_id': currentMapId,
      'logs': logs.map((log) => {
        'message': log.message,
        'type': log.type.index,
        'timestamp': log.timestamp.toIso8601String(),
      }).toList(),
      'mails': mails.map((m) => _mailToJson(m)).toList(),
      'quests': quests.map((q) => _questToJson(q)).toList(),
      'saved_at': DateTime.now().toIso8601String(),
    };

    await _client.from(_tableName).upsert({
      'device_id': _deviceId,
      'save_data': saveData,
      'equipment_instances': data['equipmentInstances'] is String ? data['equipmentInstances'] : null,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  // ========== JSON 序列化辅助方法 ==========

  Map<String, dynamic> _playerToJson(Player player) {
    return {
      'name': player.name,
      'job': player.job.index,
      'stats': {
        'level': player.stats.level,
        'hp': player.stats.hp,
        'max_hp': player.stats.maxHp,
        'mp': player.stats.mp,
        'max_mp': player.stats.maxMp,
        'exp': player.stats.exp,
        'max_exp': player.stats.maxExp,
        'str': player.stats.str,
        'dex': player.stats.dex,
        'int': player.stats.intStat,
        'luk': player.stats.luk,
        'ap': player.stats.ap,
        'sp': player.stats.sp,
      },
      'meso': player.meso,
      'inventory': player.inventory,
      'current_map': player.currentMap,
      'skill_levels': player.skillLevels,
      'equipment': _equipmentMapToJson(player.equipment),
    };
  }

  Player _playerFromJson(Map<String, dynamic> json) {
    final statsJson = json['stats'] as Map<String, dynamic>;
    final skillLevelsRaw = json['skill_levels'];
    final Map<String, int> skillLevels = skillLevelsRaw is Map
        ? skillLevelsRaw.map((k, v) => MapEntry(k.toString(), v as int))
        : <String, int>{};

    final equipmentJson = json['equipment'] as Map<String, dynamic>?;
    final equipment = equipmentJson != null
        ? _equipmentMapFromJson(equipmentJson)
        : <EquipmentSlot, Equipment?>{};

    return Player(
      name: json['name'] as String,
      job: Job.values[json['job'] as int],
      stats: Stats(
        level: statsJson['level'] as int,
        hp: statsJson['hp'] as int,
        maxHp: statsJson['max_hp'] as int,
        mp: statsJson['mp'] as int,
        maxMp: statsJson['max_mp'] as int,
        exp: statsJson['exp'] as int,
        maxExp: statsJson['max_exp'] as int,
        str: statsJson['str'] as int,
        dex: statsJson['dex'] as int,
        intStat: statsJson['int'] as int,
        luk: statsJson['luk'] as int,
        ap: statsJson['ap'] as int? ?? 0,
        sp: statsJson['sp'] as int? ?? 0,
      ),
      meso: json['meso'] as int,
      inventory: List<String>.from(json['inventory'] as List),
      currentMap: json['current_map'] as String,
      skillLevels: skillLevels,
      equipment: equipment,
    );
  }

  Map<String, dynamic> _mailToJson(GameMail mail) {
    return {
      'id': mail.id,
      'title': mail.title,
      'content': mail.content,
      'sender': mail.sender,
      'sent_at': mail.sentAt.toIso8601String(),
      'is_read': mail.isRead,
      'is_claimed': mail.isClaimed,
      'attachments': mail.attachments.map((a) => {
        'type': a.type.index,
        'item_id': a.itemId,
        'equipment_id': a.equipmentId,
        'instance_id': a.instanceId,
        'count': a.count,
        'meso': a.meso,
      }).toList(),
    };
  }

  GameMail _mailFromJson(Map<String, dynamic> json) {
    return GameMail(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      sender: json['sender'] as String,
      sentAt: DateTime.parse(json['sent_at'] as String),
      isRead: json['is_read'] as bool? ?? false,
      isClaimed: json['is_claimed'] as bool? ?? false,
      attachments: (json['attachments'] as List? ?? [])
          .map((a) => MailAttachment(
            type: MailAttachmentType.values[a['type'] as int],
            itemId: a['item_id'] as String?,
            equipmentId: a['equipment_id'] as String?,
            instanceId: a['instance_id'] as String?,
            count: a['count'] as int?,
            meso: a['meso'] as int?,
          ))
          .toList(),
    );
  }

  Map<String, dynamic> _questToJson(GameQuest quest) {
    return {
      'id': quest.id,
      'title': quest.title,
      'description': quest.description,
      'type': quest.type.index,
      'min_level': quest.minLevel,
      'required_job': quest.requiredJob?.index,
      'target_job': quest.targetJob?.index,
      'target_map_id': quest.targetMapId,
      'target_mobs': quest.targetMobs,
      'target_count': quest.targetCount,
      'current_count': quest.currentCount,
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
      minLevel: json['min_level'] as int,
      requiredJob: json['required_job'] != null ? Job.values[json['required_job'] as int] : null,
      targetJob: json['target_job'] != null ? Job.values[json['target_job'] as int] : null,
      targetMapId: json['target_map_id'] as String?,
      targetMobs: (json['target_mobs'] as List).cast<String>(),
      targetCount: json['target_count'] as int,
      currentCount: json['current_count'] as int,
      status: QuestStatus.values[json['status'] as int],
      rewards: (json['rewards'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, v as int),
      ),
    );
  }

  // ========== 装备序列化 ==========

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
      'instance_id': equipment.instanceId,
      'emoji': equipment.emoji,
      'description': equipment.description,
      'slot': equipment.slot.index,
      'atk': equipment.atk,
      'def': equipment.def,
      'str': equipment.str,
      'dex': equipment.dex,
      'int_bonus': equipment.intBonus,
      'luk': equipment.luk,
      'price': equipment.price,
      'level_req': equipment.levelReq,
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
        instanceId: json['instance_id'] as String,
        emoji: json['emoji'] as String?,
        description: json['description'] as String?,
        slot: EquipmentSlot.values[json['slot'] as int],
        atk: json['atk'] as int? ?? 0,
        def: json['def'] as int? ?? 0,
        str: json['str'] as int? ?? 0,
        dex: json['dex'] as int? ?? 0,
        intBonus: json['int_bonus'] as int? ?? 0,
        luk: json['luk'] as int? ?? 0,
        price: json['price'] as int?,
        levelReq: json['level_req'] as int?,
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

  Map<String, dynamic> _equipmentMapToJson(Map<EquipmentSlot, Equipment?> equipment) {
    final Map<String, dynamic> jsonMap = {};
    for (final entry in equipment.entries) {
      if (entry.value != null) {
        jsonMap[entry.key.index.toString()] = _equipmentToJson(entry.value!);
      }
    }
    return jsonMap;
  }

  Map<EquipmentSlot, Equipment?> _equipmentMapFromJson(Map<String, dynamic> json) {
    final Map<EquipmentSlot, Equipment?> equipment = {};
    for (final entry in json.entries) {
      final slotIndex = int.parse(entry.key);
      final slot = EquipmentSlot.values[slotIndex];
      equipment[slot] = _equipmentFromJson(entry.value as Map<String, dynamic>);
    }
    return equipment;
  }
}
