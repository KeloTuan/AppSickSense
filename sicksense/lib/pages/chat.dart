import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sick_sense_mobile/nav_bar/leftBar.dart';
import 'package:sick_sense_mobile/nav_bar/rightbar.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:sick_sense_mobile/pages/chat_service.dart';
import 'package:sick_sense_mobile/summarize/summarize_websocket_screen.dart';

class Chat extends StatefulWidget {
  final String friendId;

  const Chat({super.key, required this.friendId});

  @override
  State<Chat> createState() => _ChatState();
}

class _ChatState extends State<Chat> {
  final TextEditingController _controller = TextEditingController();
  late String conversationId;
  late ChatService chatService;
  bool? isDoctor;

  @override
  void initState() {
    super.initState();
    chatService = ChatService();
    conversationId = chatService.generateConversationId(widget.friendId);
    _checkIfDoctor();
  }

  Future<void> _checkIfDoctor() async {
    final firestore = FirebaseFirestore.instance;
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      final userDoc =
          await firestore.collection('User').doc(currentUser.uid).get();
      if (userDoc.exists) {
        setState(() {
          isDoctor = userDoc.data()?['IsDoctor'] ?? false;
        });
      }
    }
  }

  void _sendMessage(String message) async {
    if (message.isNotEmpty) {
      await chatService.sendMessage(conversationId, message, widget.friendId);
      _controller.clear();
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

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context, localizations) as PreferredSizeWidget,
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: chatService.getMessages(conversationId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.data == null || snapshot.data!.isEmpty) {
                  return Center(child: Text(localizations.noMessageYet));
                }

                final messages = snapshot.data!;

                return ListView.builder(
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    var message = messages[index];
                    bool isSender = message['sender'] ==
                        FirebaseAuth.instance.currentUser!.uid;
                    return Row(
                      mainAxisAlignment: isSender
                          ? MainAxisAlignment.end
                          : MainAxisAlignment.start,
                      children: [
                        if (!isSender)
                          const Padding(
                            padding: EdgeInsets.only(left: 10.0),
                            child: CircleAvatar(
                              backgroundImage: AssetImage('assets/profile.jpg'),
                            ),
                          ),
                        Container(
                          margin: const EdgeInsets.symmetric(
                              vertical: 5, horizontal: 10),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSender ? Colors.blue : Colors.grey,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(message['message'],
                              style: const TextStyle(color: Colors.white)),
                        ),
                        if (isSender)
                          const Padding(
                            padding: EdgeInsets.only(right: 10.0),
                            child: CircleAvatar(
                              backgroundImage: AssetImage('assets/profile.jpg'),
                            ),
                          ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
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
                      _sendMessage(_controller.text);
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
