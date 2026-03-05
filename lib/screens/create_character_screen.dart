import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_provider.dart';
import '../game/models/player.dart';

/// 创建角色 - 投骰子界面
class CreateCharacterScreen extends ConsumerStatefulWidget {
  final String playerName;
  
  const CreateCharacterScreen({
    super.key,
    required this.playerName,
  });

  @override
  ConsumerState<CreateCharacterScreen> createState() => _CreateCharacterScreenState();
}

class _CreateCharacterScreenState extends ConsumerState<CreateCharacterScreen> {
  int _str = 4;
  int _dex = 4;
  int _int = 4;
  int _luk = 4;
  bool _isRolling = false;
  int _rollCount = 0;
  
  void _rollDice() {
    if (_isRolling) return;
    
    setState(() {
      _isRolling = true;
      _rollCount++;
    });
    
    // 模拟投骰子动画
    int animations = 0;
    const maxAnimations = 10;
    
    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      // 随机分配25点属性，每个属性4-13点
      final stats = _distributeStats();
      setState(() {
        _str = stats[0];
        _dex = stats[1];
        _int = stats[2];
        _luk = stats[3];
      });
      
      animations++;
      if (animations >= maxAnimations) {
        timer.cancel();
        setState(() {
          _isRolling = false;
        });
      }
    });
  }
  
  /// 分配25点属性，每个属性4-13点
  List<int> _distributeStats() {
    final random = Random();
    
    // 先给每个属性分配最低4点 (共16点)
    var remaining = 9; // 25 - 16 = 9点需要分配
    
    // 随机分配剩余点数
    var strBonus = random.nextInt(remaining + 1);
    if (strBonus > 9) strBonus = 9;
    remaining = remaining - strBonus;
    
    var dexBonus = random.nextInt(remaining + 1);
    if (dexBonus > 9) dexBonus = 9;
    remaining = remaining - dexBonus;
    
    var intBonus = random.nextInt(remaining + 1);
    if (intBonus > 9) intBonus = 9;
    remaining = remaining - intBonus;
    
    // 剩余全给运气
    var lukBonus = remaining;
    if (lukBonus > 9) lukBonus = 9;
    
    // 如果还有剩余，重新随机分配
    if (strBonus + dexBonus + intBonus + lukBonus < 9) {
      return _distributeStats();
    }
    
    return [
      4 + strBonus,
      4 + dexBonus,
      4 + intBonus,
      4 + lukBonus,
    ];
  }
  
  void _confirm() {
    // 创建新角色
    final newPlayer = Player(
      name: widget.playerName,
      job: Job.beginner,
      stats: Stats(
        str: _str,
        dex: _dex,
        intStat: _int,
        luk: _luk,
        hp: 50,
        maxHp: 50,
        mp: 5,
        maxMp: 5,
        level: 1,
        exp: 0,
        maxExp: 15,
        ap: 0,
      ),
    );
    
    // 更新游戏状态
    ref.read(gameProvider.notifier).setNewPlayer(newPlayer);
    
    // 返回游戏
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final total = _str + _dex + _int + _luk;
    
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 标题
              const Text(
                '🎲 投骰子决定初始属性',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '冒险家: ${widget.playerName}',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 32),
              
              // 骰子动画或属性展示
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F3460),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isRolling ? Colors.amber : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    // 力量
                    _buildStatRow('💪 力量', _str, Colors.red),
                    const SizedBox(height: 16),
                    // 敏捷
                    _buildStatRow('🏃 敏捷', _dex, Colors.green),
                    const SizedBox(height: 16),
                    // 智力
                    _buildStatRow('🧠 智力', _int, Colors.blue),
                    const SizedBox(height: 16),
                    // 运气
                    _buildStatRow('🍀 运气', _luk, Colors.purple),
                    const Divider(color: Colors.white24, height: 32),
                    // 总和
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          '总属性: ',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '$total',
                          style: TextStyle(
                            color: total >= 25 ? Colors.green : Colors.amber,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          ' / 25',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // 投骰子次数提示
              if (_rollCount > 0)
                Text(
                  '已投 $_rollCount 次',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              
              const SizedBox(height: 16),
              
              // 按钮
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isRolling ? null : _rollDice,
                      icon: _isRolling
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.casino),
                      label: Text(_isRolling ? '投骰子中...' : '🎲 投骰子'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _rollCount > 0 && !_isRolling ? _confirm : null,
                      icon: const Icon(Icons.check),
                      label: const Text('✅ 确定'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        disabledBackgroundColor: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // 提示
              const Text(
                '总属性25点随机分配\n每个属性4-13点，可以重复投骰子',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildStatRow(String label, int value, Color color) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 16,
          ),
        ),
        const Spacer(),
        // 进度条
        Container(
          width: 100,
          height: 12,
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(6),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: (value - 4) / 9,  // 4-13 映射到 0-1
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // 数值
        Container(
          width: 40,
          alignment: Alignment.center,
          child: Text(
            '$value',
            style: TextStyle(
              color: value >= 10 ? Colors.green : (value <= 5 ? Colors.red : Colors.white),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}