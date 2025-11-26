// lib/widgets/unread_badge.dart
import 'package:chat_system/controller/all_chats_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class UnreadBadge extends StatelessWidget {
  final String chatId;

  const UnreadBadge({Key? key, required this.chatId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final AllChatsController allChatsController =
          Get.find<AllChatsController>();
      int count = allChatsController.getUnreadCount(chatId);

      if (count > 0) {
        return CircleAvatar(
          radius: 12,
          backgroundColor: Colors.green,
          child: Text(
            '$count',
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
        );
      } else {
        return SizedBox();
      }
    });
  }
}
