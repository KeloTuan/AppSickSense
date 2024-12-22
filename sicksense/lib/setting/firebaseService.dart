import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _dbRef =
      FirebaseDatabase.instance.ref().child('users');

  Future<Map<String, dynamic>> getUserData() async {
    final User? user = _auth.currentUser;
    if (user != null) {
      final DataSnapshot snapshot = await _dbRef.child(user.uid).get();
      if (snapshot.exists) {
        return Map<String, dynamic>.from(snapshot.value as Map);
      } else {
        throw Exception('User data not found');
      }
    } else {
      throw Exception('User not logged in');
    }
  }
}
