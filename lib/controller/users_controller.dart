import 'dart:math';

import 'package:chat_system/repository/auth_repo.dart';
import 'package:chat_system/repository/chat_repo.dart';
import 'package:chat_system/service/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../models/user_model.dart';

class UserController extends GetxController {
  final AuthService _authService;
  final AuthRepo _authRepo;

  RxList<UserModel> allUsers = <UserModel>[].obs;
  Rx<UserModel?> currentUser = Rx<UserModel?>(null);

  UserController(this._authService, this._authRepo);

  String get currentUserId => currentUser.value?.uid ?? '';

  @override
  void onInit() {
    super.onInit();
    _listenAllUsers();
  }

  void _listenAllUsers() {
    _authRepo.getAllUsersStream().listen((users) {
      allUsers.value = users;
      log("All users list updated: ${users.length} users found." as num);
    });
  }

  Future<void> loadCurrentUserData() async {
    final User? firebaseUser = _authService.currentUser;
    if (firebaseUser != null) {
      final UserModel? userModel = await _authService.fetchUserByUid(
        firebaseUser.uid,
      );
      if (userModel != null) {
        currentUser.value = userModel;
        print(
          "Current User data loaded successfully for UID: ${userModel.uid}",
        );
      }
    } else {
      currentUser.value = null;
      print("loadCurrentUserData: User is not logged in.");
    }
  }

  void clearUserData() {
    currentUser.value = null;
  }
}
