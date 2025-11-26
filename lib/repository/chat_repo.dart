import 'dart:developer';

import 'package:chat_system/models/chat_model.dart';
import 'package:chat_system/models/message_model.dart';
import 'package:chat_system/service/chat_service.dart';

class ChatRepo {
  final ChatService _chatService;
  ChatRepo(this._chatService);

  String get currentUserId => _chatService.currentUserId;

  // create or get chat room between two users
  Future<String> getOrCreateChatId(String userId, String otherUserId) async {
    try {
      log('Getting or creating chat ID for $userId and $otherUserId');
      return await _chatService.getOrCreateChatId(userId, otherUserId);
    } catch (e) {
      log('Error in getOrCreateChatId: $e', level: 1000);
      throw Exception('Failed to get or create chat ID: $e');
    }
  }

  // send message

  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String message,
    required String receiverId,
  }) async {
    try {
      await _chatService.sendMessage(
        chatId: chatId,
        senderId: senderId,
        message: message,
        receiverId: receiverId,
      );
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  // get messages stream
  Stream<List<MessageModel>> getMessages(String chatId) {
    log(" ChatRepo.getMessages called for: $chatId");
    try {
      return _chatService.getMessages(chatId);
    } catch (e) {
      log(" Error in ChatRepo.getMessages: $e");
      throw Exception('Failed to get messages: $e');
    }
  }

  // reset unread count
  Future<void> resetUnreadCount(String chatId, String userId) {
    try {
      return _chatService.resetUnreadCount(chatId, userId);
    } catch (e) {
      throw Exception('Failed to reset unread count: $e');
    }
  }

  /// Get all chats for user stream
  Stream<List<ChatModel>> getUserChats(String userId) {
    try {
      return _chatService.getUserChats(userId);
    } catch (e) {
      throw Exception('Failed to get user chats: $e');
    }
  }

  Future<void> markMessagesRead(String chatId, String userId) {
    return _chatService.markMessagesRead(chatId, userId);
  }

  Future<void> markAllMessagesAsRead(String chatId, String userId) async {
    try {
      await _chatService.markAllMessagesAsRead(chatId, userId);
    } catch (e) {
      throw Exception('Failed to mark all messages as read: $e');
    }
  }
}
