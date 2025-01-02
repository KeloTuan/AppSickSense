import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sick_sense_mobile/pages/chat.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User?>(
      future: _getCurrentUser(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData) {
          return const Center(child: Text('Chưa đăng nhập'));
        }

        return Chat(friendId: 'someFriendId');
      },
    );
  }

  Future<User?> _getCurrentUser() async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    return auth.currentUser;
  }
}
