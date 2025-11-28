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
  final RxSet<String> _openChats = <String>{}.obs;

  ///
  final Map<String, StreamSubscription> _messageSubscriptions = {};

  // Track loading state
  RxBool isLoading = false.obs;
  RxBool hasInitialized = false.obs;
  RxList<ChatModel> activeChats = <ChatModel>[].obs;

  AllChatsController(this._chatRepo);

  @override
  void onInit() {
    super.onInit();
  }

  void initializeChats() {
    if (hasInitialized.value) return;

    if (_chatRepo.currentUserId.isEmpty) {
      log(" User ID not available for chats initialization");
      return;
    }

    hasInitialized.value = true;
    listenAllUserChats();
  }

  void markChatAsOpen(String chatId) {
    _openChats.add(chatId);
    unreadCounts[chatId] = 0;
    update();
    log(" Chat $chatId marked as open - Unread count reset to 0");
  }

  void markChatAsClosed(String chatId) {
    _openChats.remove(chatId);

    unreadCounts[chatId] = 0;
    update();
    log(" Chat $chatId marked as closed - Unread count: 0");
  }

  int getUnreadCount(String chatId) {
    return unreadCounts[chatId] ?? 0;
  }

  void listenAllUserChats() {
    log(" Loading all user chats: ${_chatRepo.currentUserId}");
    isLoading.value = true;

    _chatRepo
        .getOnlyActiveChats(_chatRepo.currentUserId)
        .listen(
          (chats) {
            allChats.value = chats;
            isLoading.value = false;
            log(" Chats loaded: ${chats.length} chats found");

            if (chats.isEmpty) {
              log(" NO CHATS FOUND - Cannot start message listeners");
              return;
            }

            //   Show each chat
            for (int i = 0; i < chats.length; i++) {
              log(" Chat $i: ${chats[i].id} | Users: ${chats[i].users}");
            }

            //  FORCE RESTART ALL MESSAGE LISTENERS
            log(" FORCE RESTARTING all message listeners");

            // Cancel all existing subscriptions
            _messageSubscriptions.forEach((chatId, subscription) {
              subscription.cancel();
              log(" Cancelled existing subscription for: $chatId");
            });
            _messageSubscriptions.clear();

            // Start fresh listeners for all chats
            int listenersStarted = 0;
            for (var chat in chats) {
              log(" STARTING message listener for: ${chat.id}");
              _listenChatMessages(chat.id, chat);
              listenersStarted++;
            }

            log(" Total message listeners started: $listenersStarted");

            // Check after delay
            Future.delayed(Duration(seconds: 3), () {
              log(
                " After 3 seconds - Active subscriptions: ${_messageSubscriptions.length}",
              );
              log(" UnreadCounts: $unreadCounts");
            });
          },
          onError: (error) {
            isLoading.value = false;
            log(" Error loading chats: $error");
          },
        );
  }

  void _listenChatMessages(String chatId, ChatModel chat) {
    log(" _listenChatMessages ENTERED for: $chatId");

    try {
      log(" Calling _chatRepo.getMessages($chatId)");

      _messageSubscriptions[chatId] = _chatRepo
          .getMessages(chatId, _chatRepo.currentUserId)
          .listen(
            (messages) {
              log(
                " MESSAGES RECEIVED for $chatId: ${messages.length} messages",
              );

              Future.microtask(() {
                //  FIX: Filter messages based on deletedTimeStamp
                final deleteTime = chat.getDeleteTimeForUser(
                  _chatRepo.currentUserId,
                );

                List<MessageModel> filteredMessages = messages;

                if (deleteTime != null) {
                  filteredMessages =
                      messages
                          .where((msg) => msg.timestamp.isAfter(deleteTime))
                          .toList();
                  log(
                    " Filtered messages for $chatId: ${filteredMessages.length}/${messages.length}",
                  );
                }

                if (_openChats.contains(chatId)) {
                  log(" Chat $chatId OPEN - Unread: 0");
                  lastMessages[chatId] =
                      filteredMessages.isNotEmpty
                          ? filteredMessages.first
                          : null;
                  unreadCounts[chatId] = 0;
                  return;
                }

                if (filteredMessages.isNotEmpty) {
                  lastMessages[chatId] = filteredMessages.first;

                  int actualUnread =
                      filteredMessages
                          .where(
                            (msg) =>
                                !msg.isRead &&
                                msg.senderId != _chatRepo.currentUserId,
                          )
                          .length;
                  unreadCounts[chatId] = actualUnread;
                  update();
                  log(" Unread count for $chatId: $actualUnread");
                } else {
                  //  No messages after filtering - show empty state
                  lastMessages[chatId] = null;
                  unreadCounts[chatId] = 0;
                  log(" No messages for $chatId after filtering");
                }
                update();
              });
            },
            onError: (error) {
              log(" STREAM ERROR for $chatId: $error");
            },
            cancelOnError: false,
          );

      log(" Subscription CREATED for $chatId");
    } catch (e) {
      log(" EXCEPTION in _listenChatMessages: $e");
    }
  }

  /// Listen messages for a specific chat to get last message & unread count

  // void _listenChatMessages(String chatId,ChatModel chat) {
  //   log(" _listenChatMessages ENTERED for: $chatId");

  //   try {
  //     log(" Calling _chatRepo.getMessages($chatId)");

  //     _messageSubscriptions[chatId] = _chatRepo
  //         .getMessages(chatId, _chatRepo.currentUserId)
  //         .listen(
  //           (messages) {
  //             log(
  //               " MESSAGES RECEIVED for $chatId: ${messages.length} messages",
  //             );

  //             Future.microtask(() {
  //               if (_openChats.contains(chatId)) {
  //                 log(" Chat $chatId OPEN - Unread: 0");
  //                 lastMessages[chatId] =
  //                     messages.isNotEmpty ? messages.first : null;
  //                 unreadCounts[chatId] = 0;
  //                 return;
  //               }

  //               if (messages.isNotEmpty) {
  //                 lastMessages[chatId] = messages.first;
  //                 int currentUnread = unreadCounts[chatId] ?? 0;
  //                 int actualUnread =
  //                     messages
  //                         .where(
  //                           (msg) =>
  //                               !msg.isRead &&
  //                               msg.senderId != _chatRepo.currentUserId,
  //                         )
  //                         .length;
  //                 if (actualUnread > currentUnread) {
  //                   unreadCounts[chatId] = actualUnread;
  //                   log(" New message - Unread: $actualUnread");
  //                 }
  //               } else {
  //                 lastMessages[chatId] = null;
  //                 unreadCounts[chatId] = 0;
  //                 log(" No messages for $chatId");
  //               }
  //             });
  //           },
  //           onError: (error) {
  //             log(" STREAM ERROR for $chatId: $error");
  //           },
  //           cancelOnError: false,
  //         );

  //     log(" Subscription CREATED for $chatId");
  //   } catch (e) {
  //     log(" EXCEPTION in _listenChatMessages: $e");
  //   }
  // }

  void resetForNewUser() {
    log(" RESETTING AllChatsController for new user");

    // Cancel all subscriptions
    _messageSubscriptions.forEach((chatId, subscription) {
      subscription.cancel();
    });
    _messageSubscriptions.clear();

    // Clear all data
    allChats.clear();
    lastMessages.clear();
    unreadCounts.clear();
    _openChats.clear();

    // Reset flags
    isLoading.value = false;
    hasInitialized.value = false;

    log(" AllChatsController reset complete");
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
