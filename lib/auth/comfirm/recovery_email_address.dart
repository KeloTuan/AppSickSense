import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sick_sense_mobile/auth/login/login_screen.dart';

class RecoveryEmailAddress extends StatefulWidget {
  const RecoveryEmailAddress({super.key});

  @override
  State<RecoveryEmailAddress> createState() => _RecoveryEmailAddressState();
}

class _RecoveryEmailAddressState extends State<RecoveryEmailAddress> {
  TextEditingController email = TextEditingController();

  reset() async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email.text);

      // Hiển thị thông báo thành công
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Mã khôi phục mật khẩu đã được gửi thành công qua email.\nKhi đổi mật khẩu xong cần tải lại trang đăng nhập.'),
          duration: const Duration(seconds: 8),
        ),
      );

      // Điều hướng về trang đăng nhập sau khi hiển thị thông báo
      //Navigator.pushReplacement: Sử dụng khi bạn muốn thay thế màn hình hiện tại mà không cần quay lại
      Future.delayed(const Duration(seconds: 8), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      });
    } catch (e) {
      // Hiển thị thông báo lỗi nếu có lỗi
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Có lỗi xảy ra: $e'),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recovery Email Address')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Hình ảnh ở trên email
            CircleAvatar(
              backgroundImage: AssetImage('assets/Duck.png'),
              radius: 30,
            ),
            const SizedBox(height: 20), // Khoảng cách giữa ảnh và email
            // Trường email được thiết kế theo yêu cầu
            TextField(
              controller: email,
              decoration: InputDecoration(
                labelText: 'Email',
                labelStyle: const TextStyle(color: Colors.purple),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.purple),
                ),
              ),
            ),
            const SizedBox(height: 20), // Khoảng cách giữa email và nút
            // Nút xác nhận với thiết kế theo yêu cầu
            ElevatedButton(
              onPressed: reset,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple, // Màu nền
                shape: const RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.all(Radius.circular(5.5)), // Góc bo tròn
                ),
              ),
              child: const Text(
                'Xác nhận',
                style: TextStyle(
                  color: Colors.white, // Màu chữ là trắng
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
