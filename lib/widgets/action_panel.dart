import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_provider.dart';
import '../game/models/player.dart';
import '../game/models/map.dart';
import '../game/models/item.dart';
import '../screens/shop_screen.dart';

class ActionPanel extends ConsumerWidget {
  const ActionPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameProvider);
    final isTown = gameState.currentMap.isTown;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 方向按钮（十字键）
            _buildDirectionPad(context, ref, gameState),
            
            const SizedBox(height: 16),
            
            // 功能按钮
            _buildActionButtons(context, ref, isTown),
          ],
        ),
      ),
    );
  }

  Widget _buildDirectionPad(BuildContext context, WidgetRef ref, GameData gameState) {
    final exits = gameState.currentMap.exits;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 方向控制区
        Container(
          width: 160,
          height: 160,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 上
              Positioned(
                top: 0,
                child: _buildDirectionButton(
                  icon: Icons.arrow_upward,
                  label: exits['北'] != null ? '北' : '',
                  onPressed: exits['北'] != null 
                      ? () => ref.read(gameProvider.notifier).move('北')
                      : null,
                ),
              ),
              // 下
              Positioned(
                bottom: 0,
                child: _buildDirectionButton(
                  icon: Icons.arrow_downward,
                  label: exits['南'] != null ? '南' : '',
                  onPressed: exits['南'] != null 
                      ? () => ref.read(gameProvider.notifier).move('南')
                      : null,
                ),
              ),
              // 左
              Positioned(
                left: 0,
                child: _buildDirectionButton(
                  icon: Icons.arrow_back,
                  label: exits['西'] != null ? '西' : '',
                  onPressed: exits['西'] != null 
                      ? () => ref.read(gameProvider.notifier).move('西')
                      : null,
                ),
              ),
              // 右
              Positioned(
                right: 0,
                child: _buildDirectionButton(
                  icon: Icons.arrow_forward,
                  label: exits['东'] != null ? '东' : '',
                  onPressed: exits['东'] != null 
                      ? () => ref.read(gameProvider.notifier).move('东')
                      : null,
                ),
              ),
              // 中心（当前位置）
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF533483).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    '📍',
                    style: TextStyle(fontSize: 24),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDirectionButton({
    required IconData icon,
    required String label,
    VoidCallback? onPressed,
  }) {
    final isEnabled = onPressed != null;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: isEnabled 
                ? const Color(0xFF0F3460) 
                : Colors.grey[800],
            foregroundColor: isEnabled ? Colors.white : Colors.grey,
            padding: const EdgeInsets.all(12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: isEnabled ? 4 : 0,
          ),
          child: Icon(icon, size: 24),
        ),
        if (label.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isEnabled ? Colors.white70 : Colors.grey,
              fontSize: 10,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref, bool isTown) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // 狩猎/休息
        Expanded(
          child: _buildActionButton(
            icon: isTown ? Icons.hotel : Icons.sports_martial_arts,
            label: isTown ? '休息 (R)' : '探索',
            color: isTown ? Colors.green : Colors.orange,
            onPressed: () {
              if (isTown) {
                ref.read(gameProvider.notifier).rest();
              } else {
                ref.read(gameProvider.notifier).explore();
              }
            },
          ),
        ),
        const SizedBox(width: 12),
        
        // 商店
        Expanded(
          child: _buildActionButton(
            icon: Icons.store,
            label: '商店',
            color: isTown ? Colors.amber : Colors.grey,
            onPressed: isTown
                ? () {
                    ref.read(gameProvider.notifier).openShop();
                  }
                : null,
          ),
        ),
        const SizedBox(width: 12),
        
        // 物品栏
        Expanded(
          child: _buildActionButton(
            icon: Icons.backpack,
            label: '物品',
            color: Colors.blue,
            onPressed: () {
              _showInventoryDialog(context, ref);
            },
          ),
        ),
        const SizedBox(width: 12),
        
        // 角色
        Expanded(
          child: _buildActionButton(
            icon: Icons.person,
            label: '角色',
            color: Colors.purple,
            onPressed: () {
              _showCharacterDialog(context, ref);
            },
          ),
        ),
        const SizedBox(width: 12),
        
        // 设置
        Expanded(
          child: _buildActionButton(
            icon: Icons.settings,
            label: '设置',
            color: Colors.grey,
            onPressed: () {
              _showSettingsDialog(context, ref);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.2),
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withOpacity(0.5)),
        ),
        elevation: 0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
  }

  void _showInventoryDialog(BuildContext context, WidgetRef ref) {
    final player = ref.read(gameProvider).player;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text(
          '🎒 物品栏',
          style: TextStyle(color: Colors.white),
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: player.inventory.isEmpty
              ? const Center(
                  child: Text(
                    '背包是空的\n去商店购买一些药水吧！',
                    style: TextStyle(color: Colors.white54),
                    textAlign: TextAlign.center,
                  ),
                )
              : _buildInventoryList(context, ref, player),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryList(BuildContext context, WidgetRef ref, Player player) {
    // 统计物品数量
    final itemCounts = <String, int>{};
    for (final itemId in player.inventory) {
      itemCounts[itemId] = (itemCounts[itemId] ?? 0) + 1;
    }

    return ListView.builder(
      shrinkWrap: true,
      itemCount: itemCounts.length,
      itemBuilder: (context, index) {
        final entry = itemCounts.entries.elementAt(index);
        final item = ShopDatabase.getById(entry.key);
        if (item == null) return const SizedBox.shrink();

        return Card(
          color: const Color(0xFF0F3460),
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Text(item.emoji, style: const TextStyle(fontSize: 24)),
            title: Text(
              item.name,
              style: const TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              item.description,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 数量
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'x${entry.value}',
                    style: const TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // 材料显示"卖出"，消耗品显示"使用"
                if (item.type == ItemType.material)
                  ElevatedButton(
                    onPressed: () {
                      ref.read(gameProvider.notifier).sellItem(item.id, quantity: 1);
                      // 刷新对话框
                      Navigator.pop(context);
                      Future.delayed(const Duration(milliseconds: 100), () {
                        _showInventoryDialog(context, ref);
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: const Text('卖出'),
                  )
                else
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      ref.read(gameProvider.notifier).useItem(item.id);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: const Text('使用'),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCharacterDialog(BuildContext context, WidgetRef ref) {
    final player = ref.read(gameProvider).player;
    final stats = player.stats;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Text(
          '${player.job.emoji} 角色信息',
          style: const TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInfoRow('名字', player.name),
              _buildInfoRow('职业', player.job.displayName),
              _buildInfoRow('等级', 'Lv.${stats.level}'),
              const Divider(color: Colors.white24),
              _buildInfoRow('HP', '${stats.hp}/${stats.maxHp}'),
              _buildInfoRow('MP', '${stats.mp}/${stats.maxMp}'),
              _buildInfoRow('EXP', '${stats.exp}/${stats.maxExp}'),
              const Divider(color: Colors.white24),
              _buildInfoRow('力量', '${stats.str}'),
              _buildInfoRow('敏捷', '${stats.dex}'),
              _buildInfoRow('智力', '${stats.intStat}'),
              _buildInfoRow('运气', '${stats.luk}'),
              const Divider(color: Colors.white24),
              _buildInfoRow('攻击力', '${player.getAtk()}'),
              _buildInfoRow('防御力', '${player.getDef()}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog(BuildContext context, WidgetRef ref) async {
    final hasSave = await ref.read(gameProvider.notifier).hasSave();
    
    if (!context.mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text(
          '⚙️ 设置',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 修改名字
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.orange),
              title: const Text(
                '修改名字',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                '当前: ${ref.read(gameProvider).player.name}',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(context);
                _showRenameDialog(context, ref);
              },
            ),
            const Divider(color: Colors.white24),
            // 保存游戏
            ListTile(
              leading: const Icon(Icons.save, color: Colors.green),
              title: const Text(
                '保存游戏',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                '将当前进度保存到本地',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              onTap: () async {
                Navigator.pop(context);
                final success = await ref.read(gameProvider.notifier).saveGame();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? '✅ 游戏已保存' : '❌ 保存失败'),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ),
                  );
                }
              },
            ),
            // 读取存档
            ListTile(
              leading: Icon(Icons.folder_open, 
                color: hasSave ? Colors.blue : Colors.grey),
              title: Text(
                '读取存档',
                style: TextStyle(
                  color: hasSave ? Colors.white : Colors.grey,
                ),
              ),
              subtitle: Text(
                hasSave ? '加载上次保存的进度' : '没有存档',
                style: TextStyle(
                  color: hasSave ? Colors.white54 : Colors.grey, 
                  fontSize: 12
                ),
              ),
              onTap: hasSave ? () async {
                Navigator.pop(context);
                final success = await ref.read(gameProvider.notifier).loadGame();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? '✅ 存档已读取' : '❌ 读取失败'),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ),
                  );
                }
              } : null,
            ),
            // 导出存档
            ListTile(
              leading: const Icon(Icons.upload, color: Colors.orange),
              title: const Text(
                '导出存档',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                '导出为 JSON 文件（可转移存档）',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              onTap: () async {
                Navigator.pop(context);
                final json = await ref.read(gameProvider.notifier).exportToJson();
                if (context.mounted) {
                  if (json != null) {
                    // 显示导出成功提示，并让用户复制
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: const Color(0xFF1A1A2E),
                        title: const Text(
                          '📤 存档已导出',
                          style: TextStyle(color: Colors.white),
                        ),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              '请复制以下文本保存到安全的地方：',
                              style: TextStyle(color: Colors.white70),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.black26,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: SelectableText(
                                json.substring(0, json.length > 200 ? 200 : json.length) + '...',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('关闭'),
                          ),
                        ],
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('❌ 导出失败'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
            // 导入存档
            ListTile(
              leading: const Icon(Icons.download, color: Colors.purple),
              title: const Text(
                '导入存档',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                '从 JSON 文件恢复存档',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(context);
                _showImportDialog(context, ref);
              },
            ),
            const Divider(color: Colors.white24),
            // 删除存档
            ListTile(
              leading: Icon(Icons.delete, 
                color: hasSave ? Colors.red : Colors.grey),
              title: Text(
                '删除存档',
                style: TextStyle(
                  color: hasSave ? Colors.red : Colors.grey,
                ),
              ),
              onTap: hasSave ? () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: const Color(0xFF1A1A2E),
                    title: const Text(
                      '⚠️ 确认删除?',
                      style: TextStyle(color: Colors.red),
                    ),
                    content: const Text(
                      '存档将被永久删除，无法恢复！',
                      style: TextStyle(color: Colors.white70),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('取消'),
                      ),
                      TextButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          final success = await ref.read(gameProvider.notifier).deleteSave();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(success ? '🗑️ 存档已删除' : '❌ 删除失败'),
                                backgroundColor: success ? Colors.green : Colors.red,
                              ),
                            );
                          }
                        },
                        child: const Text(
                          '确认删除',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
              } : null,
            ),
            const Divider(color: Colors.white24),
            // 重新开始
            ListTile(
              leading: const Icon(Icons.refresh, color: Colors.white70),
              title: const Text(
                '重新开始',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: const Color(0xFF1A1A2E),
                    title: const Text(
                      '确认重新开始?',
                      style: TextStyle(color: Colors.white),
                    ),
                    content: const Text(
                      '当前进度将会丢失',
                      style: TextStyle(color: Colors.white70),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('取消'),
                      ),
                      TextButton(
                        onPressed: () {
                          ref.read(gameProvider.notifier).restart();
                          Navigator.pop(context);
                        },
                        child: const Text(
                          '确认',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  void _showImportDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text(
          '📥 导入存档',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '请粘贴之前导出的存档 JSON：',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 5,
              style: const TextStyle(color: Colors.white, fontSize: 12),
              decoration: InputDecoration(
                hintText: '{"player": {...}, ...}',
                hintStyle: const TextStyle(color: Colors.white30),
                filled: true,
                fillColor: Colors.black26,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              final json = controller.text.trim();
              if (json.isNotEmpty) {
                Navigator.pop(context);
                final success = await ref.read(gameProvider.notifier).importFromJson(json);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? '✅ 存档已导入' : '❌ 导入失败，请检查JSON格式'),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('导入'),
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController(text: ref.read(gameProvider).player.name);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text(
          '✏️ 修改名字',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '请输入新的冒险家名字：',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLength: 10,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: '输入名字（最多10字）',
                hintStyle: const TextStyle(color: Colors.white30),
                filled: true,
                fillColor: Colors.black26,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                counterStyle: const TextStyle(color: Colors.white54),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                Navigator.pop(context);
                final success = ref.read(gameProvider.notifier).changePlayerName(newName);
                if (success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('✨ 改名成功！欢迎 $newName'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('确认'),
          ),
        ],
      ),
    );
  }
}
