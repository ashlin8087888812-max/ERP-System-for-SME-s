import 'package:equatable/equatable.dart';

enum ChannelType { chat, channel, group }

class ThreadMember extends Equatable {
  final int id;
  final int partnerId;
  final String name;
  final String? avatarUrl;
  final bool isSelf;
  final int? lastSeenId;
  final int unreadCount;

  const ThreadMember({
    required this.id,
    required this.partnerId,
    required this.name,
    this.avatarUrl,
    this.isSelf = false,
    this.lastSeenId,
    this.unreadCount = 0,
  });

  factory ThreadMember.fromJson(Map<String, dynamic> json) {
    return ThreadMember(
      id: json['id'],
      partnerId: json['partner_id'],
      name: json['name'],
      avatarUrl: json['avatar_url'],
      isSelf: json['is_self'] ?? false,
      lastSeenId: json['last_seen_id'],
      unreadCount: json['unread_count'] ?? 0,
    );
  }

  @override
  List<Object?> get props => [id, partnerId, name, isSelf, lastSeenId, unreadCount];
}

class Thread extends Equatable {
  final int id;
  final String name;
  final ChannelType type;
  final String? description;
  final String uuid;
  final bool isMember;
  final int memberCount;
  final int messageCount;
  final DateTime? lastActivity;
  final String? avatarUrl;
  final List<ThreadMember> members;
  final bool isVirtual;

  const Thread({
    required this.id,
    required this.name,
    required this.type,
    this.description,
    required this.uuid,
    this.isMember = false,
    this.memberCount = 0,
    this.messageCount = 0,
    this.lastActivity,
    this.avatarUrl,
    this.members = const [],
    this.isVirtual = false,
  });

  factory Thread.virtual(String id, String name, ChannelType type) {
    return Thread(
      id: id.hashCode, // Synthetic ID
      name: name,
      type: type,
      uuid: id,
      isVirtual: true,
    );
  }

  factory Thread.fromJson(Map<String, dynamic> json) {
    return Thread(
      id: json['id'],
      name: json['name'],
      type: _parseType(json['type']),
      description: json['description'],
      uuid: json['uuid'],
      isMember: json['is_member'] ?? false,
      memberCount: json['member_count'] ?? 0,
      messageCount: json['message_count'] ?? 0,
      lastActivity: json['last_activity'] != null 
          ? DateTime.parse(json['last_activity']) 
          : null,
      avatarUrl: json['avatar_url'],
      members: (json['members'] as List? ?? [])
          .map((m) => ThreadMember.fromJson(m))
          .toList(),
    );
  }

  static ChannelType _parseType(String type) {
    switch (type) {
      case 'chat': return ChannelType.chat;
      case 'group': return ChannelType.group;
      default: return ChannelType.channel;
    }
  }

  @override
  List<Object?> get props => [id, uuid, type, messageCount, lastActivity, members];
}

class ThreadMessage extends Equatable {
  final int id;
  final String content;
  final DateTime timestamp;
  final int senderId;
  final String senderName;
  final String? senderAvatar;
  final String type;
  final List<dynamic> attachments;
  final int? parentId;
  final bool isStarred;
  final int sequence; // Monotonic Ordering

  const ThreadMessage({
    required this.id,
    required this.content,
    required this.timestamp,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    this.type = 'comment',
    this.attachments = const [],
    this.parentId,
    this.isStarred = false,
    required this.sequence,
  });

  factory ThreadMessage.fromJson(Map<String, dynamic> json) {
    return ThreadMessage(
      id: json['id'],
      content: json['content'],
      timestamp: DateTime.parse(json['timestamp']),
      senderId: json['sender_id'],
      senderName: json['sender_name'],
      senderAvatar: json['sender_avatar'],
      type: json['type'] ?? 'comment',
      parentId: json['parent_id'],
      isStarred: json['is_starred'] ?? false,
      sequence: json['sequence'],
    );
  }

  @override
  List<Object?> get props => [id, sequence, content, timestamp, senderId, isStarred];
}
