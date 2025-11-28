import 'dart:convert';
import 'dart:developer';

import 'package:chat_system/models/chat_model.dart';
import 'package:chat_system/models/message_model.dart';
import 'package:chat_system/service/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  String get currentUserId => _authService.currentUser?.uid ?? '';

  // create or get chat room between two users

  Future<String> getOrCreateChatId(String userId, String otherUserId) async {
    List<String> uids = [userId, otherUserId];
    uids.sort();
    String chatId = uids.join('_');

    final chatRef = _firestore.collection('chats').doc(chatId);
    final docSnapshot = await chatRef.get();

    // check if chat already exists
    if (!docSnapshot.exists) {
      await chatRef.set({
        'users': [userId, otherUserId],
        'lastMessage': '',
        'lastMessageTime': Timestamp.now(),
        'unreadCount': {userId: 0, otherUserId: 0},
        'deletedForUsers': [],
        'deletedTimeStamp': {},
      });
    }

    return chatId;
  }

  // Send message
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String message,
    required String receiverId,
  }) async {
    final messageRef =
        _firestore.collection('chats').doc(chatId).collection('messages').doc();

    final Timestamp timestamp = Timestamp.now();

    // Add message
    await messageRef.set({
      'senderId': senderId,
      'receiverId': receiverId,
      'message': message,
      'timestamp': timestamp,
      'isRead': false,
    });

    // Update chat last message and read count
    final chatDoc = _firestore.collection('chats').doc(chatId);

    //  Check if receiver has deleted this chat
    final chatSnapshot = await chatDoc.get();
    final chatData = chatSnapshot.data();

    Map<String, dynamic> updateData = {
      'lastMessage': message,
      'lastMessageTime': timestamp,
      'unreadCount.$receiverId': FieldValue.increment(1),
    };

    // If receiver had deleted the chat, restore it by removing them from deletedForUsers
    if (chatData != null) {
      List<String> deletedForUsers = List<String>.from(
        chatData['deletedForUsers'] ?? [],
      );
      if (deletedForUsers.contains(receiverId)) {
        // Remove receiver from deletedForUsers to restore chat
        updateData['deletedForUsers'] = FieldValue.arrayRemove([receiverId]);

        updateData['deletedTimeStamp.$receiverId'] = timestamp;
        log(' Chat restored for receiver: $receiverId');
      }
    }

    await chatDoc.update(updateData);
  }
  // get Chat message through Stream

  Stream<List<MessageModel>> getMessages(String chatId, String userId) {
    return _firestore.collection('chats').doc(chatId).snapshots().asyncExpand((
      chatDoc,
    ) {
      final chatData = chatDoc.data();
      DateTime? deleteTime;

      // Get delete timestamp for current user
      if (chatData != null &&
          chatData['deletedTimeStamp'] != null &&
          chatData['deletedTimeStamp'][userId] != null) {
        deleteTime =
            (chatData['deletedTimeStamp'][userId] as Timestamp).toDate();
      }

      // Now get messages
      return _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs
                .map((doc) => MessageModel.fromMap(doc.data(), doc.id))
                .where((message) {
                  // If user has deleted chat, only show messages after delete time
                  if (deleteTime != null) {
                    return message.timestamp.millisecondsSinceEpoch >=
                        deleteTime.millisecondsSinceEpoch;
                  }
                  return true;
                })
                .toList();
          });
    });
  }

  //Reset Unread count for a user

  Future<void> resetUnreadCount(String chatId, String userid) async {
    final chatDoc = _firestore.collection('chats').doc(chatId);
    await chatDoc.update({'unreadCount.$userid': 0});
  }

  /// Get all chats for a user
  Stream<List<ChatModel>> getUserChats(String userId) {
    log("getting user chats");
    return _firestore
        .collection('chats')
        .where('users', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) {
          log(" Raw documents: ${snapshot.docs.length}");

          try {
            final chats =
                snapshot.docs
                    .map((doc) => ChatModel.fromMap(doc.data(), doc.id))
                    //  .where((chat) => chat.shouldShowOnHomeScreen(userId))
                    .toList();

            log(" Filtered chats: ${chats.length}");
            return chats;
          } catch (e) {
            log(" ERROR in filter: $e");
            log(" StackTrace: ${StackTrace.current}");
            return [];
          }
        });
  }

  Future<void> markMessagesRead(String chatId, String userId) async {
    final messagesRef = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages');

    // Get all unread messages sent to  user
    final query =
        await messagesRef
            .where('receiverId', isEqualTo: userId)
            .where('isRead', isEqualTo: false)
            .get();

    // Update each message to isRead = true
    for (var doc in query.docs) {
      await doc.reference.update({'isRead': true});
    }
  }

  Future<void> markAllMessagesAsRead(String chatId, String userId) async {
    try {
      // Get all unread messages from other users
      final querySnapshot =
          await _firestore
              .collection('chats')
              .doc(chatId)
              .collection('messages')
              .where('isRead', isEqualTo: false)
              .where('senderId', isNotEqualTo: userId)
              .get();

      // Batch update all to read
      final batch = _firestore.batch();
      for (final doc in querySnapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
      print(
        " Marked ${querySnapshot.docs.length} messages as read in Firestore",
      );
    } catch (e) {
      print(" Error in markAllMessagesAsRead: $e");
      throw e;
    }
  }

  // Delete chat for specific User

  Future<void> deletedChatForUser(String chatID, String userId) async {
    try {
      await _firestore.collection('chats').doc(chatID).update({
        'deletedForUsers': FieldValue.arrayUnion([userId]),
        'deletedTimeStamp.$userId': FieldValue.serverTimestamp(),
      });
      log(' Chat deleted for user: $userId');
    } catch (e) {
      log(' Error deleting chat: $e');
    }
  }

  // Get only active chats
  Stream<List<ChatModel>> getOnlyActiveChats(String userID) {
    log(" getOnlyActiveChats called for user:");
    return _firestore
        .collection('chats')
        .where('users', arrayContains: userID)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => ChatModel.fromMap(doc.data(), doc.id))
                  .where((chat) => !chat.isDeletedForUser(userID))
                  .toList(),
        );
  }

  // check if any any chat exist between users(even deleted )
  Future<String?> getAnyChatsBetweenUsers(String user1, String user2) async {
    final snapshot =
        await _firestore
            .collection('chats')
            .where('users', arrayContainsAny: [user1, user2])
            .get();

    for (final doc in snapshot.docs) {
      final chat = ChatModel.fromMap(doc.data(), doc.id);
      if (chat.users.contains(user1) && chat.users.contains(user2)) {
        return chat.id;
      }
    }
    return null;
  }

  // create new caht with unique ID
  Future<String?> createNewChat(String userID, String otherUserId) async {
    List<String> uids = [userID, otherUserId];
    uids.sort();

    //unique chat id with new  timeStamp
    String chatID =
        '${uids.join('_')}_${DateTime.now().millisecondsSinceEpoch}';
    final chatRef = _firestore.collection('chats').doc(chatID);

    await chatRef.set({
      'users': [userID, otherUserId],
      'lastMessage': '',
      'lastMessageTime': Timestamp.now(),
      'deletedForUsers': [],
    });
    return chatID;
  }
}
