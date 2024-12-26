import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sick_sense_mobile/auth/login/login_screen.dart';
import 'package:sick_sense_mobile/pages/chat.dart';
import 'package:sick_sense_mobile/setting/setting.dart';
//import 'package:sicksense/map/screens/pharmacy_search_screen.dart';

class RightBar extends StatelessWidget {
  const RightBar({super.key});

  Future<void> signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    // Điều hướng về màn hình đăng nhập hoặc trang chính sau khi đăng xuất
    if (FirebaseAuth.instance.currentUser == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Phần trái 20% (Nút menu)
          Container(
            width: MediaQuery.of(context).size.width * 0.2,
            // color: Colors.white,
            // child: Column(
            //   children: [
            //     const SizedBox(height: 40),
            //     IconButton(
            //       icon: const Icon(Icons.menu),
            //       onPressed: () {
            //         Navigator.pop(context); // Đóng LeftBar khi nhấn menu
            //       },
            //     ),
            //   ],
            // ),
          ),

          // Phần phải 80%
          Expanded(
            child: Container(
              color: Colors.grey[200],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 45),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: ListTile(
                      leading: const Icon(Icons.local_pharmacy, size: 28),
                      title: const Text(
                        'Nhà thuốc gần đây',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onTap: () {
                        // Navigator.push(
                        //   context,
                        //   MaterialPageRoute(
                        //       builder: (context) => PharmacySearchScreen()),
                        // );
                      },
                    ),
                  ),

                  //const SizedBox(height: 20),
                  const Divider(thickness: 1), // Gạch ngang

                  //const SizedBox(height: 20),
                  ListTile(
                    leading: const Icon(Icons.settings),
                    title:
                        const Text('Cài đặt', style: TextStyle(fontSize: 20)),
                    onTap: () {
                      // Xử lý sự kiện cài đặt
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SettingPage()),
                      );
                    },
                  ),
                  //const SizedBox(height: 20),
                  ListTile(
                    leading: const Icon(Icons.help_outline),
                    title: const Text('Hỗ trợ', style: TextStyle(fontSize: 20)),
                    onTap: () {
                      // Xử lý sự kiện hỗ trợ
                    },
                  ),
                  //const SizedBox(height: 20),
                  // Nút Đăng xuất
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.black),
                    title: const Text('Đăng xuất',
                        style: TextStyle(fontSize: 20, color: Colors.black)),
                    onTap: () {
                      signOut(context);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
