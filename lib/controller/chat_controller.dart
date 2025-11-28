import 'dart:async';
import 'dart:developer';

import 'package:chat_system/controller/all_chats_controller.dart';
import 'package:chat_system/controller/users_controller.dart';
import 'package:chat_system/models/chat_model.dart';
import 'package:chat_system/models/message_model.dart';
import 'package:chat_system/models/user_model.dart';
import 'package:chat_system/repository/chat_repo.dart';
import 'package:get/get.dart';

class ChatController extends GetxController {
  final ChatRepo _chatRepo;
  final UserController userController;
  ChatController(this._chatRepo, this.userController);

  RxString currentChatId = ''.obs;
  RxList<MessageModel> messages = <MessageModel>[].obs;

  RxInt unreadCount = 0.obs;
  Rx<UserModel?> otherUser = Rx<UserModel?>(null);
  StreamSubscription? _messagesSub;

  RxList<ChatModel> activeChats = <ChatModel>[].obs;

  // initiaize chat with slected chat Id
  void initChat(String chatId) {
    currentChatId.value = chatId;
    _listenMessages();
    markAllMessagesAsRead(chatId);
    _chatRepo.markMessagesRead(chatId, _chatRepo.currentUserId);
  }

  void _listenMessages() {
    if (currentChatId.value.isEmpty) return;

    _chatRepo.getMessages(currentChatId.value, _chatRepo.currentUserId).listen((
      allMessages,
    ) {
      //  GET CURRENT CHAT DETAILS FOR FILTERING
      messages.value = allMessages;

      // Update unread count
      unreadCount.value =
          messages
              .where(
                (msg) => !msg.isRead && msg.senderId != _chatRepo.currentUserId,
              )
              .length;
    });
  }

  // // get Filtered Messages
  // List<MessageModel> _getFilteredMessages(
  //   List<MessageModel> allMessages,
  //   ChatModel chat,
  //   String userId,
  // ) {
  //   // Agar chat delete nahi ki, toh saare messages dikhao
  //   if (!chat.isDeletedForUser(userId)) {
  //     return allMessages;
  //   }

  //   // Delete time get karein
  //   final deleteTime = chat.getDeleteTimeForUser(userId);
  //   if (deleteTime == null) {
  //     return allMessages; // Agar delete time nahi hai, toh saare messages
  //   }

  //   // Sirf delete time ke baad wale messages dikhao
  //   return allMessages
  //       .where((message) => message.timestamp.isAfter(deleteTime))
  //       .toList();
  // }

  /// Create or get chat and initialize messages
  Future<void> createOrGetChat({required UserModel otherUser}) async {
    log('create or get chat called');
    final currentUser = userController.currentUser.value;
    if (currentUser == null) {
      print("Current user not loaded yet");
      return;
    }

    final currentUserId = _chatRepo.currentUserId;

    this.otherUser.value = otherUser;

    log(otherUser.uid);

    currentChatId.value = (await _chatRepo.getOrCreateChatId(
      currentUserId,
      otherUser.uid,
    ));

    log('create chat id');

    _messagesSub?.cancel();

    _messagesSub = _chatRepo
        .getMessages(currentChatId.value, _chatRepo.currentUserId)
        .listen((msgs) {
          messages.value = msgs;
          log('get messages');

          // Update unread count
          unreadCount.value =
              msgs
                  .where((msg) => !msg.isRead && msg.senderId != currentUserId)
                  .length;
          markAllMessagesAsRead(currentChatId.value);
          // Reset unread count in DB
          _chatRepo.resetUnreadCount(currentChatId.value, currentUserId);
        });
  }

  Future<void> sendMessage(String text, String receiverId) async {
    if (currentChatId.value.isEmpty) return;

    try {
      await _chatRepo.sendMessage(
        chatId: currentChatId.value,
        senderId: _chatRepo.currentUserId,
        receiverId: receiverId,
        message: text,
      );
    } catch (e) {
      Get.snackbar('Error', 'Message not sent');
    }
  }

  /// Mark all messages as read for current user
  Future<void> markMessagesRead() async {
    if (currentChatId.value.isEmpty) return;

    await _chatRepo.markMessagesRead(
      currentChatId.value,
      _chatRepo.currentUserId,
    );
    unreadCount.value = 0;
  }

  Future<void> markAllMessagesAsRead(String chatId) async {
    try {
      await _chatRepo.markAllMessagesAsRead(chatId, _chatRepo.currentUserId);
      log(" All messages marked as READ in Firestore for chat: $chatId");
    } catch (e) {
      log(" Error marking all messages as read: $e");
    }
  }

  //delete chat for current user
  Future<void> deletedChatForUser(String chatID) async {
    try {
      await _chatRepo.deletedChatForUser(chatID, _chatRepo.currentUserId);

      log(" Chat deleted for current user: $chatID");
    } catch (e) {
      log(" Error deleting chat for user: $e");
    }
  }

  // get activechat between user
  Stream<List<ChatModel>> getActiveChatStream() {
    final currentUserId = _chatRepo.currentUserId;
    return _chatRepo.getOnlyActiveChats(currentUserId);
  }

  // check if any chat exist between user
  Future<String?> checkExistingChat(String otherUserId) async {
    final currentUserId = _chatRepo.currentUserId;
    return await _chatRepo.getAnyChatsBetweenUsers(currentUserId, otherUserId);
  }

  //create fresh new chat between users
  Future<String?> createFreshChat(String otherUserId) async {
    final currentUserId = _chatRepo.currentUserId;
    return await _chatRepo.createNewChat(currentUserId, otherUserId);
  }

  @override
  void onClose() {
    // TODO: implement onClose
    super.onClose();
    _messagesSub?.cancel();
  }
}
