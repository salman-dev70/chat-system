import 'package:chat_system/controller/all_chats_controller.dart';
import 'package:chat_system/controller/auth_controller.dart';
import 'package:chat_system/controller/chat_controller.dart';
import 'package:chat_system/controller/users_controller.dart';
import 'package:chat_system/repository/auth_repo.dart';
import 'package:chat_system/repository/chat_repo.dart';
import 'package:chat_system/service/auth_service.dart';
import 'package:chat_system/service/chat_service.dart';
import 'package:chat_system/view/login_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  // Repositories
  final authRepo = AuthRepo(AuthService());
  final chatRepo = ChatRepo(ChatService());

  // Controllers
  Get.put(AuthController(authRepo));
  Get.put(UserController(authRepo));
  Get.put(ChatController(chatRepo, Get.find<UserController>()));
  Get.put(AllChatsController(chatRepo));
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: LoginScreen(),
    );
  }
}
