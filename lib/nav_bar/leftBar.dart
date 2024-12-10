import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sick_sense_mobile/auth/home_screen.dart';
import 'package:sick_sense_mobile/setting/accountSettingPage.dart';

class LeftBar extends StatelessWidget {
  const LeftBar({super.key});

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      body: Row(
        children: [
          // Left Section (80%)
          Container(
            width: MediaQuery.of(context).size.width * 0.8,
            color: Colors.grey[200],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                Expanded(
                  child: ListView(
                    children: [
                      _buildExpandableTile('Trò chuyện cùng AI', 20.0),
                      const SizedBox(height: 16),
                      _buildExpandableTile('Trò chuyện cùng bác sĩ', 20.0),
                    ],
                  ),
                ),
                FutureBuilder<DocumentSnapshot>(
                  future: _getUserData(currentUser),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData) {
                      return const Center(
                          child: Text('Thông tin người dùng không có'));
                    }

                    final userData =
                        snapshot.data!.data() as Map<String, dynamic>;
                    final String userEmail =
                        userData['Name'] ?? "Tên chưa được cập nhật";

                    return ListTile(
                      leading: const CircleAvatar(
                        backgroundImage: AssetImage('assets/profile.jpg'),
                      ),
                      title: Text(
                        userEmail,
                        style: const TextStyle(fontSize: 20.0),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AccountSettingPage(),
                          ),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),

          // Right Section (20%)
          Container(
            width: MediaQuery.of(context).size.width * 0.2,
            color: Colors.white,
            child: Column(
              children: [
                const SizedBox(height: 45),
                IconButton(
                  icon: const Icon(Icons.menu),
                  iconSize: 30.0,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const HomeScreen()),
                    );
                  },
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.add),
                  iconSize: 30.0,
                  onPressed: () {},
                ),
                const SizedBox(height: 20),
              ],
            ),
          )
        ],
      ),
    );
  }

  Future<DocumentSnapshot> _getUserData(User? currentUser) async {
    final firestore = FirebaseFirestore.instance;
    return await firestore
        .collection('User')
        .doc(currentUser
            ?.uid) // Query using UID instead of email for better precision
        .get();
  }

  Widget _buildExpandableTile(String title, double fontSize) {
    return Padding(
      padding: const EdgeInsets.only(left: 20.0),
      child: ExpansionTile(
        leading: const Icon(Icons.add),
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize),
        ),
        tilePadding: EdgeInsets.zero,
        backgroundColor: Colors.transparent,
        shape: Border.all(color: Colors.transparent),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18.0),
            child: Container(
              constraints: const BoxConstraints(
                maxHeight: 300.0,
              ),
              child: SingleChildScrollView(
                child: _buildConversationHistory(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        _buildConversationGroup('Hôm nay', [
          'Thiết kế ERD hệ thống',
          'Sửa lỗi emulator Android',
        ]),
        const SizedBox(height: 20),
        _buildConversationGroup('Hôm qua', [
          'Thiết kế ERD hệ thống',
          'Sửa lỗi emulator Android',
        ]),
        const SizedBox(height: 20),
        _buildConversationGroup('7 ngày trước', [
          'Thiết kế ERD hệ thống',
          'Sửa lỗi emulator Android',
          'Thêm dữ liệu cho hệ thống',
          'Kiểm tra giao diện',
          'Viết tài liệu hướng dẫn',
        ]),
      ],
    );
  }

  Widget _buildConversationGroup(String date, List<String> conversations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          alignment: Alignment.centerLeft,
          child: Text(
            date,
            style: const TextStyle(
              fontSize: 20.0,
              color: Colors.blue,
            ),
          ),
        ),
        const SizedBox(height: 20.0),
        ...conversations.map(
          (conversation) => Container(
            alignment: Alignment.centerLeft,
            margin: const EdgeInsets.only(bottom: 24.0),
            child: Text(
              conversation,
              style: const TextStyle(fontSize: 20.0, color: Colors.black),
            ),
          ),
        ),
      ],
    );
  }
}
