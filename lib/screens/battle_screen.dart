import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import "../utils/maple_theme.dart";
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_provider.dart';
import '../game/models/mob.dart';
import '../game/models/player.dart';
import '../services/audio_manager.dart';
import '../widgets/status_bar.dart';
import '../widgets/game_log.dart';

class BattleScreen extends ConsumerStatefulWidget {
  const BattleScreen({super.key});

  @override
  ConsumerState<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends ConsumerState<BattleScreen>
    with TickerProviderStateMixin {
  StreamSubscription<BattleEffect>? _effectSub;
  late final AnimationController _shakeCtrl;
  final List<_DamageOverlayItem> _overlayItems = [];
  int _itemIdSeq = 0;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    // 进入下一帧后再订阅,避免在 build 中读取 notifier
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _effectSub = ref
          .read(gameProvider.notifier)
          .battleEffects
          .listen(_handleEffect);
    });
  }

  void _handleEffect(BattleEffect effect) {
    if (!mounted) return;

    // 飘字
    final id = _itemIdSeq++;
    setState(() {
      _overlayItems.add(_DamageOverlayItem(id: id, effect: effect));
    });

    // 震屏 + 触感反馈
    final audio = AudioManager();
    if (effect.isFatal) {
      _shakeCtrl.forward(from: 0);
      audio.hapticHeavy();
    } else if (effect.isCrit) {
      _shakeCtrl.forward(from: 0);
      audio.hapticHeavy();
    } else if (effect.target == BattleEffectTarget.player && !effect.isAvoided) {
      _shakeCtrl.forward(from: 0);
      audio.hapticHit();
    } else if (effect.target == BattleEffectTarget.mob && !effect.isAvoided) {
      audio.hapticHit();
    }
  }

  void _removeOverlayItem(int id) {
    if (!mounted) return;
    setState(() {
      _overlayItems.removeWhere((e) => e.id == id);
    });
  }

  @override
  void dispose() {
    _effectSub?.cancel();
    _shakeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mob = ref.watch(gameProvider.select((g) => g.currentMob))!;
    final player = ref.watch(gameProvider.select((g) => g.player));
    final isAutoBattle = ref.watch(gameProvider.select((g) => g.isAutoBattle));

    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) => _handleKey(event, player),
      child: Scaffold(
        backgroundColor: const Color(0xFF2D1B1B),
        body: SafeArea(
          child: AnimatedBuilder(
            animation: _shakeCtrl,
            builder: (context, child) {
              // 衰减式正弦震动
              final t = _shakeCtrl.value;
              final amp = (1 - t) * 8;
              final dx = math.sin(t * math.pi * 6) * amp;
              return Transform.translate(
                offset: Offset(dx, 0),
                child: child,
              );
            },
          child: Column(
            children: [
              const StatusBar(),
              Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                decoration: BoxDecoration(
                  color: isAutoBattle
                      ? Colors.amber.withOpacity(0.2)
                      : Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isAutoBattle
                        ? Colors.amber.withOpacity(0.6)
                        : Colors.red.withOpacity(0.5),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isAutoBattle ? Icons.flash_on : Icons.warning,
                      color: isAutoBattle ? Colors.amber : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isAutoBattle ? '⚡ 自动战斗中' : '⚔️ 战斗中',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isAutoBattle ? Colors.amber : Colors.red,
                      ),
                    ),
                    if (isAutoBattle) ...[
                      const SizedBox(width: 12),
                      _PulseDot(color: Colors.amber),
                    ],
                  ],
                ),
              ),

              // 敌人区: 飘字定位在这里
              Stack(
                clipBehavior: Clip.none,
                children: [
                  _buildEnemyInfo(mob),
                  ..._overlayItems
                      .where((e) => e.effect.target == BattleEffectTarget.mob)
                      .map((e) => Positioned(
                            top: 24,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: _FloatingDamage(
                                key: ValueKey(e.id),
                                effect: e.effect,
                                onComplete: () => _removeOverlayItem(e.id),
                              ),
                            ),
                          )),
                ],
              ),

              const Expanded(child: GameLog()),

              // 战斗操作区: 玩家飘字定位在这里
              Stack(
                clipBehavior: Clip.none,
                children: [
                  _buildBattleActions(context, ref, player),
                  ..._overlayItems
                      .where((e) => e.effect.target == BattleEffectTarget.player)
                      .map((e) => Positioned(
                            top: 8,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: _FloatingDamage(
                                key: ValueKey(e.id),
                                effect: e.effect,
                                onComplete: () => _removeOverlayItem(e.id),
                              ),
                            ),
                          )),
                ],
              ),
            ],
          ),
        ),
      ),
     ),
    );
  }

  /// 键盘快捷键: 1=普攻 2=技能 Esc/F=逃跑 I=查看状态
  KeyEventResult _handleKey(KeyEvent event, Player player) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final notifier = ref.read(gameProvider.notifier);
    if (event.logicalKey == LogicalKeyboardKey.digit1 ||
        event.logicalKey == LogicalKeyboardKey.numpad1) {
      notifier.attack();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.digit2 ||
        event.logicalKey == LogicalKeyboardKey.numpad2) {
      if (player.stats.mp >= player.job.skill.mpCost) notifier.useSkill();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.escape ||
        event.logicalKey == LogicalKeyboardKey.keyF) {
      notifier.flee();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.keyI) {
      _showStatusDialog(context, player);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Widget _buildEnemyInfo(Mob mob) {
    final hpPercent = mob.hp / mob.maxHp;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MapleColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Text(
            mob.emoji,
            style: const TextStyle(fontSize: 48),
          ),
          const SizedBox(height: 8),
          Text(
            '${mob.name} Lv.${mob.level}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text(
                'HP: ',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: hpPercent,
                    backgroundColor: Colors.grey[800],
                    valueColor: AlwaysStoppedAnimation(
                      hpPercent > 0.5 ? Colors.green :
                      hpPercent > 0.25 ? Colors.orange : Colors.red,
                    ),
                    minHeight: 20,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${mob.hp}/${mob.maxHp}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStatBadge('⚔️ ${mob.atk}', Colors.orange),
              const SizedBox(width: 16),
              _buildStatBadge('🛡️ ${mob.def}', Colors.blue),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildBattleActions(BuildContext context, WidgetRef ref, Player player) {
    final skill = player.job.skill;
    final canUseSkill = player.stats.mp >= skill.mpCost;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MapleColors.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.info,
                    label: '查看状态',
                    color: Colors.blue,
                    onPressed: () {
                      _showStatusDialog(context, player);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.auto_fix_high,
                    label: '${skill.emoji} ${skill.name}',
                    color: canUseSkill ? Colors.purple : Colors.grey,
                    subLabel: canUseSkill ? '消耗 ${skill.mpCost} MP' : 'MP 不足',
                    onPressed: canUseSkill
                        ? () => ref.read(gameProvider.notifier).useSkill()
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.sports_martial_arts,
                    label: '普通攻击',
                    color: Colors.red,
                    onPressed: () {
                      ref.read(gameProvider.notifier).attack();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.run_circle,
                    label: '逃跑',
                    color: Colors.orange,
                    onPressed: () {
                      ref.read(gameProvider.notifier).flee();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    String? subLabel,
    required Color color,
    VoidCallback? onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        disabledBackgroundColor: Colors.grey[700],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 28),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (subLabel != null) ...[
            const SizedBox(height: 2),
            Text(
              subLabel,
              style: TextStyle(
                fontSize: 10,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showStatusDialog(BuildContext context, Player player) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: MapleColors.background,
        title: const Text(
          '角色状态',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusRow('等级', 'Lv.${player.stats.level}'),
            _buildStatusRow('HP', '${player.stats.hp}/${player.stats.maxHp}'),
            _buildStatusRow('MP', '${player.stats.mp}/${player.stats.maxMp}'),
            _buildStatusRow('EXP', '${player.stats.exp}/${player.stats.maxExp}'),
            const Divider(color: Colors.white24),
            _buildStatusRow('力量', '${player.stats.str}'),
            _buildStatusRow('敏捷', '${player.stats.dex}'),
            _buildStatusRow('智力', '${player.stats.intStat}'),
            _buildStatusRow('运气', '${player.stats.luk}'),
            const Divider(color: Colors.white24),
            _buildStatusRow('攻击力', '${player.getAtk()}'),
            _buildStatusRow('防御力', '${player.getDef()}'),
            _buildStatusRow('暴击率', '${player.getCritRate().toStringAsFixed(1)}%'),
            _buildStatusRow('闪避率', '${player.getAvoidRate().toStringAsFixed(1)}%'),
            const Divider(color: Colors.white24),
            _buildStatusRow('金币', '${player.meso} 💰'),
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

  Widget _buildStatusRow(String label, String value) {
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
}

/// 飘字队列项
class _DamageOverlayItem {
  final int id;
  final BattleEffect effect;
  _DamageOverlayItem({required this.id, required this.effect});
}

/// 单条飘字: 自管理动画,完成后回调清理
class _FloatingDamage extends StatefulWidget {
  final BattleEffect effect;
  final VoidCallback onComplete;
  const _FloatingDamage({super.key, required this.effect, required this.onComplete});

  @override
  State<_FloatingDamage> createState() => _FloatingDamageState();
}

class _FloatingDamageState extends State<_FloatingDamage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..addStatusListener((s) {
        if (s == AnimationStatus.completed) {
          widget.onComplete();
        }
      });
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.effect;

    // MP 回复特效: 显示 "💧 +N MP" 青色文字
    if (e.mpRegenAmount > 0) {
      return AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          final t = _ctrl.value;
          final dy = -50 * Curves.easeOut.transform(t);
          final opacity = (1 - t * t).clamp(0.0, 1.0);
          return Opacity(
            opacity: opacity,
            child: Transform.translate(
              offset: Offset(0, dy),
              child: Text(
                '💧 +${e.mpRegenAmount} MP',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.cyanAccent,
                  shadows: [
                    Shadow(blurRadius: 4, color: Colors.black, offset: Offset(1, 1)),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }

    final color = e.isAvoided
        ? Colors.white
        : e.isExtraHit
            ? Colors.cyanAccent
            : e.isCrit
                ? Colors.amber
                : (e.target == BattleEffectTarget.player ? Colors.red : Colors.orangeAccent);
    String text;
    if (e.isAvoided) {
      text = 'MISS';
    } else if (e.isExtraHit) {
      text = '⚡${e.damage}';
    } else if (e.isReduced) {
      text = '🛡️${e.damage}';
    } else {
      text = '${e.damage}';
    }
    final fontSize = e.isCrit
        ? 32.0
        : e.isAvoided
            ? 18.0
            : e.isExtraHit
                ? 16.0
                : 22.0;
    // 追打的初始位置稍微错开,避免和主打字重叠
    final initialDx = e.isExtraHit ? 30.0 : 0.0;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final t = _ctrl.value;
        // 上飘 + 淡出 + 暴击有点抖动
        final dy = -60 * Curves.easeOut.transform(t);
        final maxOpacity = e.isExtraHit ? 0.85 : 1.0;
        final opacity = ((1 - t * t) * maxOpacity).clamp(0.0, 1.0);
        final wobble = e.isCrit ? math.sin(t * math.pi * 4) * 4 : 0.0;
        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(wobble + initialDx, dy),
            child: Text(
              e.isCrit && !e.isAvoided ? '$text!' : text,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: color,
                shadows: const [
                  Shadow(blurRadius: 4, color: Colors.black, offset: Offset(1, 1)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 脉冲圆点 (用作"自动战斗中"指示器的呼吸光点)
class _PulseDot extends StatefulWidget {
  final Color color;
  const _PulseDot({required this.color});

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final scale = 0.6 + _ctrl.value * 0.6;
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: widget.color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: widget.color.withOpacity(0.5),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
