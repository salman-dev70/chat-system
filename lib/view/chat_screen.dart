import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chat_system/controller/chat_controller.dart';
import 'package:chat_system/models/message_model.dart';

class ChatScreen extends StatelessWidget {
  final ChatController chatController = Get.find<ChatController>();
  final TextEditingController messageController = TextEditingController();

  ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(() {
          final ouser = chatController.otherUser.value;
          if (ouser == null) return Text("Chat");

          return Row(
            children: [
              CircleAvatar(backgroundImage: NetworkImage(ouser.image)),
              SizedBox(width: 10),
              Text(ouser.name),
            ],
          );
        }),
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: Obx(() {
              final msgs = chatController.messages;
              final ouser = chatController.otherUser.value;

              if (ouser == null) {
                return Center(child: Text("Loading chat..."));
              }

              if (msgs.isEmpty) {
                return Center(child: Text("No messages yet"));
              }

              return ListView.builder(
                reverse: true,
                padding: const EdgeInsets.all(10),
                itemCount: msgs.length,
                itemBuilder: (context, index) {
                  final MessageModel msg = msgs[msgs.length - 1 - index];
                  final isMe =
                      msg.senderId ==
                      chatController.userController.currentUser.value!.uid;

                  return Align(
                    alignment:
                        isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isMe ? Colors.blue : Colors.grey[300],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        msg.message,
                        style: TextStyle(
                          color: isMe ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
          ),

          // Input field
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            color: Colors.grey[200],
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () async {
                    final text = messageController.text.trim();
                    if (text.isEmpty) return;

                    final ouser = chatController.otherUser.value;
                    if (ouser == null) {
                      Get.snackbar("Error", "Other user not loaded yet");
                      return;
                    }

                    await chatController.sendMessage(text, ouser.uid);
                    messageController.clear();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
