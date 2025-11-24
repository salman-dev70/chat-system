import 'package:chat_system/view/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chat_system/controller/auth_controller.dart';

class LoginScreen extends StatelessWidget {
  final AuthController _authController = Get.find<AuthController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton.icon(
          icon: Icon(Icons.login),
          // icon: Image.asset(

          //   //'assets/google_logo.png', // apna Google icon
          //   // height: 24,
          //   // width: 24,
          // ),
          label: Text('Sign in with Google'),
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          onPressed: () async {
            await _authController.signInWithGoogle();
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (context) => HomeScreen()));
          },
        ),
      ),
    );
  }
}
