import 'package:chat_system/repository/auth_repo.dart';
import 'package:get/get.dart';
import '../models/user_model.dart';

class UserController extends GetxController {
  final AuthRepo _authRepo;

  RxList<UserModel> allUsers = <UserModel>[].obs;
  Rx<UserModel?> currentUser = Rx<UserModel?>(null);

  UserController(this._authRepo);

  String get currentUserId => currentUser.value?.uid ?? '';

  @override
  void onInit() {
    super.onInit();
    _listenAllUsers();
  }

  void _listenAllUsers() {
    _authRepo.getAllUsersStream().listen((users) {
      allUsers.value = users;
    });
  }
}
