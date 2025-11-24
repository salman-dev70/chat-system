import 'dart:async';

import 'package:chat_system/controller/users_controller.dart';
import 'package:chat_system/models/message_model.dart';
import 'package:chat_system/models/user_model.dart';
import 'package:chat_system/repository/chat_repo.dart';
import 'package:get/get.dart';

class ChatController extends GetxController {
  final ChatRepo _chatRepo;
  final UserController userController;
  ChatController(this._chatRepo, this.userController);

  RxString currentChatId = ''.obs;
  RxList messages = <MessageModel>[].obs;

  RxInt unreadCount = 0.obs;
  Rx<UserModel?> otherUser = Rx<UserModel?>(null);
  StreamSubscription? _messagesSub;

  // initiaize chat with slected chat Id
  void initChat(String chatId) {
    currentChatId.value = chatId;
    _listenMessages();
  }

  void _listenMessages() {
    if (currentChatId.value.isEmpty) return;

    _chatRepo.getMessages(currentChatId.value).listen((msgs) {
      messages.value = msgs;

      // Update unread count: messages not read by current user
      unreadCount.value =
          msgs
              .where(
                (msg) => !msg.isRead && msg.senderId != _chatRepo.currentUserId,
              )
              .length;
    });
  }

  /// Create or get chat and initialize messages
  Future<void> createOrGetChat({required UserModel otherUser}) async {
    final currentUser = userController.currentUser.value;
    if (currentUser == null) {
      print("Current user not loaded yet");
      return;
    }

    final currentUserId = currentUser.uid;
    this.otherUser.value = otherUser;

    // Get or create chatId
    currentChatId.value =
        (await _chatRepo.getOrCreateChatId(currentUserId, otherUser.uid))!;

    // Cancel previous listener if exists
    _messagesSub?.cancel();

    _messagesSub = _chatRepo.getMessages(currentChatId.value).listen((msgs) {
      messages.value = msgs;

      // Update unread count
      unreadCount.value =
          msgs
              .where((msg) => !msg.isRead && msg.senderId != currentUserId)
              .length;

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

  @override
  void onClose() {
    // TODO: implement onClose
    super.onClose();
    _messagesSub?.cancel();
  }
}
