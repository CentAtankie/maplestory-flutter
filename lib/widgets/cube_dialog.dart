import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_provider.dart';
import '../game/models/player.dart';
import '../game/models/potential.dart';

/// 洗魔方对话框
class CubeDialog extends ConsumerStatefulWidget {
  final Equipment equipment;
  final String cubeType; // 'normal', 'advanced', 'super'

  const CubeDialog({
    super.key,
    required this.equipment,
    required this.cubeType,
  });

  @override
  ConsumerState<CubeDialog> createState() => _CubeDialogState();
}

class _CubeDialogState extends ConsumerState<CubeDialog> {
  bool _isRolling = false;
  List<PotentialStat>? _previewStats;
  PotentialGrade? _previewGrade;
  int _cubeUsedCount = 1; // 第一个魔方已在 CubeSelectorDialog 中消耗

  String get _cubeName {
    switch (widget.cubeType) {
      case 'advanced':
        return '高级神奇魔方';
      case 'super':
        return '超级神奇魔方';
      default:
        return '神奇魔方';
    }
  }

  String get _cubeEmoji {
    switch (widget.cubeType) {
      case 'advanced':
        return '🔷';
      case 'super':
        return '💎';
      default:
        return '🎲';
    }
  }

  void _rollPotential() {
    // 检查是否还有足够的魔方
    final cubeId = widget.cubeType == 'advanced'
        ? 'cube_advanced'
        : widget.cubeType == 'super'
            ? 'cube_super'
            : 'cube_normal';

    final player = ref.read(gameProvider).player;
    final cubeCount = player.inventory.where((id) => id == cubeId).length;

    // 检查是否至少有一个魔方
    if (cubeCount < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ 魔方不足！'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 消耗一个魔方
    ref.read(gameProvider.notifier).useItem(cubeId);

    setState(() {
      _isRolling = true;
    });

    // 模拟滚动动画
    Future.delayed(const Duration(milliseconds: 800), () {
      final currentPotential = widget.equipment.potential;
      final random = Random().nextInt(100); // 0-99 真正随机

      setState(() {
        // 判断是否升级潜能
        final currentGrade = currentPotential?.grade ?? PotentialGrade.rare;
        
        // 超级魔方洗A级物品时，应用高级魔方的效果（30%概率变S）
        if (widget.cubeType == 'super' && currentGrade == PotentialGrade.rare) {
          // 超级魔方洗A级 → 按高级魔方逻辑：30%概率升级到S级
          if (random < 30) {
            _previewGrade = PotentialGrade.epic;
            _previewStats = EquipmentPotential.generateEpic().stats;
          } else {
            _previewGrade = currentGrade;
            _previewStats = EquipmentPotential.generateRare().stats;
          }
        } else if (widget.cubeType == 'advanced' && currentGrade == PotentialGrade.rare) {
          // 高级魔方洗A级：30%概率升级到S级
          if (random < 30) {
            _previewGrade = PotentialGrade.epic;
            _previewStats = EquipmentPotential.generateEpic().stats;
          } else {
            _previewGrade = currentGrade;
            _previewStats = EquipmentPotential.generateRare().stats;
          }
        } else if (widget.cubeType == 'super' && currentGrade == PotentialGrade.epic) {
          // 超级魔方洗S级：20%概率升级到SS级
          if (random < 20) {
            _previewGrade = PotentialGrade.unique;
            _previewStats = EquipmentPotential.generateUnique().stats;
          } else {
            _previewGrade = currentGrade;
            _previewStats = EquipmentPotential.generateEpic().stats;
          }
        } else {
          // 同等级或已达上限：只重新随机属性
          _previewGrade = currentGrade;
          switch (_previewGrade) {
            case PotentialGrade.rare:
              _previewStats = EquipmentPotential.generateRare().stats;
              break;
            case PotentialGrade.epic:
              _previewStats = EquipmentPotential.generateEpic().stats;
              break;
            case PotentialGrade.unique:
              _previewStats = EquipmentPotential.generateUnique().stats;
              break;
            default:
              _previewStats = EquipmentPotential.generateRare().stats;
          }
        }
        _isRolling = false;
        _cubeUsedCount++; // 增加已使用魔方计数
      });
    });
  }

  void _applyPotential() {
    if (_previewStats == null || _previewGrade == null) return;

    // 更新装备潜能
    final updatedEquipment = Equipment(
      name: widget.equipment.name,
      id: widget.equipment.id,
      instanceId: widget.equipment.instanceId,
      emoji: widget.equipment.emoji,
      description: widget.equipment.description,
      slot: widget.equipment.slot,
      atk: widget.equipment.atk,
      def: widget.equipment.def,
      str: widget.equipment.str,
      dex: widget.equipment.dex,
      intBonus: widget.equipment.intBonus,
      luk: widget.equipment.luk,
      price: widget.equipment.price,
      levelReq: widget.equipment.levelReq,
      crit: widget.equipment.crit,
      avoid: widget.equipment.avoid,
      potential: EquipmentPotential(
        grade: _previewGrade!,
        stats: _previewStats!,
      ),
    );

    // 更新装备实例
    ref.read(gameProvider.notifier).updateEquipmentPotential(
      widget.equipment.instanceId,
      updatedEquipment.potential!,
    );

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✨ ${widget.equipment.name} 的潜能已更新！'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentPotential = widget.equipment.potential;
    final hasRolled = _previewStats != null;

    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A2E),
      title: Row(
        children: [
          Text(_cubeEmoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _cubeName,
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
          // 显示已使用魔方数量
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '已用: $_cubeUsedCount个',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 装备信息
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F3460),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Text(
                    widget.equipment.emoji ?? '📦',
                    style: const TextStyle(fontSize: 32),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.equipment.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (currentPotential != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Color(
                                int.parse(currentPotential.gradeColor.replaceFirst('#', '0xFF')),
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              currentPotential.gradeName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        else
                          const Text(
                            '无潜能',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 潜能预览区
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: hasRolled
                    ? Color(
                        int.parse(
                          (_previewGrade ?? PotentialGrade.rare)
                              .gradeColor
                              .replaceFirst('#', '0xFF'),
                        ),
                      ).withOpacity(0.2)
                    : const Color(0xFF0F3460),
                borderRadius: BorderRadius.circular(12),
                border: hasRolled
                    ? Border.all(
                        color: Color(
                          int.parse(
                            (_previewGrade ?? PotentialGrade.rare)
                                .gradeColor
                                .replaceFirst('#', '0xFF'),
                          ),
                        ),
                        width: 2,
                      )
                    : null,
              ),
              child: Column(
                children: [
                  if (_isRolling)
                    const Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 8),
                        Text(
                          '正在重塑潜能...',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    )
                  else if (hasRolled)
                    Column(
                      children: [
                        Text(
                          '新潜能 (${_previewGrade?.gradeName})',
                          style: TextStyle(
                            color: Color(
                              int.parse(
                                _previewGrade!
                                    .gradeColor
                                    .replaceFirst('#', '0xFF'),
                              ),
                            ),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ..._previewStats!.map((stat) => Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getGradeColor(stat.grade).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                stat.displayText,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: _getGradeColor(stat.grade),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  stat.grade,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                      ],
                    )
                  else if (currentPotential != null)
                    Column(
                      children: [
                        Text(
                          '当前潜能 (${currentPotential.gradeName})',
                          style: TextStyle(
                            color: Color(
                              int.parse(
                                currentPotential.gradeColor.replaceFirst('#', '0xFF'),
                              ),
                            ),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...currentPotential.stats.map((stat) => Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getGradeColor(stat.grade).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                stat.displayText,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: _getGradeColor(stat.grade),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  stat.grade,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                      ],
                    )
                  else
                    const Text(
                      '该装备暂无潜能\n点击"洗潜能"开始',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white54),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 提示信息
            if (widget.cubeType == 'advanced')
              const Text(
                '💡 有30%概率将潜能升级为S级(史诗)',
                style: TextStyle(
                  color: Colors.amber,
                  fontSize: 11,
                ),
              )
            else if (widget.cubeType == 'super')
              Builder(builder: (context) {
                final currentGrade = widget.equipment.potential?.grade;
                if (currentGrade == PotentialGrade.rare) {
                  // 超级魔方洗A级，按高级魔方效果
                  return const Text(
                    '💡 洗A级装备时：30%概率升级为S级(史诗)',
                    style: TextStyle(
                      color: Colors.amber,
                      fontSize: 11,
                    ),
                  );
                } else if (currentGrade == PotentialGrade.epic) {
                  // 超级魔方洗S级
                  return const Text(
                    '💡 洗S级装备时：20%概率升级为SS级(传说)',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 11,
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('退出'),
        ),
        if (hasRolled) ...[
          // 洗出潜能后显示两个按钮：继续洗 和 应用
          ElevatedButton.icon(
            onPressed: _isRolling ? null : _rollPotential,
            icon: _isRolling
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.casino),
            label: Text(_isRolling ? '洗潜能中...' : '继续洗'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: _applyPotential,
            icon: const Icon(Icons.check),
            label: const Text('应用新潜能'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ] else
          ElevatedButton.icon(
            onPressed: _isRolling ? null : _rollPotential,
            icon: _isRolling
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.casino),
            label: Text(_isRolling ? '洗潜能中...' : '洗潜能'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
            ),
          ),
      ],
    );
  }

  Color _getGradeColor(String grade) {
    switch (grade) {
      case 'B':
        return Colors.blue;
      case 'A':
        return Colors.purple;
      case 'S':
        return Colors.orange;
      case 'SS':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}

/// 获取魔方可用的最高潜能等级
PotentialGrade? _getMaxGradeForCube(String cubeType) {
  switch (cubeType) {
    case 'normal':
      return PotentialGrade.rare; // 神奇魔方只能用于A级
    case 'advanced':
      return PotentialGrade.epic; // 高级神奇魔方只能用于S级以下
    case 'super':
      return PotentialGrade.unique; // 超级神奇魔方能用于SS级以下
    default:
      return null;
  }
}

/// 检查装备是否可以使用该魔方
bool _canUseCubeOnEquipment(String cubeType, Equipment? equipment) {
  if (equipment == null) return false;
  final maxGrade = _getMaxGradeForCube(cubeType);
  if (maxGrade == null) return false;
  
  final currentGrade = equipment.potential?.grade ?? PotentialGrade.none;
  // 无潜能的装备也不能用魔方
  if (currentGrade == PotentialGrade.none) return false;
  
  // 检查当前等级是否不超过魔方支持的最高等级
  return currentGrade.index <= maxGrade.index;
}

/// 获取魔方限制的描述文本
String _getCubeLimitDescription(String cubeType) {
  switch (cubeType) {
    case 'normal':
      return '仅可用于A级(稀有)装备';
    case 'advanced':
      return '仅可用于S级(史诗)及以下装备';
    case 'super':
      return '可用于SS级(传说)及以下装备';
    default:
      return '';
  }
}

/// 选择装备使用魔方的对话框
class CubeEquipmentSelector extends ConsumerWidget {
  final String cubeType;
  final Equipment? initialEquipment;

  const CubeEquipmentSelector({
    super.key,
    required this.cubeType,
    this.initialEquipment,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(gameProvider).player;
    
    // 如果有初始装备，检查是否可以使用
    if (initialEquipment != null) {
      if (!_canUseCubeOnEquipment(cubeType, initialEquipment)) {
        // 显示错误提示并返回
        Future.microtask(() {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ 该装备不能使用${_getCubeName(cubeType)}！${_getCubeLimitDescription(cubeType)}'),
              backgroundColor: Colors.red,
            ),
          );
          Navigator.pop(context);
        });
        return const SizedBox.shrink();
      }
      return CubeDialog(
        equipment: initialEquipment!,
        cubeType: cubeType,
      );
    }
    
    // 获取已装备的装备，并过滤掉不符合等级的
    final maxGrade = _getMaxGradeForCube(cubeType);
    final equippedItems = player.equipment.values
        .where((e) => e != null && _canUseCubeOnEquipment(cubeType, e))
        .toList();

    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A2E),
      title: Row(
        children: [
          Text(_getCubeEmoji(cubeType), style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '选择要洗潜能的装备',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  '(${_getCubeName(cubeType)} - ${_getCubeLimitDescription(cubeType)})',
                  style: const TextStyle(color: Colors.amber, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 350,
        child: equippedItems.isEmpty
            ? const Center(
                child: Text(
                  '没有符合条件的装备\n该魔方只能用于特定等级的装备',
                  style: TextStyle(color: Colors.white54),
                  textAlign: TextAlign.center,
                ),
              )
            : ListView.builder(
                itemCount: equippedItems.length,
                itemBuilder: (context, index) {
                  final equipment = equippedItems[index]!;
                  final potential = equipment.potential;

                  return Card(
                    color: const Color(0xFF0F3460),
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Text(
                        equipment.emoji ?? '📦',
                        style: const TextStyle(fontSize: 28),
                      ),
                      title: Text(
                        equipment.name,
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: potential != null
                          ? Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Color(
                                  int.parse(
                                    potential.gradeColor.replaceFirst('#', '0xFF'),
                                  ),
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                potential.gradeName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              ),
                            )
                          : const Text(
                              '无潜能',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                      trailing: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          showDialog(
                            context: context,
                            builder: (context) => CubeDialog(
                              equipment: equipment,
                              cubeType: cubeType,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('选择'),
                      ),
                    ),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
      ],
    );
  }
}

/// 获取魔方名称
String _getCubeName(String cubeType) {
  switch (cubeType) {
    case 'advanced':
      return '高级神奇魔方';
    case 'super':
      return '超级神奇魔方';
    default:
      return '神奇魔方';
  }
}

/// 获取魔方emoji
String _getCubeEmoji(String cubeType) {
  switch (cubeType) {
    case 'advanced':
      return '🔷';
    case 'super':
      return '💎';
    default:
      return '🎲';
  }
}