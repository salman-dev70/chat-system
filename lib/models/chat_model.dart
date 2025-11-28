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
  final Map<String, dynamic> deletedTimeStamp;

  ChatModel({
    required this.id,
    required this.users,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unreadCount,
    this.deletedForUsers = const [],
    this.deletedTimeStamp = const {},
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
    deletedTimeStamp: Map<String, dynamic>.from(map['deletedTimeStamp'] ?? {}),
  );

  Map<String, dynamic> toMap() => {
    'users': users,
    'lastMessage': lastMessage,
    'lastMessageTime': lastMessageTime,
    'unreadCount': unreadCount,
    'deletedForUsers': deletedForUsers,
    'deletedTimeStamp': deletedTimeStamp,
  };

  bool isDeletedForUser(String userId) {
    return deletedForUsers.contains(userId);
  }

  // get deletedTime for User

  DateTime? getDeleteTimeForUser(String userId) {
    if (deletedTimeStamp.containsKey(userId)) {
      final timestamp = deletedTimeStamp[userId];
      if (timestamp is Timestamp) {
        return timestamp.toDate();
      }
    }
    return null;
  }

  // Check time for Home screen

  bool shouldShowOnHomeScreen(String userId) {
    if (!isDeletedForUser(userId)) return true;

    final deleteTime = getDeleteTimeForUser(userId);
    if (deleteTime == null) return false;

    return lastMessageTime.isAfter(deleteTime);
  }
}
