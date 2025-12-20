/// Mail Channel model for Odoo conversations
class MailChannel {
  final int id;
  final String name;
  final String channelType; // 'chat', 'channel', or 'group'
  final String public; // 'public', 'private', 'groups'
  final String? description;
  final List<int> membersPartnerIds;
  final List<int>? channelPartnerIds;
  final List<int>? groupIds;
  final List<int>? messageIds;
  final String? uuid; // For DM channels

  MailChannel({
    required this.id,
    required this.name,
    required this.channelType,
    this.public = 'private',
    this.description,
    this.membersPartnerIds = const [],
    this.channelPartnerIds,
    this.groupIds,
    this.messageIds,
    this.uuid,
  });

  factory MailChannel.fromJson(Map<String, dynamic> json) {
    // Handle both members_partner_ids and channel_partner_ids
    List<int>? membersIds;
    if (json['members_partner_ids'] != null) {
      membersIds = (json['members_partner_ids'] as List<dynamic>?)
          ?.map((e) => e as int)
          .toList();
    } else if (json['channel_partner_ids'] != null) {
      // channel_partner_ids might be tuples [(id, name), ...]
      final channelPartners = json['channel_partner_ids'] as List<dynamic>?;
      if (channelPartners != null && channelPartners.isNotEmpty) {
        membersIds = channelPartners.map((e) {
          if (e is List && e.isNotEmpty) {
            return e[0] as int; // Extract ID from tuple
          }
          return e as int;
        }).toList();
      }
    }

    // Handle description which might be false from Odoo
    String? description;
    final descValue = json['description'];
    if (descValue != null && descValue is String) {
      description = descValue;
    }

    return MailChannel(
      id: json['id'] as int,
      name: json['name'] as String,
      channelType: json['channel_type'] as String,
      public: json['public'] as String? ?? 'private',
      description: description,
      membersPartnerIds: membersIds ?? [],
      channelPartnerIds: membersIds,
      groupIds: (json['group_ids'] as List<dynamic>?)
          ?.map((e) => e as int)
          .toList(),
      messageIds: (json['message_ids'] as List<dynamic>?)
          ?.map((e) => e as int)
          .toList(),
      uuid: json['uuid'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'channel_type': channelType,
      'public': public,
      'description': description,
      'members_partner_ids': membersPartnerIds,
      'channel_partner_ids': channelPartnerIds ?? membersPartnerIds,
      'group_ids': groupIds,
      'message_ids': messageIds,
      'uuid': uuid,
    };
  }

  bool get isDirectMessage => channelType == 'chat';
  bool get isChannel => channelType == 'channel';
  bool get isGroup => channelType == 'group';
  bool get isPublic => public == 'public';
  bool get isPrivate => public == 'private';
}
