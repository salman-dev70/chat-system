// lib/bindings/app_bindings.dart

import 'package:chat_system/controller/all_chats_controller.dart';
import 'package:chat_system/controller/auth_controller.dart';
import 'package:chat_system/controller/chat_controller.dart';
import 'package:chat_system/controller/users_controller.dart';
import 'package:chat_system/repository/auth_repo.dart';
import 'package:chat_system/repository/chat_repo.dart';
import 'package:chat_system/service/auth_service.dart';
import 'package:chat_system/service/chat_service.dart';
import 'package:get/get.dart';

class AppBindings extends Bindings {
  @override
  void dependencies() {
    // Services
    Get.put<AuthService>(AuthService(), permanent: true);
    Get.put<ChatService>(ChatService(), permanent: true);

    // Repositories
    Get.put<AuthRepo>(AuthRepo(Get.find<AuthService>()), permanent: true);
    Get.put<ChatRepo>(ChatRepo(Get.find<ChatService>()), permanent: true);

    // Controllers
    Get.put<AuthController>(AuthController(Get.find<AuthRepo>()));
    Get.put<UserController>(
      UserController(Get.find<AuthService>(), Get.find<AuthRepo>()),
      permanent: true,
    );
    Get.put<ChatController>(
      ChatController(Get.find<ChatRepo>(), Get.find<UserController>()),
    );
    Get.put<AllChatsController>(AllChatsController(Get.find<ChatRepo>()));
  }

  static Future<void> loadInitialData() async {
    final AuthService authService = Get.find<AuthService>();
    final UserController userController = Get.find<UserController>();

    if (authService.currentUser != null) {
      await userController.loadCurrentUserData();
    }
  }
}
