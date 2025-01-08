import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Generate a unique conversation ID based on user IDs
  String generateConversationId(String friendId) {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) throw Exception("User not authenticated");

    return currentUserId.compareTo(friendId) < 0
        ? '${currentUserId}_$friendId'
        : '${friendId}_$currentUserId';
  }

  /// Get messages for a specific conversation
  Future<List<Map<String, dynamic>>> getConversationMessages(
      String friendId) async {
    final conversationId = generateConversationId(friendId);

    final querySnapshot = await _firestore
        .collection('Chats')
        .doc(conversationId)
        .collection('Messages')
        .orderBy('timestamp')
        .get();

    return querySnapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .toList();
  }

  Future<void> sendMessage({
    required String friendId,
    required String message,
  }) async {
    if (message.trim().isEmpty) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final conversationId = generateConversationId(friendId);
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    final chatRef =
        FirebaseFirestore.instance.collection('Chats').doc(conversationId);

    try {
      // Try to get existing chat
      final chatDoc = await chatRef.get();

      if (!chatDoc.exists) {
        // Create new chat if it doesn't exist
        await chatRef.set({
          'ChatId': conversationId,
          'Participants': [currentUser.uid, friendId],
          'Messages': [
            {
              'SenderId': currentUser.uid,
              'Message': message.trim(),
              'Timestamp': timestamp,
            }
          ]
        });
      } else {
        // Add message to existing chat
        await chatRef.update({
          'Messages': FieldValue.arrayUnion([
            {
              'SenderId': currentUser.uid,
              'Message': message.trim(),
              'Timestamp': timestamp,
            }
          ])
        });
      }
    } catch (e) {
      print('Error sending message: $e');
      rethrow;
    }
  }

  // Get a stream of messages for a conversation
  Stream<List<Map<String, dynamic>>> getMessages(String conversationId) {
    return _firestore
        .collection('Chats')
        .doc(conversationId)
        .collection('Messages')
        .orderBy('Timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'SenderId': data['SenderId'],
          'Message': data['Message'],
          'Timestamp': (data['Timestamp'] as Timestamp).seconds,
        };
      }).toList();
    });
  }

  // Fetch the list of texted users for the current user
  Future<List<Map<String, dynamic>>> getTextedUsers() async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) throw Exception("User not authenticated");

      final userDoc =
          await _firestore.collection('Users').doc(currentUserId).get();

      if (!userDoc.exists || userDoc.data() == null) return [];
      final data = userDoc.data() as Map<String, dynamic>;

      return List<Map<String, dynamic>>.from(data['TextedUsers'] ?? []);
    } catch (e) {
      print("Error fetching texted users: $e");
      return [];
    }
  }

  // Private helper method to update TextedUsers
  Future<void> _updateTextedUsers(String currentUserId, String friendId,
      String message, int timestamp) async {
    try {
      // Update current user's TextedUsers
      await _firestore.collection('Users').doc(currentUserId).set({
        'TextedUsers': FieldValue.arrayUnion([
          {
            'UserId': friendId,
            'LastMessage': message,
            'Timestamp': timestamp,
          }
        ])
      }, SetOptions(merge: true));

      // Update friend's TextedUsers
      await _firestore.collection('Users').doc(friendId).set({
        'TextedUsers': FieldValue.arrayUnion([
          {
            'UserId': currentUserId,
            'LastMessage': message,
            'Timestamp': timestamp,
          }
        ])
      }, SetOptions(merge: true));
    } catch (e) {
      print("Error updating texted users: $e");
      rethrow;
    }
  }
}
