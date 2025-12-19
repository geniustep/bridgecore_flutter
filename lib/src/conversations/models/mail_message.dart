/// Mail Message model for Odoo conversations
class MailMessage {
  final int id;
  final String? model;
  final int? resId;
  final String messageType;
  final int? subtypeId;
  final String? subject;
  final String? body;
  final int? authorId;
  final String? authorName;
  final List<int> partnerIds;
  final List<int> channelIds;
  final DateTime date;
  final int? parentId;
  final List<int> attachmentIds;
  final bool isInternal;

  MailMessage({
    required this.id,
    this.model,
    this.resId,
    required this.messageType,
    this.subtypeId,
    this.subject,
    this.body,
    this.authorId,
    this.authorName,
    this.partnerIds = const [],
    this.channelIds = const [],
    required this.date,
    this.parentId,
    this.attachmentIds = const [],
    this.isInternal = false,
  });

  factory MailMessage.fromJson(Map<String, dynamic> json) {
    return MailMessage(
      id: json['id'] as int,
      model: json['model'] as String?,
      resId: json['res_id'] as int?,
      messageType: json['message_type'] as String,
      subtypeId: json['subtype_id'] as int?,
      subject: json['subject'] as String?,
      body: json['body'] as String?,
      authorId: json['author_id'] as int?,
      authorName: json['author_name'] as String?,
      partnerIds: (json['partner_ids'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [],
      channelIds: (json['channel_ids'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [],
      date: json['date'] is String
          ? DateTime.parse(json['date'] as String)
          : json['date'] is int
              ? DateTime.fromMillisecondsSinceEpoch(json['date'] as int)
              : (json['date'] as DateTime? ?? DateTime.now()),
      parentId: json['parent_id'] as int?,
      attachmentIds: (json['attachment_ids'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [],
      isInternal: json['is_internal'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'model': model,
      'res_id': resId,
      'message_type': messageType,
      'subtype_id': subtypeId,
      'subject': subject,
      'body': body,
      'author_id': authorId,
      'author_name': authorName,
      'partner_ids': partnerIds,
      'channel_ids': channelIds,
      'date': date.toIso8601String(),
      'parent_id': parentId,
      'attachment_ids': attachmentIds,
      'is_internal': isInternal,
    };
  }
}
