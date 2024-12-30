import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sick_sense_mobile/auth/login/login_screen.dart';
import 'package:sick_sense_mobile/pages/chat.dart';
import 'package:sick_sense_mobile/setting/setting.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
    // Lấy đối tượng AppLocalizations để sử dụng chuỗi ngôn ngữ
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      body: Row(
        children: [
          // Phần trái 20% (Nút menu - nếu cần thiết)
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
                      title: Text(
                        localizations
                            .nearbyPharmacies, // Sử dụng chuỗi ngôn ngữ
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onTap: () {
                        // Bạn có thể điều hướng tới trang tìm kiếm nhà thuốc
                        // Navigator.push(
                        //   context,
                        //   MaterialPageRoute(
                        //       builder: (context) => PharmacySearchScreen()),
                        // );
                      },
                    ),
                  ),

                  const Divider(thickness: 1), // Gạch ngang

                  ListTile(
                    leading: const Icon(Icons.settings),
                    title: Text(localizations.settings,
                        style: const TextStyle(fontSize: 20)),
                    onTap: () {
                      // Xử lý sự kiện cài đặt
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SettingPage()),
                      );
                    },
                  ),

                  ListTile(
                    leading: const Icon(Icons.help_outline),
                    title: Text(localizations.support,
                        style: const TextStyle(fontSize: 20)),
                    onTap: () {
                      // Xử lý sự kiện hỗ trợ
                      // Bạn có thể điều hướng tới một trang hỗ trợ
                    },
                  ),

                  // Nút Đăng xuất
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.black),
                    title: Text(
                      localizations.logout,
                      style: const TextStyle(fontSize: 20, color: Colors.black),
                    ),
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
