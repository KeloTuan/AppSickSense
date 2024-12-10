import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sick_sense_mobile/auth/home_screen.dart';
import 'package:sick_sense_mobile/auth/signup/sign_up_screen.dart';
import 'package:sick_sense_mobile/auth/comfirm/recovery_email_address.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController email = TextEditingController();
  TextEditingController password = TextEditingController();

  bool isLoading = false;

  signIn() async {
    setState(() {
      isLoading = true;
    });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email.text, password: password.text);

      // Kiểm tra nếu người dùng đã đăng nhập thành công
      if (FirebaseAuth.instance.currentUser != null) {
        // Chuyển đến màn hình chính (hoặc RightBar)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      Get.snackbar("error message", e.code);
    } catch (e) {
      Get.snackbar("error message", e.toString());
    }
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? Center(
            child: CircularProgressIndicator(),
          )
        : Scaffold(
            // appBar: AppBar(
            //   title: Text("Login"),
            // ),
            backgroundColor: Colors.white,
            body: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Hình ảnh nhân vật nằm ở phía trên email
                  Image.asset(
                    'assets/images/doctor_cartoon.png', // Đặt hình ảnh nhân vật tại đây
                    height: 300, // Chỉnh kích thước của hình ảnh
                  ),
                  SizedBox(
                      height:
                          30), // Khoảng cách giữa hình ảnh và trường nhập email

                  // Trường nhập email
                  TextField(
                    controller: email,
                    decoration: InputDecoration(
                      labelText: 'Enter email',
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
                  SizedBox(height: 20),

                  // Trường nhập mật khẩu
                  TextField(
                    controller: password,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Enter password',
                      labelStyle: const TextStyle(color: Colors.purple),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.purple),
                      ),
                      suffixIcon: const Icon(
                        Icons.visibility,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  SizedBox(height: 30),

                  // Nút đăng nhập
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple, // Màu nền của nút
                      minimumSize: const Size(
                          double.infinity, 50), // Kích thước tối thiểu
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(8), // Bo góc cho nút
                      ),
                    ),
                    onPressed: (() => signIn()), // Hàm xử lý khi nút được nhấn
                    child: const Text(
                      'Đăng nhập', // Văn bản của nút
                      style: TextStyle(
                        fontSize: 18, // Kích thước chữ
                        color: Colors.white, // Màu chữ
                      ),
                    ),
                  ),
                  SizedBox(height: 20),

                  // Nút đăng ký
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                          "Bạn chưa có tài khoản? "), // Văn bản "Bạn chưa có tài khoản?"
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => SignUpScreen()),
                          );
                        },
                        child: const Text(
                          "Đăng ký", // Văn bản "Đăng ký"
                          style: TextStyle(
                            color: Colors.purple, // Màu chữ là tím
                            fontWeight: FontWeight.bold, // Đặt chữ đậm nếu cần
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),

                  // Nút quên mật khẩu
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Get.to(
                              RecoveryEmailAddress()); // Chuyển đến màn hình Đăng ký khi nhấn
                        },
                        child: const Text(
                          "Quên mật khẩu?", // Văn bản "Đăng ký"
                          style: TextStyle(
                            color: Colors.purple, // Màu chữ là tím
                            fontWeight: FontWeight.bold, // Đặt chữ đậm nếu cần
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
  }
}
