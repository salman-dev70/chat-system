import 'dart:developer';

import 'package:chat_system/controller/all_chats_controller.dart';

import 'package:chat_system/controller/users_controller.dart';

import 'package:chat_system/view/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chat_system/controller/auth_controller.dart';

class LoginScreen extends StatelessWidget {
  final AuthController _authController = Get.find<AuthController>();
  final UserController userController = Get.find<UserController>();
  final AllChatsController allChatsController = Get.find<AllChatsController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Obx(() {
          if (_authController.isLoading.value) {
            return Center(child: CircularProgressIndicator());
          } else {
            return ElevatedButton.icon(
              icon: Icon(Icons.login),
              label: Text('Sign in with Google'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onPressed: () async {
                await _authController.signInWithGoogle();
                allChatsController.resetForNewUser();

                log("fetch chats after login");
                await userController.loadCurrentUserData();
                log("fetch chats of current user");
                allChatsController.initializeChats();
                log("all chats initialize");
                Get.off(HomeScreen());
              },
            );
          }
        }),
      ),
    );
  }
}
