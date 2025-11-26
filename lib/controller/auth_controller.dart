import 'dart:io';

import 'package:chat_system/bindings/app_binding.dart';
import 'package:chat_system/controller/all_chats_controller.dart';
import 'package:chat_system/controller/users_controller.dart';
import 'package:chat_system/models/user_model.dart';
import 'package:chat_system/repository/auth_repo.dart';
import 'package:chat_system/view/login_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';

class AuthController extends GetxController with WidgetsBindingObserver {
  final AuthRepo _authRepo;
  AuthController(this._authRepo);

  Rx<UserModel?> currentUser = Rx<UserModel?>(null);

  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _checkSavedUser();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final user = currentUser.value;
    if (user == null) return;

    switch (state) {
      case AppLifecycleState.resumed:
        _authRepo.setOnline(user.uid);
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _authRepo.setOffline(user.uid);
        break;
      default:
        _authRepo.setOffline(user.uid);
        break;
    }
  }

  // google sign in

  Future<void> signInWithGoogle() async {
    isLoading.value = true;
    try {
      final user = await _authRepo.signInWithGoogle();
      currentUser.value = user;
      if (user != null) {
        await _authRepo.setOnline(user.uid);
      }
      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
      Get.snackbar("SignIn falied", e.toString());
    }
  }

  Future<void> _checkSavedUser() async {
    try {
      String? savedUid = await _authRepo.getSavedUser();
      if (savedUid != null) {
        UserModel? user = await _authRepo.fetchUserByUid(savedUid);
        if (user != null) {
          currentUser.value = user;
          await _authRepo.setOnline(user.uid);
        }
      }
    } catch (e) {
      Get.snackbar("Error", e.toString());
    }
  }

  // sign out
  Future<void> signOut() async {
    final UserController userController = Get.find<UserController>();
    try {
      if (currentUser.value != null) {
        final String currentUserId = currentUser.value!.uid;

        await _authRepo.setOffline(currentUserId);
      } else {}

      await _authRepo.logout();

      currentUser.value = null;
      userController.clearUserData();
      await _clearAppCache();

      Get.offAll(() => LoginScreen());
    } catch (e) {
      Get.snackbar("Sign Out failed", e.toString());
      print(e.toString());
    }
  }

  Future<void> _clearAppCache() async {
    try {
      Directory tempDir = await getTemporaryDirectory();
      if (tempDir.existsSync()) {
        // Delete the entire directory recursively
        await tempDir.delete(recursive: true);
        // Recreate it to avoid potential errors if other processes need it immediately
        await Directory(tempDir.path).create(recursive: true);
      }
    } catch (e) {
      print("Error clearing temporary app cache: $e");
    }
  }
}
