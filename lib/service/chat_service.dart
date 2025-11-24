import 'package:chat_system/models/chat_model.dart';
import 'package:chat_system/models/message_model.dart';
import 'package:chat_system/service/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  String get currentUserId => _authService.currentUser?.uid ?? '';

  // create or get chat room between two users

  Future<String?> getOrCreateChatId(String userId, String otherUserId) async {
    final chatRef = _firestore.collection('chats');

    // Check if chat already exists
    final querySnapshot =
        await chatRef.where('participants', arrayContains: userId).get();
    for (var doc in querySnapshot.docs) {
      final users = List<String>.from(doc['users']);
      if (users.contains(otherUserId)) {
        return doc.id;
      }
    }

    // Create new chat if not exists
    final newChatDoc = await chatRef.doc();
    await newChatDoc.set({
      'users': [userId, otherUserId],
      'lastMessage': '',
      'lastMessageTime': DateTime.now(),
      'unreadCount': {userId: 0, otherUserId: 0},
    });
    return newChatDoc.id;
  }

  // Send message

  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String message,
    required String receiverId,
  }) async {
    final messageRef =
        _firestore
            .collection('chats')
            .doc('chatId')
            .collection('messages')
            .doc();

    final Timestamp timestamp = Timestamp.now();

    //Add messsage
    await messageRef.set({
      'senderId': senderId,
      'receiverId': receiverId,
      'message': message,
      'timestamp': timestamp,
    });

    // update chat last mesasge and read count
    final chatDoc = _firestore.collection('chats').doc(chatId);
    await chatDoc.update({
      'lastMessage': message,
      'lastMessageTime': timestamp,
      'unreadCount.$receiverId': FieldValue.increment(1),
    });
  }
  // get Chat message through Stream

  Stream<List<MessageModel>> getMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => MessageModel.fromMap(doc.data(), doc.id))
                  .toList(),
        );
  }

  //Reset Unread count for a user

  Future<void> resetUnreadCount(String chatId, String userid) async {
    final chatDoc = _firestore.collection('chats').doc(chatId);
    await chatDoc.update({'unreadCount.$userid': 0});
  }

  /// Get all chats for a user
  Stream<List<ChatModel>> getUserChats(String userId) {
    return _firestore
        .collection('chats')
        .where('users', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => ChatModel.fromMap(doc.data(), doc.id))
                  .toList(),
        );
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
}
