import 'dart:developer';

import 'package:chat_system/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // get Current user
  UserModel? get currentUser {
    final user = _auth.currentUser;
    if (user != null) {
      return UserModel(
        uid: user.uid,
        name: user.displayName ?? '',
        image: user.photoURL ?? '',
        isOnline: true,
      );
    }
    return null;
  }

  // google Signin

  Future<UserModel?> signInWithGoogle() async {
    log("process start ");
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      return null;
    }
    log("google done ");
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;
    log("google sign in authentication done ");
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    log("google credential done ");
    final userCredential = await _auth.signInWithCredential(credential);
    final user = userCredential.user;
    log("credential from firebase done ");
    if (user == null) return null;

    final userDoc = _firestore.collection('users').doc(user.uid);
    final docSnapshot = await userDoc.get();
    if (!docSnapshot.exists) {
      await userDoc.set({
        'uid': user.uid,
        'name': user.displayName ?? '',
        'image': user.photoURL ?? '',
        'isOnline': true,
      });
      log("user store in firestore ");
    } else {
      await userDoc.update({'isOnline': true});
    }
    return UserModel(
      uid: user.uid,
      name: user.displayName ?? '',
      image: user.photoURL ?? '',
      isOnline: true,
    );
  }

  // Set online Status
  Future<void> setOnlineStatus(String userId, bool isOnline) async {
    final userDoc = _firestore.collection('users').doc(userId);
    await userDoc.update({'isOnline': isOnline});
  }

  //set offline status
  Future<void> setOfflineStatus(String userId) async {
    final userDoc = _firestore.collection('users').doc(userId);
    await userDoc.update({'isOnline': false});
  }

  //save User Locally
  Future<void> saveUserLocally(String Uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('uid', Uid);
  }

  // get saved user
  Future<String?> getSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('uid');
  }

  /// Fetch user data by UID
  Future<UserModel?> fetchUserByUid(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserModel(
        uid: doc['uid'],
        name: doc['name'],
        image: doc['image'],
        isOnline: doc['isOnline'],
      );
    } else {}
  }

  // Getting All login Users

  Stream<List<UserModel>> getAllUsersStream() {
    return _firestore
        .collection('users')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => UserModel.fromJson(doc.data()))
                  .toList(),
        );
  }
}
