import 'dart:async';
import 'dart:developer';

import 'package:chat_system/controller/auth_controller.dart';
import 'package:chat_system/models/message_model.dart';
import 'package:chat_system/utils/widgets/timeformat.dart';
import 'package:chat_system/utils/widgets/unread_badge_widget.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/all_chats_controller.dart';
import '../controller/chat_controller.dart';
import '../controller/users_controller.dart';
import '../models/chat_model.dart';
import '../models/user_model.dart';
import 'chat_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AllChatsController allChatsController = Get.find<AllChatsController>();

  final UserController userController = Get.find<UserController>();

  final ChatController chatController = Get.find<ChatController>();

  final AuthController authController = Get.find<AuthController>();

  Timer? _timer;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      allChatsController.initializeChats();
    });

    _timer = Timer.periodic(Duration(minutes: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _timer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    log(" Current User ID: ${userController.currentUserId}");
    log(" All Users Count: ${userController.allUsers.length}");
    log(" All Chats Count: ${allChatsController.allChats.length}");
    log(" HomeScreen - All unreadCounts: ${allChatsController.unreadCounts}");

    return DefaultTabController(
      length: 2, // Chats & Users
      child: Scaffold(
        appBar: AppBar(
          title: Text('Home'),
          actions: [
            IconButton(
              icon: Icon(Icons.logout, color: Colors.black),
              onPressed: () async {
                log("User logged out");
                await authController.signOut();
              },
            ),
          ],
          bottom: TabBar(tabs: [Tab(text: 'Chats'), Tab(text: 'Users')]),
        ),
        body: TabBarView(
          children: [
            // --------- Chats Tab ---------
            Obx(() {
              if (allChatsController.isLoading.value) {
                return Center(child: CircularProgressIndicator());
              }
              if (allChatsController.allChats.isEmpty) {
                return Center(child: Text('No chats yet'));
              }
              return ListView.builder(
                itemCount: allChatsController.allChats.length,
                itemBuilder: (context, index) {
                  ChatModel chat = allChatsController.allChats[index];

                  int? unreadCount = allChatsController.unreadCounts[chat.id];
                  log("Chat ${chat.id} - Unread: $unreadCount");

                  // Find the other user's ID
                  String otherUserId = chat.users.firstWhere(
                    (uid) => uid != userController.currentUser.value?.uid,
                  );

                  // Get the other user's info
                  UserModel? otherUser = userController.allUsers
                      .firstWhereOrNull((user) => user.uid == otherUserId);
                  MessageModel? lastMsg =
                      allChatsController.lastMessages[chat.id];

                  return Dismissible(
                    key: Key(chat.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: EdgeInsets.only(right: 20),
                      child: Icon(Icons.delete, color: Colors.white),
                    ),
                    confirmDismiss: (direction) async {
                      return await _showDeleteConfirmation(
                        chat.id,
                        otherUser?.name ?? 'User',
                      );
                    },
                    onDismissed: (direction) {
                      chatController.deletedChatForUser(chat.id);
                    },
                    child: ListTile(
                      leading: Stack(
                        children: [
                          CircleAvatar(
                            backgroundImage: NetworkImage(
                              otherUser?.image ?? '',
                            ),
                          ),
                          // Online Indicator
                          if (otherUser != null)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color:
                                      otherUser.isOnline
                                          ? Colors.green
                                          : Colors.grey,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      title: Text(otherUser?.name ?? 'Unknown'),
                      subtitle: Obx(() {
                        MessageModel? lastMsg =
                            allChatsController.lastMessages[chat.id];
                        if (lastMsg == null) {
                          return Text(chat.lastMessage);
                        }
                        return Text(lastMsg.message);
                      }),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            TimeUtils.formatMessageTime(
                              lastMsg?.timestamp ?? chat.lastMessageTime,
                            ),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),

                          UnreadBadge(chatId: chat.id),
                        ],
                      ),
                      onTap: () {
                        log(
                          " BEFORE - Unread: ${allChatsController.unreadCounts[chat.id]}",
                        );

                        allChatsController.markChatAsOpen(chat.id);

                        log(
                          " AFTER - Unread: ${allChatsController.unreadCounts[chat.id]}",
                        );
                        chatController.initChat(chat.id);
                        chatController.otherUser.value = otherUser;

                        if (chatController.otherUser.value != null) {
                          Get.to(() => ChatScreen());
                        } else {
                          Get.snackbar("Error", "Other user not loaded yet");
                        }
                      },
                    ),
                  );
                },
              );
            }),

            // --------- Users Tab ---------
            Obx(() {
              final users =
                  userController.allUsers
                      .where(
                        (u) => u.uid != userController.currentUser.value?.uid,
                      )
                      .toList();

              if (users.isEmpty) return Center(child: Text("No users found"));

              return ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final otherUser = users[index];

                  return ListTile(
                    leading: Stack(
                      children: [
                        CircleAvatar(
                          backgroundImage: NetworkImage(otherUser.image),
                        ),
                        // Online Indicator
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color:
                                  otherUser.isOnline
                                      ? Colors.green
                                      : Colors.grey,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                    title: Text(otherUser.name),
                    trailing: IconButton(
                      icon: Icon(Icons.message, color: Colors.blue),
                      onPressed: () async {
                        // Create or get chat with this user
                        await chatController.createOrGetChat(
                          otherUser: otherUser,
                        );
                        String chatId = chatController.currentChatId.value;
                        if (chatId.isNotEmpty) {
                          allChatsController.markChatAsOpen(chatId);
                        }

                        // Navigate to ChatScreen
                        Get.to(() => ChatScreen());
                      },
                    ),
                    onTap: () async {
                      await chatController.createOrGetChat(
                        otherUser: otherUser,
                      );
                      String chatId = chatController.currentChatId.value;
                      if (chatId.isNotEmpty) {
                        allChatsController.markChatAsOpen(chatId);
                      }

                      log("Navigating to chat with: ${otherUser.name}");
                      Get.to(() => ChatScreen());
                    },
                  );
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  // Delete Confirmation Dialog
  Future<bool> _showDeleteConfirmation(String chatId, String userName) async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        title: Text('Delete Chat?'),
        content: Text('This chat will be deleted from your account.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (result == true) {
      chatController.deletedChatForUser(chatId);
      Get.snackbar('Success', 'Chat deleted successfully');
      return true;
    }
    return false;
  }
}
