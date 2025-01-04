import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Tạo ID cuộc trò chuyện duy nhất giữa hai người dùng
  String generateConversationId(String friendId) {
    return _auth.currentUser!.uid.compareTo(friendId) < 0
        ? '${_auth.currentUser!.uid}_${friendId}'
        : '${friendId}_${_auth.currentUser!.uid}';
  }

  // Gửi tin nhắn đến Firestore
  Future<void> sendMessage(
      String conversationId, String message, String receiverId) async {
    try {
      final userId = _auth.currentUser!.uid;

      // Thêm tin nhắn vào Firestore
      await _firestore
          .collection('chats')
          .doc(conversationId)
          .collection('messages')
          .add({
        'sender': userId,
        'receiver': receiverId,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Lỗi khi gửi tin nhắn: $e");
      rethrow;
    }
  }

  // Lấy danh sách tin nhắn từ Firestore
  Stream<List<Map<String, dynamic>>> getMessages(String conversationId) {
    return _firestore
        .collection('chats')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return doc.data() as Map<String, dynamic>;
      }).toList();
    });
  }

  // Lấy danh sách bạn bè của người dùng
  Future<List<Map<String, dynamic>>> getFriendsList() async {
    try {
      final userId = _auth.currentUser!.uid;

      // Lấy danh sách bạn bè từ Firestore
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('friends')
          .get();

      return querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print("Lỗi khi lấy danh sách bạn bè: $e");
      return [];
    }
  }
}
