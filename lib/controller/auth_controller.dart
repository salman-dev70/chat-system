import 'package:chat_system/models/user_model.dart';
import 'package:chat_system/repository/auth_repo.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

class AuthController extends GetxController with WidgetsBindingObserver {
  final AuthRepo _authRepo;
  AuthController(this._authRepo);

  Rx<UserModel?> currentUser = Rx<UserModel?>(null);

  @override
  void onInit() {
    // TODO: implement onInit
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
    try {
      final user = await _authRepo.signInWithGoogle();
      currentUser.value = user;
      if (user != null) {
        await _authRepo.setOnline(user.uid);
      }
    } catch (e) {
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
}
