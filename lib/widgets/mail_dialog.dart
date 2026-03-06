import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_provider.dart';
import '../game/models/mail.dart';
import '../game/models/item.dart';

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
          const Text('📧 邮件', style: TextStyle(color: Colors.white)),
          if (unreadCount > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(12)),
              child: Text('$unreadCount', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ],
      ),
      content: SizedBox(
        width: 500,
        height: 400,
        child: mails.isEmpty
            ? const Center(child: Text('暂无邮件', style: TextStyle(color: Colors.white54)))
            : Row(
                children: [
                  SizedBox(
                    width: 140,
                    child: ListView.builder(
                      itemCount: mails.length,
                      itemBuilder: (context, index) => _buildMailListItem(mails[index]),
                    ),
                  ),
                  const VerticalDivider(color: Colors.white24),
                  Expanded(
                    child: _selectedMail != null
                        ? _buildMailDetail(_selectedMail!)
                        : const Center(child: Text('选择邮件查看', style: TextStyle(color: Colors.white54))),
                  ),
                ],
              ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('关闭'))],
    );
  }

  Widget _buildMailListItem(GameMail mail) {
    final isSelected = _selectedMail?.id == mail.id;
    return InkWell(
      onTap: () {
        setState(() => _selectedMail = mail);
        if (!mail.isRead) ref.read(gameProvider.notifier).markMailAsRead(mail.id);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF533483) : mail.isRead ? Colors.transparent : const Color(0xFF0F3460),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            if (!mail.isRead) Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle)) else const SizedBox(width: 8),
            const SizedBox(width: 8),
            if (mail.hasUnclaimedAttachments) const Text('🎁', style: TextStyle(fontSize: 16)) else const SizedBox(width: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(mail.title, style: TextStyle(color: Colors.white, fontWeight: mail.isRead ? FontWeight.normal : FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(mail.sender, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMailDetail(GameMail mail) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(mail.title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Row(
          children: [
            Text('发件人: ${mail.sender}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
            const Spacer(),
            Text('${mail.sentAt.month}/${mail.sentAt.day}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
          ],
        ),
        const Divider(color: Colors.white24),
        Flexible(
          child: SingleChildScrollView(child: Text(mail.content, style: const TextStyle(color: Colors.white, fontSize: 14))),
        ),
        if (mail.attachments.isNotEmpty) ...[
          const Divider(color: Colors.white24),
          Row(
            children: [
              const Text('🎁', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () => _showGiftDetail(mail),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xFF533483), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.amber)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('新手冒险大礼包', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        Text('${mail.attachments.length}件', style: const TextStyle(color: Colors.amber)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (!mail.isClaimed)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  ref.read(gameProvider.notifier).claimMailAttachments(mail.id);
                  setState(() => _selectedMail = _selectedMail?.copyWith(isClaimed: true));
                },
                icon: const Icon(Icons.card_giftcard),
                label: const Text('一键领取'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.grey.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
              child: const Text('✓ 已领取', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54)),
            ),
        ],
        if (mail.isClaimed || mail.attachments.isEmpty)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                ref.read(gameProvider.notifier).deleteMail(mail.id);
                setState(() => _selectedMail = null);
              },
              icon: const Icon(Icons.delete, size: 16),
              label: const Text('删除'),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
            ),
          ),
      ],
    );
  }

  void _showGiftDetail(GameMail mail) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('🎁 礼包详情', style: TextStyle(color: Colors.white)),
        content: SizedBox(
          width: 300,
          height: 400,
          child: ListView.builder(
            itemCount: mail.attachments.length,
            itemBuilder: (context, index) {
              final att = mail.attachments[index];
              String name = '未知';
              String emoji = '📦';
              String subtitle = '';
              switch (att.type) {
                case MailAttachmentType.item:
                  final item = ShopDatabase.getById(att.itemId ?? '');
                  if (item != null) { name = item.name; emoji = item.emoji; subtitle = '×${att.count}'; }
                  break;
                case MailAttachmentType.meso:
                  name = '金币'; emoji = '💰'; subtitle = '${att.meso}';
                  break;
                case MailAttachmentType.equipment:
                  final equip = EquipmentDatabase.getById(att.equipmentId ?? '');
                  if (equip != null) { name = equip.name; emoji = equip.emoji ?? '⚔️'; subtitle = equip.stats; }
                  break;
              }
              return Card(
                color: const Color(0xFF0F3460),
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Text(emoji, style: const TextStyle(fontSize: 24)),
                  title: Text(name, style: const TextStyle(color: Colors.white)),
                  subtitle: Text(subtitle, style: const TextStyle(color: Colors.amber, fontSize: 12)),
                ),
              );
            },
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('关闭'))],
      ),
    );
  }
}
