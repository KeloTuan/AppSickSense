import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sick_sense_mobile/nav_bar/leftBar.dart';
import 'package:sick_sense_mobile/nav_bar/rightbar.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:sick_sense_mobile/pages/chat_service.dart';
import 'package:sick_sense_mobile/summarize/summarize_websocket_screen.dart';
import 'package:sick_sense_mobile/setting/base64_image.dart';

class Chat extends StatefulWidget {
  final String friendId;

  const Chat({super.key, required this.friendId});

  @override
  State<Chat> createState() => _ChatState();
}

class _ChatState extends State<Chat> {
  final TextEditingController _controller = TextEditingController();
  late ChatService chatService;
  bool? isDoctor;
  final Map<String, ImageProvider?> _userAvatars = {};

  @override
  void initState() {
    super.initState();
    chatService = ChatService();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    await _checkIfDoctor();
    await _loadAvatars();
  }

  Future<void> _checkIfDoctor() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final userDoc = await FirebaseFirestore.instance
          .collection('User')
          .doc(currentUser.uid)
          .get();

      if (mounted) {
        setState(() {
          isDoctor = userDoc.data()?['IsDoctor'] ?? false;
        });
      }
    } catch (e) {
      debugPrint('Error checking doctor status: $e');
    }
  }

  Future<void> _loadAvatars() async {
    try {
      // Load current user's avatar
      if (FirebaseAuth.instance.currentUser != null) {
        await _loadUserAvatar(FirebaseAuth.instance.currentUser!.uid);
      }
      // Load friend's avatar
      await _loadUserAvatar(widget.friendId);
    } catch (e) {
      debugPrint('Error loading avatars: $e');
    }
  }

  Future<void> _loadUserAvatar(String userId) async {
    try {
      final userDoc =
          await FirebaseFirestore.instance.collection('User').doc(userId).get();

      if (!userDoc.exists) {
        debugPrint('No user document found for ID: $userId');
        return;
      }

      final userData = userDoc.data();
      final avatarBase64 = userData?['avatar'] as String?;

      if (mounted && avatarBase64 != null && avatarBase64.isNotEmpty) {
        setState(() {
          try {
            final decodedImage =
                Base64ImageService().decodeBase64Image(avatarBase64);
            _userAvatars[userId] = MemoryImage(decodedImage);
            debugPrint('Successfully loaded avatar for user: $userId');
          } catch (e) {
            debugPrint('Error decoding avatar for user $userId: $e');
            _userAvatars[userId] = const AssetImage('assets/profile.jpg');
          }
        });
      } else {
        debugPrint('No avatar found for user: $userId, using default');
        if (mounted) {
          setState(() {
            _userAvatars[userId] = const AssetImage('assets/profile.jpg');
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading avatar for user $userId: $e');
      if (mounted) {
        setState(() {
          _userAvatars[userId] = const AssetImage('assets/profile.jpg');
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Sends the message via ChatService
  void _sendMessage(String conversationId, String message) async {
    try {
      await chatService.sendMessage(
        friendId: widget.friendId,
        message: message,
      );
      _controller.clear();
    } catch (e) {
      print("Error sending message: $e");
    }
  }

  Widget _buildAppBar(BuildContext context, AppLocalizations localizations) {
    return AppBar(
      title: Center(
        child: isDoctor == true
            ? ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SummarizeWebsocketScreen(
                        userId: widget.friendId, // Truyền userId của bệnh nhân
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black54,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(localizations.summary),
              )
            : null,
      ),
      backgroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.menu),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const LeftBar(),
            ),
          );
        },
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const RightBar(),
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final conversationId = chatService.generateConversationId(widget.friendId);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context, localizations) as PreferredSizeWidget,
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              // Changed to DocumentSnapshot
              stream: FirebaseFirestore.instance
                  .collection('Chats')
                  .doc(conversationId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return Center(child: Text(localizations.noMessageYet));
                }

                final chatData = snapshot.data!.data() as Map<String, dynamic>;
                final messages = (chatData['Messages'] as List<dynamic>? ?? [])
                    .map((msg) => msg as Map<String, dynamic>)
                    .toList();

                messages.sort((a, b) => (a['Timestamp'] as int)
                    .compareTo(b['Timestamp'] as int)); // Sort by timestamp

                return ListView.builder(
                  itemCount: messages.length,
                  reverse: true, // Show latest messages at the bottom
                  itemBuilder: (context, index) {
                    final message = messages[messages.length -
                        1 -
                        index]; // Reverse index for proper ordering
                    final isSender = message['SenderId'] ==
                        FirebaseAuth.instance.currentUser!.uid;
                    final senderId = message['SenderId'] as String;
                    final avatarImage = _userAvatars[senderId] ??
                        const AssetImage('assets/profile.jpg');

                    return Row(
                      mainAxisAlignment: isSender
                          ? MainAxisAlignment.end
                          : MainAxisAlignment.start,
                      children: [
                        if (!isSender)
                          Padding(
                            padding: const EdgeInsets.only(left: 10.0),
                            child: CircleAvatar(
                              backgroundColor: Colors.grey[300],
                              backgroundImage: avatarImage,
                              child: avatarImage is AssetImage
                                  ? Icon(Icons.person, color: Colors.grey[600])
                                  : null,
                            ),
                          ),
                        Flexible(
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                                vertical: 5, horizontal: 10),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isSender ? Colors.blue : Colors.grey[300],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              message['Message'] ?? '',
                              style: TextStyle(
                                color: isSender ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                        ),
                        if (isSender)
                          Padding(
                            padding: const EdgeInsets.only(right: 10.0),
                            child: CircleAvatar(
                              backgroundColor: Colors.grey[300],
                              backgroundImage: avatarImage,
                              child: avatarImage is AssetImage
                                  ? Icon(Icons.person, color: Colors.grey[600])
                                  : null,
                            ),
                          ),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // Message Input
          Container(
            margin: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(32),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: localizations.enterMessage,
                      hintStyle: TextStyle(
                        color: Colors.grey.withOpacity(1.0),
                        fontSize: 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(50),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 16),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    if (_controller.text.isNotEmpty) {
                      _sendMessage(conversationId, _controller.text);
                    }
                  },
                  icon: const Icon(Icons.arrow_circle_up),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
