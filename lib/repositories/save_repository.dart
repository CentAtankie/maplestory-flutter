import '../game/models/player.dart';
import '../providers/game_provider.dart';

/// 存档仓库抽象接口
/// 现在用本地存储，以后可以换成 API 实现
abstract class SaveRepository {
  /// 保存游戏（包含装备实例）
  Future<void> saveGame(GameData data, {Map<String, Equipment>? equipmentInstances});
  
  /// 读取游戏存档
  Future<GameData?> loadGame();
  
  /// 加载装备实例
  Future<Map<String, Equipment>?> loadEquipmentInstances();
  
  /// 删除存档
  Future<void> deleteSave();
  
  /// 是否有存档
  Future<bool> hasSave();
  
  /// 导出存档为 JSON
  Future<String> exportToJson(Map<String, Equipment> equipmentInstances);
  
  /// 从 JSON 导入存档
  Future<void> importFromJson(String json);
}