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

  AllChatsController(this._chatRepo);

  @override
  void onInit() {
    super.onInit();
    _listenAllUserChats();
  }

  /// Listen all chats for current user
  void _listenAllUserChats() {
    _chatRepo.getUserChats(_chatRepo.currentUserId).listen((chats) {
      allChats.value = chats;

      // For each chat, listen messages stream
      for (var chat in chats) {
        _listenChatMessages(chat.id);
      }
    });
  }

  /// Listen messages for a specific chat to get last message & unread count
  void _listenChatMessages(String chatId) {
    RxList<MessageModel> chatMessages = <MessageModel>[].obs;
    chatMessages.bindStream(_chatRepo.getMessages(chatId));

    chatMessages.listen((messages) {
      if (messages.isNotEmpty) {
        lastMessages[chatId] = messages.last;
        unreadCounts[chatId] =
            messages
                .where(
                  (msg) =>
                      !msg.isRead && msg.senderId != _chatRepo.currentUserId,
                )
                .length;
      } else {
        lastMessages[chatId] = null;
        unreadCounts[chatId] = 0;
      }
    });
  }
}
