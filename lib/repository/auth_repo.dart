import 'dart:developer';

import 'package:chat_system/models/user_model.dart';
import 'package:chat_system/service/auth_service.dart';

class AuthRepo {
  final AuthService _authService;

  AuthRepo(this._authService);

  // google sign in

  Future<UserModel?> signInWithGoogle() async {
    try {
      final user = await _authService.signInWithGoogle();
      return user;
    } catch (e) {
      throw Exception('Failed to sign in with Google: $e');
    }
  }

  // set online
  Future<void> setOnline(String uid) async {
    try {
      await _authService.setOnlineStatus(uid, true);
    } catch (e) {
      throw Exception('Failed to set user online: $e');
    }
  }

  //set offline
  Future<void> setOffline(String uid) async {
    try {
      await _authService.setOnlineStatus(uid, false);
    } catch (e) {
      throw Exception('Failed to set user offline: $e');
    }
  }

  //save user locally
  Future<void> saveUserLocally(String uid) async {
    try {
      await _authService.saveUserLocally(uid);
    } catch (e) {
      throw Exception('Failed to save user locally: $e');
    }
  }

  // get saved user
  Future<String?> getSavedUser() async {
    try {
      return await _authService.getSavedUser();
    } catch (e) {
      throw Exception('Failed to get saved user: $e');
    }
  }

  //get user by uid
  Future<UserModel?> fetchUserByUid(String uid) async {
    try {
      return await _authService.fetchUserByUid(uid);
    } catch (e) {
      throw Exception('Failed to fetch user by UID: $e');
    }
  }

  // get all login users
  Stream<List<UserModel>> getAllUsersStream() {
    return _authService.getAllUsersStream();
  }

  // logout
  Future<void> logout() async {
    try {
      await _authService.logout();
      log("user log out");
    } catch (e) {
      throw Exception('Failed to logout: $e');
    }
  }
}
