import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sick_sense_mobile/pages/chat.dart';

class LeftBar extends StatelessWidget {
  const LeftBar({super.key});

  // Kiểm tra người dùng hiện tại có phải bác sĩ
  Future<bool> _isCurrentUserDoctor() async {
    final firestore = FirebaseFirestore.instance;
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      final userDoc =
          await firestore.collection('User').doc(currentUser.uid).get();
      if (userDoc.exists) {
        return userDoc.data()?['IsDoctor'] ?? false;
      }
    }
    return false;
  }

  // Lấy danh sách phù hợp dựa trên vai trò người dùng
  Future<QuerySnapshot> _getDoctorsList() async {
    final firestore = FirebaseFirestore.instance;
    final isDoctor = await _isCurrentUserDoctor();

    if (isDoctor) {
      return await firestore
          .collection('User')
          .where('IsDoctor', isEqualTo: false)
          .get();
    } else {
      return await firestore
          .collection('User')
          .where('IsDoctor', isEqualTo: true)
          .get();
    }
  }

  // Lấy tên người dùng hiện tại
  Future<String> _getCurrentUserName() async {
    final firestore = FirebaseFirestore.instance;
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      final userDoc =
          await firestore.collection('User').doc(currentUser.uid).get();
      if (userDoc.exists) {
        return userDoc.data()?['Name'] ?? 'Unknown User';
      }
    }
    return 'Unknown User';
  }

  // Tạo ExpansionTile
  Widget _buildExpandableTile(
      String title, double fontSize, Future<QuerySnapshot> futureList) {
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
          FutureBuilder<QuerySnapshot>(
            future: futureList,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No users available.'),
                );
              }

              return ListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: snapshot.data!.docs.map((doc) {
                  var userData = doc.data() as Map<String, dynamic>;
                  return ListTile(
                    title: Text(userData['Name']),
                    subtitle: Text(userData['Email']),
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
        ],
      ),
    );
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
                Expanded(
                  child: ListView(
                    children: [
                      //_buildExpandableTile('Trò chuyện cùng AI', 20.0, Future.value(QuerySnapshot.empty())),
                      const SizedBox(height: 16),
                      _buildExpandableTile(
                          'Trò chuyện cùng bác sĩ', 20.0, _getDoctorsList()),
                    ],
                  ),
                ),
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
}
