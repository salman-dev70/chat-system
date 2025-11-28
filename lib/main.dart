import 'package:chat_system/bindings/app_binding.dart';

import 'package:chat_system/controller/users_controller.dart';

import 'package:chat_system/view/home_screen.dart';
import 'package:chat_system/view/login_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  AppBindings().dependencies();

  await AppBindings.loadInitialData();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final userController = Get.find<UserController>();

    return GetMaterialApp(
      initialBinding: AppBindings(),
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),

      home:
          userController.currentUser.value != null
              ? HomeScreen()
              : LoginScreen(),
    );
  }
}
