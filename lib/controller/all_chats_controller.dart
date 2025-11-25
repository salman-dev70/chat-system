import 'dart:async';
import 'dart:developer';

import 'package:chat_system/repository/chat_repo.dart';
import 'package:get/get.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';

class AllChatsController extends GetxController {
  final ChatRepo _chatRepo;

  // List of all chats for current user
  RxList<ChatModel> allChats = <ChatModel>[].obs;

  // Map to track last message for each chat
  RxMap<String, MessageModel?> lastMessages = <String, MessageModel?>{}.obs;

  // Map to track unread messages count per chat
  RxMap<String, int> unreadCounts = <String, int>{}.obs;

  ///
  final Map<String, StreamSubscription> _messageSubscriptions = {};

  // Track loading state
  RxBool isLoading = false.obs;
  RxBool hasInitialized = false.obs;

  AllChatsController(this._chatRepo);

  @override
  void onInit() {
    super.onInit();
  }

  void initializeChats() {
    if (hasInitialized.value) return; // Already initialized

    if (_chatRepo.currentUserId.isEmpty) {
      log(" User ID not available for chats initialization");
      return;
    }

    hasInitialized.value = true;
    listenAllUserChats();
  }

  void listenAllUserChats() {
    log(" Loading all user chats: ${_chatRepo.currentUserId}");
    isLoading.value = true;

    _chatRepo
        .getUserChats(_chatRepo.currentUserId)
        .listen(
          (chats) {
            allChats.value = chats;
            isLoading.value = false;
            log(" Chats loaded: ${chats.length} chats found");

            // Ensure we only subscribe to new chats
            for (var chat in chats) {
              if (!_messageSubscriptions.containsKey(chat.id)) {
                _listenChatMessages(chat.id);
              }
            }

            // Unsubscribe from chats that were deleted
            List<String> currentChatIds = chats.map((c) => c.id).toList();
            _messageSubscriptions.keys.toList().forEach((chatId) {
              if (!currentChatIds.contains(chatId)) {
                _messageSubscriptions[chatId]?.cancel();
                _messageSubscriptions.remove(chatId);
                lastMessages.remove(chatId);
                unreadCounts.remove(chatId);
              }
            });
          },
          onError: (error) {
            isLoading.value = false;
            log(" Error loading chats: $error");
          },
        );
  }

  /// Listen messages for a specific chat to get last message & unread count
  void _listenChatMessages(String chatId) {
    _messageSubscriptions[chatId] = _chatRepo.getMessages(chatId).listen((
      messages,
    ) {
      if (messages.isNotEmpty) {
        lastMessages[chatId] = messages.first;
        unreadCounts[chatId] =
            messages
                .where(
                  (msg) =>
                      !msg.isRead && msg.senderId != _chatRepo.currentUserId,
                )
                .length;
        log("Updated unread count for $chatId: ${unreadCounts[chatId]}");
      } else {
        lastMessages[chatId] = null;
        unreadCounts[chatId] = 0;
      }
    });
  }

  @override
  void onClose() {
    // Cleanup all subscriptions
    _messageSubscriptions.forEach((chatId, subscription) {
      subscription.cancel();
    });
    _messageSubscriptions.clear();
    super.onClose();
  }
}
