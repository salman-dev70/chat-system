import 'dart:developer';

import 'package:chat_system/controller/auth_controller.dart';
import 'package:chat_system/models/message_model.dart';
import 'package:chat_system/view/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/all_chats_controller.dart';
import '../controller/chat_controller.dart';
import '../controller/users_controller.dart';
import '../models/chat_model.dart';
import '../models/user_model.dart';
import 'chat_screen.dart';

class HomeScreen extends StatelessWidget {
  final AllChatsController allChatsController = Get.find<AllChatsController>();
  final UserController userController = Get.find<UserController>();
  final ChatController chatController = Get.find<ChatController>();
  final AuthController authController = Get.find<AuthController>();

  @override
  Widget build(BuildContext context) {
    log(" Current User ID: ${userController.currentUserId}");
    log(" All Users Count: ${userController.allUsers.length}");
    log(" All Chats Count: ${allChatsController.allChats.length}");
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
              if (allChatsController.allChats.isEmpty) {
                return Center(child: Text('No chats yet'));
              }
              return ListView.builder(
                itemCount: allChatsController.allChats.length,
                itemBuilder: (context, index) {
                  ChatModel chat = allChatsController.allChats[index];

                  // Find the other user's ID
                  String otherUserId = chat.users.firstWhere(
                    (uid) => uid != userController.currentUser.value?.uid,
                  );

                  // Get the other user's info
                  UserModel? otherUser = userController.allUsers
                      .firstWhereOrNull((user) => user.uid == otherUserId);

                  return ListTile(
                    leading: Stack(
                      children: [
                        CircleAvatar(
                          backgroundImage: NetworkImage(otherUser?.image ?? ''),
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
                    trailing: Obx(() {
                      int? count = allChatsController.unreadCounts[chat.id];

                      if (count != null && count > 0) {
                        return CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.red,
                          child: Text(
                            '$count',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        );
                      } else {
                        return SizedBox();
                      }
                    }),
                    onTap: () {
                      chatController.initChat(chat.id);
                      chatController.otherUser.value = otherUser;

                      if (chatController.otherUser.value != null) {
                        Get.to(() => ChatScreen());
                      } else {
                        Get.snackbar("Error", "Other user not loaded yet");
                      }
                    },
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

                        // Navigate to ChatScreen
                        Get.to(() => ChatScreen());
                      },
                    ),
                    onTap: () async {
                      await chatController.createOrGetChat(
                        otherUser: otherUser,
                      );

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
}
