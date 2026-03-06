import 'player.dart';

/// 邮件附件类型
enum MailAttachmentType {
  item,      // 物品
  meso,      // 金币
  equipment, // 装备
}

/// 邮件附件
class MailAttachment {
  final MailAttachmentType type;
  final String? itemId;      // 物品ID（物品类型）
  final String? equipmentId; // 装备类型ID（用于生成装备实例）
  final String? instanceId;  // 装备实例ID（装备类型）
  final int? count;          // 数量
  final int? meso;           // 金币数量

  MailAttachment({
    required this.type,
    this.itemId,
    this.equipmentId,
    this.instanceId,
    this.count,
    this.meso,
  });

  /// 创建物品附件
  factory MailAttachment.item(String itemId, int count) {
    return MailAttachment(
      type: MailAttachmentType.item,
      itemId: itemId,
      count: count,
    );
  }

  /// 创建金币附件
  factory MailAttachment.meso(int amount) {
    return MailAttachment(
      type: MailAttachmentType.meso,
      meso: amount,
    );
  }

  /// 创建装备附件（通过装备ID生成实例）
  factory MailAttachment.equipment(String equipmentId) {
    return MailAttachment(
      type: MailAttachmentType.equipment,
      equipmentId: equipmentId,
    );
  }
}

/// 游戏邮件
class GameMail {
  String id;                // 邮件唯一ID
  String title;             // 标题
  String content;           // 内容
  String sender;            // 发送者
  DateTime sentAt;          // 发送时间
  bool isRead;              // 是否已读
  bool isClaimed;           // 附件是否已领取
  List<MailAttachment> attachments; // 附件列表

  GameMail({
    required this.id,
    required this.title,
    required this.content,
    required this.sender,
    required this.sentAt,
    this.isRead = false,
    this.isClaimed = false,
    this.attachments = const [],
  });

  /// 检查是否有未领取的附件
  bool get hasUnclaimedAttachments => 
      attachments.isNotEmpty && !isClaimed;

  /// 标记为已读
  void markAsRead() {
    isRead = true;
  }

  /// 标记附件已领取
  void markAsClaimed() {
    isClaimed = true;
  }

  /// 复制邮件
  GameMail copyWith({
    String? id,
    String? title,
    String? content,
    String? sender,
    DateTime? sentAt,
    bool? isRead,
    bool? isClaimed,
    List<MailAttachment>? attachments,
  }) {
    return GameMail(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      sender: sender ?? this.sender,
      sentAt: sentAt ?? this.sentAt,
      isRead: isRead ?? this.isRead,
      isClaimed: isClaimed ?? this.isClaimed,
      attachments: attachments ?? this.attachments,
    );
  }
}

/// 邮件模板
class MailTemplates {
  /// 新手礼包邮件
  static GameMail newPlayerGift() {
    return GameMail(
      id: 'new_player_gift_${DateTime.now().millisecondsSinceEpoch}',
      title: '🎁 新手冒险家礼包',
      content: '''欢迎来到冒险岛文字版！

为了帮助你更好地开始冒险之旅，我们为你准备了新手礼包：

🎲 神奇魔方 × 100
🔷 高级神奇魔方 × 100
💎 超级神奇魔方 × 100

🎁 1级新手装备一套：
• 🪖 冒险家头盔
• 👕 冒险家铠甲
• 👖 冒险家护腿
• 👢 冒险家战靴
• 🧤 冒险家手套
• ⚔️ 冒险家之剑
• 🧣 冒险家披风

记得打开邮件领取附件！

祝你游戏愉快！''',
      sender: '冒险岛管理员',
      sentAt: DateTime.now(),
      attachments: [
        // 魔方
        MailAttachment.item('cube_normal', 100),
        MailAttachment.item('cube_advanced', 100),
        MailAttachment.item('cube_super', 100),
        // 1级装备
        MailAttachment.equipment('gift_lvl1_helmet'),
        MailAttachment.equipment('gift_lvl1_armor'),
        MailAttachment.equipment('gift_lvl1_pants'),
        MailAttachment.equipment('gift_lvl1_shoes'),
        MailAttachment.equipment('gift_lvl1_gloves'),
        MailAttachment.equipment('gift_lvl1_weapon'),
        MailAttachment.equipment('gift_lvl1_cape'),
      ],
    );
  }

  /// 欢迎邮件
  static GameMail welcomeMail() {
    return GameMail(
      id: 'welcome_${DateTime.now().millisecondsSinceEpoch}',
      title: '🌟 欢迎来到冒险岛',
      content: '''亲爱的冒险家：

欢迎加入冒险岛文字版！

在这里，你将：
• 🗡️ 击败各种怪物，收集战利品
• 📈 升级变强，转职成为战士、法师、弓箭手或飞侠
• 🎒 收集装备，提升战斗力
• 🎲 使用魔方洗练装备潜能
• 🗺️ 探索不同的地图

快捷键：
• 点击怪物即可开始战斗
• 打开背包使用药水
• 点击装备可以穿戴或强化

有任何问题都可以随时联系我们！

祝冒险愉快！''',
      sender: '冒险岛管理员',
      sentAt: DateTime.now(),
    );
  }
}
