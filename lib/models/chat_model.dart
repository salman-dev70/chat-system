import 'package:chat_system/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  final String id;
  final List<String> users;
  final String lastMessage;
  final DateTime lastMessageTime;
  final Map<String, int> unreadCount;
  UserModel? otherUser;
  final List<String> deletedForUsers;

  ChatModel({
    required this.id,
    required this.users,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unreadCount,
    this.deletedForUsers = const [],
  });

  factory ChatModel.fromMap(Map<String, dynamic> map, String id) => ChatModel(
    id: id,
    users: List<String>.from(map['users'] ?? []),
    lastMessage: map['lastMessage'] ?? '',
    lastMessageTime:
        map['lastMessageTime'] != null
            ? (map['lastMessageTime'] as Timestamp).toDate()
            : DateTime.now(),
    unreadCount: Map<String, int>.from(map['unreadCount'] ?? {}),
    deletedForUsers: List<String>.from(map['deletedForUsers'] ?? []),
  );

  Map<String, dynamic> toMap() => {
    'users': users,
    'lastMessage': lastMessage,
    'lastMessageTime': lastMessageTime,
    'unreadCount': unreadCount,
    'deletedForUsers': deletedForUsers,
  };

  bool isDeletedForUser(String userId) {
    return deletedForUsers.contains(userId);
  }

  String getOtherUserId(String currentUserId) {
    try {
      return users.firstWhere((uid) => uid != currentUserId);
    } catch (e) {
      return '';
    }
  }

  int getUnreadCountForUser(String userId) {
    return unreadCount[userId] ?? 0;
  }
}
