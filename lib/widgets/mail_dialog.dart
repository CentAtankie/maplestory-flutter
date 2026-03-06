import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_provider.dart';
import '../game/models/mail.dart';
import '../game/models/item.dart';

/// 邮件对话框
class MailDialog extends ConsumerStatefulWidget {
  const MailDialog({super.key});

  @override
  ConsumerState<MailDialog> createState() => _MailDialogState();
}

class _MailDialogState extends ConsumerState<MailDialog> {
  GameMail? _selectedMail;

  @override
  Widget build(BuildContext context) {
    final mails = ref.watch(gameProvider).mails;
    final unreadCount = mails.where((m) => !m.isRead).length;

    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A2E),
      title: Row(
        children: [
          const Text(
            '📧 邮件',
            style: TextStyle(color: Colors.white),
          ),
          if (unreadCount > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$unreadCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 450,
        child: mails.isEmpty
            ? const Center(
                child: Text(
                  '暂无邮件',
                  style: TextStyle(color: Colors.white54),
                ),
              )
            : Row(
                children: [
                  // 邮件列表
                  SizedBox(
                    width: 200,
                    child: ListView.builder(
                      itemCount: mails.length,
                      itemBuilder: (context, index) {
                        final mail = mails[index];
                        return _buildMailListItem(mail);
                      },
                    ),
                  ),
                  const VerticalDivider(color: Colors.white24),
                  // 邮件详情
                  Expanded(
                    child: _selectedMail != null
                        ? _buildMailDetail(_selectedMail!)
                        : const Center(
                            child: Text(
                              '选择一封邮件查看详情',
                              style: TextStyle(color: Colors.white54),
                            ),
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

  /// 构建邮件列表项
  Widget _buildMailListItem(GameMail mail) {
    final isSelected = _selectedMail?.id == mail.id;
    final hasAttachment = mail.hasUnclaimedAttachments;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedMail = mail;
        });
        // 标记为已读
        if (!mail.isRead) {
          ref.read(gameProvider.notifier).markMailAsRead(mail.id);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF533483)
              : mail.isRead
                  ? Colors.transparent
                  : const Color(0xFF0F3460),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF533483)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            // 未读指示器
            if (!mail.isRead)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              )
            else
              const SizedBox(width: 8),
            const SizedBox(width: 8),
            // 附件指示器
            if (hasAttachment)
              const Text('🎁', style: TextStyle(fontSize: 16))
            else
              const SizedBox(width: 24),
            const SizedBox(width: 8),
            // 标题
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mail.title,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight:
                          mail.isRead ? FontWeight.normal : FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    mail.sender,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建邮件详情
  Widget _buildMailDetail(GameMail mail) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题
        Text(
          mail.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        // 发送者和时间
        Row(
          children: [
            Text(
              '发件人: ${mail.sender}',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const Spacer(),
            Text(
              _formatDate(mail.sentAt),
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
        const Divider(color: Colors.white24),
        // 内容 - 限制最大高度
        Flexible(
          child: SingleChildScrollView(
            child: Text(
              mail.content,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ),
        // 附件区域
        if (mail.attachments.isNotEmpty) ...[
          const Divider(color: Colors.white24),
          const Text(
            '🎁 附件',
            style: TextStyle(
              color: Colors.amber,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: mail.attachments.map((attachment) {
              return _buildAttachmentItem(attachment);
            }).toList(),
          ),
          const SizedBox(height: 12),
          // 领取按钮
          if (!mail.isClaimed)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  ref.read(gameProvider.notifier).claimMailAttachments(mail.id);
                  setState(() {
                    _selectedMail = _selectedMail?.copyWith(isClaimed: true);
                  });
                },
                icon: const Icon(Icons.card_giftcard),
                label: const Text('一键领取'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '✓ 已领取',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54),
              ),
            ),
        ],
        // 删除按钮
        if (mail.isClaimed || mail.attachments.isEmpty)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                ref.read(gameProvider.notifier).deleteMail(mail.id);
                setState(() {
                  _selectedMail = null;
                });
              },
              icon: const Icon(Icons.delete, size: 16),
              label: const Text('删除'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
            ),
          ),
      ],
    );
  }

  /// 构建附件项
  Widget _buildAttachmentItem(MailAttachment attachment) {
    String emoji = '📦';
    String name = '未知物品';
    String count = '';

    switch (attachment.type) {
      case MailAttachmentType.item:
        final item = ShopDatabase.getById(attachment.itemId ?? '');
        if (item != null) {
          emoji = item.emoji;
          name = item.name;
          count = '×${attachment.count}';
        }
        break;
      case MailAttachmentType.meso:
        emoji = '💰';
        name = '金币';
        count = '${attachment.meso}';
        break;
      case MailAttachmentType.equipment:
        emoji = '⚔️';
        name = '装备';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0F3460),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Text(
            name,
            style: const TextStyle(color: Colors.white),
          ),
          if (count.isNotEmpty) ...[
            const SizedBox(width: 4),
            Text(
              count,
              style: const TextStyle(
                color: Colors.amber,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
