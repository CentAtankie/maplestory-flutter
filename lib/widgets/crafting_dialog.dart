import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../game/models/crafting.dart';
import '../game/models/item.dart';
import '../game/models/player.dart';
import '../providers/game_provider.dart';
import '../utils/maple_theme.dart';

class CraftingDialog extends ConsumerWidget {
  const CraftingDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(gameProvider).player;
    final recipes = CraftingDatabase.getAll();

    return AlertDialog(
      backgroundColor: MapleColors.background,
      title: const Row(
        children: [
          Text('🔨 合成', style: TextStyle(color: Colors.white, fontSize: 18)),
        ],
      ),
      content: SizedBox(
        width: 380,
        height: 500,
        child: Column(
          children: [
            // Material count summary
            _buildMaterialSummary(player),
            const SizedBox(height: 12),
            const Divider(color: Colors.white24),
            const SizedBox(height: 8),
            // Recipe list
            Expanded(
              child: ListView.builder(
                itemCount: recipes.length,
                itemBuilder: (context, index) {
                  final recipe = recipes[index];
                  return _buildRecipeCard(context, ref, player, recipe);
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('关闭'),
        ),
      ],
    );
  }

  Widget _buildMaterialSummary(Player player) {
    // Count key materials
    final materials = <String, String>{
      'snail_shell': '🐚',
      'blue_snail_shell': '🔷',
      'red_snail_shell': '🔴',
      'slime_bubble': '💧',
      'mushroom_cap': '🍄',
      'wood_piece': '🪵',
      'boar_tooth': '🦷',
      'golem_stone': '🗿',
    };

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: materials.entries.map((entry) {
        final count = player.inventory.where((id) => id == entry.key).length;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: MapleColors.card,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '${entry.value} $count',
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRecipeCard(
    BuildContext context,
    WidgetRef ref,
    Player player,
    CraftingRecipe recipe,
  ) {
    final canCraft = recipe.canCraft(player);

    return Card(
      color: MapleColors.card,
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(recipe.emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recipe.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        recipe.description,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Result type badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: recipe.resultType == CraftResultType.equipment
                        ? Colors.purple.withOpacity(0.3)
                        : Colors.blue.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    recipe.resultType == CraftResultType.equipment ? '装备' : '物品',
                    style: TextStyle(
                      color: recipe.resultType == CraftResultType.equipment
                          ? Colors.purple
                          : Colors.blue,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Required materials
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: recipe.requiredMaterials.entries.map((entry) {
                final item = ShopDatabase.getById(entry.key);
                final hasCount = player.inventory.where((id) => id == entry.key).length;
                final hasEnough = hasCount >= entry.value;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: hasEnough
                        ? Colors.green.withOpacity(0.2)
                        : Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: hasEnough
                          ? Colors.green.withOpacity(0.5)
                          : Colors.red.withOpacity(0.5),
                    ),
                  ),
                  child: Text(
                    '${item?.emoji ?? "📦"} ${item?.name ?? entry.key} ${hasCount}/${entry.value}',
                    style: TextStyle(
                      color: hasEnough ? Colors.green : Colors.red,
                      fontSize: 11,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            // Craft button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: canCraft
                    ? () => _craft(context, ref, recipe)
                    : null,
                icon: const Icon(Icons.build, size: 16),
                label: const Text('合成'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: Colors.grey[700],
                  disabledForegroundColor: Colors.grey[500],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _craft(BuildContext context, WidgetRef ref, CraftingRecipe recipe) {
    final notifier = ref.read(gameProvider.notifier);
    final result = notifier.craftItem(recipe);

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Text(result.itemEmoji ?? '🔨', style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                result.message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: result.success ? Colors.green : Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
