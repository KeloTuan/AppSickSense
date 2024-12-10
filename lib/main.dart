import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:sick_sense_mobile/auth/login/login_screen.dart';
import 'package:sick_sense_mobile/auth/signup/sign_up_screen.dart'; // Đường dẫn tới ứng dụng chính của bạn

void main() async {
  WidgetsFlutterBinding
      .ensureInitialized(); // Đảm bảo Flutter được khởi tạo đúng cách
  await Firebase.initializeApp(); // Khởi tạo Firebase
  runApp(const MyApp()); // Chạy ứng dụng của bạn
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sick Sense',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: LoginScreen(), // Đặt trang khởi đầu của bạn
    );
  }
}
