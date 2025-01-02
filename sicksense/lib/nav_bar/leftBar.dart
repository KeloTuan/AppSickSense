import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sick_sense_mobile/pages/chat.dart';
import 'package:sick_sense_mobile/setting/accountSettingPage.dart';

class LeftBar extends StatelessWidget {
  const LeftBar({super.key});

  Future<QuerySnapshot> _getDoctorsList() async {
    final firestore = FirebaseFirestore.instance;

    // Truy vấn danh sách người dùng có chức năng là bác sĩ
    return await firestore
        .collection('User') // Chú ý đúng tên collection 'User'
        .where('IsDoctor', isEqualTo: true) // Lọc những người là bác sĩ
        .get();
  }

  Future<String> _getCurrentUserName() async {
    final firestore = FirebaseFirestore.instance;
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      final userDoc =
      await firestore.collection('User').doc(currentUser.uid).get();
      if (userDoc.exists) {
        return userDoc.data()?['Name'] ??
            'Unknown User'; // Lấy tên hoặc hiển thị mặc định
      }
    }
    return 'Unknown User';
  }

  @override
  Widget build(BuildContext context) {
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
                // Danh sách bác sĩ
                Expanded(
                  child: FutureBuilder<QuerySnapshot>(
                    future: _getDoctorsList(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(
                            child: Text('No doctors available.'));
                      }

                      return ListView(
                        shrinkWrap: true,
                        children: snapshot.data!.docs.map((doc) {
                          var doctorData = doc.data() as Map<String, dynamic>;
                          return ListTile(
                            title: Text(doctorData['Name']),
                            subtitle: Text(doctorData['Email']),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => Chat(friendId: doc.id),
                                ),
                              );
                            },
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),

                const Divider(height: 10, color: Colors.black),
                // Hiển thị tên người dùng ở đây
                FutureBuilder<String>(
                  future: _getCurrentUserName(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      );
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        snapshot.data ?? 'Unknown User',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20)
              ],
            ),
          ),

          // Right Section (20%)
          Container(
            width: MediaQuery.of(context).size.width * 0.2,
            color: Colors.white,
            child: Column(
              children: [
                const SizedBox(height: 40),
                IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<QuerySnapshot> _getFriendsList() async {
    final firestore = FirebaseFirestore.instance;
    final currentUser = FirebaseAuth.instance.currentUser;

    return await firestore
        .collection('users')
        .doc(currentUser?.uid)
        .collection('friends') // Assuming you have a collection 'friends'
        .get();
  }
}
