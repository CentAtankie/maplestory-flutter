import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_provider.dart';

class GameLog extends ConsumerStatefulWidget {
  const GameLog({super.key});

  @override
  ConsumerState<GameLog> createState() => _GameLogState();
}

class _GameLogState extends ConsumerState<GameLog> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logs = ref.watch(gameProvider).logs;

    // 自动滚动到底部
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F3460).withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF533483).withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题栏
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                const Icon(
                  Icons.chat_bubble_outline,
                  color: Colors.white70,
                  size: 16,
                ),
                const SizedBox(width: 8),
                const Text(
                  '冒险日志',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                // 清空按钮
                GestureDetector(
                  onTap: () {
                    // 可以添加清空日志功能
                  },
                  child: const Icon(
                    Icons.delete_outline,
                    color: Colors.white30,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
          
          // 日志列表
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final log = logs[index];
                return _buildLogItem(log, index == logs.length - 1);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogItem(LogEntry log, bool isLatest) {
    Color textColor;
    switch (log.type) {
      case LogType.success:
        textColor = Colors.green;
        break;
      case LogType.warning:
        textColor = Colors.orange;
        break;
      case LogType.error:
        textColor = Colors.red;
        break;
      case LogType.battle:
        textColor = Colors.yellow;
        break;
      case LogType.reward:
        textColor = Colors.amber;
        break;
      default:
        textColor = Colors.white70;
    }

    return AnimatedOpacity(
      opacity: isLatest ? 1.0 : 0.7,
      duration: const Duration(milliseconds: 300),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 时间戳
            Text(
              _formatTime(log.timestamp),
              style: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 10,
                fontFamily: 'Courier',
              ),
            ),
            const SizedBox(width: 8),
            // 消息
            Expanded(
              child: Text(
                log.message,
                style: TextStyle(
                  color: textColor,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
  }
}
