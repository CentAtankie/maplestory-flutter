import 'item.dart';
import 'player.dart';

///  crafting recipe result type
enum CraftResultType {
  item,       // consumable/scroll/material item
  equipment,  // equipment piece
}

/// Crafting recipe
class CraftingRecipe {
  final String name;
  final String emoji;
  final Map<String, int> requiredMaterials; // itemId -> count
  final String resultItemId;
  final CraftResultType resultType;
  final String description;

  const CraftingRecipe({
    required this.name,
    required this.emoji,
    required this.requiredMaterials,
    required this.resultItemId,
    required this.resultType,
    required this.description,
  });

  /// Check if player has all required materials
  bool canCraft(Player player) {
    for (final entry in requiredMaterials.entries) {
      final count = player.inventory.where((id) => id == entry.key).length;
      if (count < entry.value) return false;
    }
    return true;
  }

  /// Get missing materials description
  String getMissingMaterials(Player player) {
    final missing = <String>[];
    for (final entry in requiredMaterials.entries) {
      final count = player.inventory.where((id) => id == entry.key).length;
      if (count < entry.value) {
        final item = ShopDatabase.getById(entry.key);
        final itemName = item?.name ?? entry.key;
        missing.add('$itemName (${count}/${entry.value})');
      }
    }
    return missing.join(', ');
  }
}

/// Crafting result
class CraftResult {
  final bool success;
  final String message;
  final String? itemName;
  final String? itemEmoji;

  CraftResult({
    required this.success,
    required this.message,
    this.itemName,
    this.itemEmoji,
  });
}

/// Crafting database
class CraftingDatabase {
  static final List<CraftingRecipe> recipes = [
    // Potions
    CraftingRecipe(
      name: '红药水',
      emoji: '❤️',
      requiredMaterials: {'snail_shell': 2},
      resultItemId: 'red_potion',
      resultType: CraftResultType.item,
      description: '用蜗牛壳炼制的恢复药水',
    ),
    CraftingRecipe(
      name: '橙色药水',
      emoji: '🧡',
      requiredMaterials: {'blue_snail_shell': 2, 'slime_bubble': 1},
      resultItemId: 'orange_potion',
      resultType: CraftResultType.item,
      description: '高级恢复药水，需要蓝蜗牛壳和绿水灵的珠',
    ),
    CraftingRecipe(
      name: '大瓶红药水',
      emoji: '💖',
      requiredMaterials: {'red_snail_shell': 3, 'mushroom_cap': 2},
      resultItemId: 'red_potion_large',
      resultType: CraftResultType.item,
      description: '大瓶恢复药水，效果显著',
    ),
    CraftingRecipe(
      name: '大瓶蓝药水',
      emoji: '💎',
      requiredMaterials: {'blue_mushroom_cap': 2, 'slime_bubble': 3},
      resultItemId: 'blue_potion_large',
      resultType: CraftResultType.item,
      description: '大瓶魔力恢复药水',
    ),
    // Scrolls
    CraftingRecipe(
      name: '回城卷轴',
      emoji: '📜',
      requiredMaterials: {'wood_piece': 2, 'snail_shell': 1},
      resultItemId: 'town_scroll',
      resultType: CraftResultType.item,
      description: '可以立即回到射手村的卷轴',
    ),
    // Equipment
    CraftingRecipe(
      name: '新手剑',
      emoji: '🗡️',
      requiredMaterials: {'snail_shell': 5},
      resultItemId: 'beginner_sword',
      resultType: CraftResultType.equipment,
      description: '用蜗牛壳加固的训练用剑',
    ),
    CraftingRecipe(
      name: '木杖',
      emoji: '🪄',
      requiredMaterials: {'wood_piece': 3, 'snail_shell': 2},
      resultItemId: 'wooden_staff',
      resultType: CraftResultType.equipment,
      description: '用木材和蜗牛壳制作的简易法杖',
    ),
    CraftingRecipe(
      name: '皮帽',
      emoji: '🎩',
      requiredMaterials: {'boar_tooth': 2, 'slime_bubble': 2},
      resultItemId: 'leather_helmet',
      resultType: CraftResultType.equipment,
      description: '用野猪牙齿加固的皮帽',
    ),
    CraftingRecipe(
      name: '铁剑',
      emoji: '⚔️',
      requiredMaterials: {'golem_stone': 2, 'wood_piece': 3, 'boar_tooth': 3},
      resultItemId: 'iron_sword',
      resultType: CraftResultType.equipment,
      description: '用石头人核心打造的铁剑',
    ),
    CraftingRecipe(
      name: '铁甲',
      emoji: '👕',
      requiredMaterials: {'golem_stone': 3, 'boar_tooth': 2, 'wood_piece': 2},
      resultItemId: 'iron_armor',
      resultType: CraftResultType.equipment,
      description: '用石头人核心加固的铁甲',
    ),
    CraftingRecipe(
      name: '魔法袍',
      emoji: '👘',
      requiredMaterials: {'evil_eye_tail': 2, 'slime_bubble': 5},
      resultItemId: 'magic_robe',
      resultType: CraftResultType.equipment,
      description: '用独眼兽尾巴编织的魔法袍',
    ),
    // Special
    CraftingRecipe(
      name: '神奇魔方',
      emoji: '🎲',
      requiredMaterials: {'golem_stone': 5, 'dark_golem_stone': 2, 'ice_piece': 3},
      resultItemId: 'cube_normal',
      resultType: CraftResultType.item,
      description: '重塑装备潜能的神奇魔方',
    ),
    CraftingRecipe(
      name: '高级神奇魔方',
      emoji: '🔷',
      requiredMaterials: {'dark_golem_stone': 5, 'fire_piece': 3, 'wraith_cloth': 3},
      resultItemId: 'cube_advanced',
      resultType: CraftResultType.item,
      description: '有概率升级为史诗潜能的高级魔方',
    ),
  ];

  /// Get all recipes
  static List<CraftingRecipe> getAll() => recipes;

  /// Get recipe by result item ID
  static CraftingRecipe? getByResultId(String itemId) {
    for (final recipe in recipes) {
      if (recipe.resultItemId == itemId) return recipe;
    }
    return null;
  }
}
