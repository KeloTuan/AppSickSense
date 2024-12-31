import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:sick_sense_mobile/nav_bar/leftBar.dart';
import 'package:sick_sense_mobile/nav_bar/rightbar.dart';

class Chat extends StatefulWidget {
  const Chat({super.key});

  @override
  State<Chat> createState() => _ChatState();
}

class _ChatState extends State<Chat> {
  final List<Map<String, String>> messages = [];
  final TextEditingController _controller = TextEditingController();
  String chatTitle = "Chat với AI";
  String? doctorName;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _sendMessage(String message) {
    final currentUser = FirebaseAuth.instance.currentUser;

    // Kiểm tra nếu người dùng đã đăng nhập
    if (currentUser == null) {
      print('User not logged in');
      return;
    }

    // Lưu tin nhắn vào Firestore
    FirebaseFirestore.instance.collection('chats').add({
      'sender': currentUser.displayName ?? 'User', // Tên người gửi
      'message': message, // Nội dung tin nhắn
      'doctorName': doctorName ?? 'AI', // Tên bác sĩ (hoặc AI)
      'timestamp': FieldValue.serverTimestamp(), // Thời gian gửi tin nhắn
    }).then((value) {
      print("Message sent successfully!");
    }).catchError((error) {
      print("Failed to send message: $error");
    });
  }

  void _openLeftBar() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LeftBar(onDoctorSelected: _startChatWithDoctor),
      ),
    );
  }

  void _startChatWithDoctor(String name) {
    setState(() {
      chatTitle = "Chat với Bác sĩ: $name";
      doctorName = name;
      messages.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(chatTitle),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: _openLeftBar,
        ),
        actions: [RightButton(context)],
        backgroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
              child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('chats')
                .orderBy('timestamp') // Sắp xếp theo thời gian
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("No messages"));
              }

              final messagesData = snapshot.data!.docs;
              return ListView.builder(
                itemCount: messagesData.length,
                itemBuilder: (context, index) {
                  final message = messagesData[index];
                  final isSender = message['sender'] ==
                      'User'; // Kiểm tra nếu là người gửi (User)
                  return Row(
                    mainAxisAlignment: isSender
                        ? MainAxisAlignment.end // Người gửi sẽ ở bên phải
                        : MainAxisAlignment.start, // Người nhận sẽ ở bên trái
                    children: [
                      if (!isSender) // Nếu là tin nhắn của người nhận (doctor)
                        const CircleAvatar(
                          backgroundImage: AssetImage('assets/doctor_icon.png'),
                          radius: 20,
                        ),
                      Flexible(
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSender
                                ? Colors.blue
                                : Colors.grey, // Màu cho tin nhắn
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.all(8.0),
                          margin: const EdgeInsets.symmetric(
                              vertical: 5.0, horizontal: 10.0),
                          child: Text(
                            message['message']!, // Nội dung tin nhắn
                            style: const TextStyle(
                                color: Colors.white, fontSize: 16.0),
                          ),
                        ),
                      ),
                      if (isSender) // Nếu là tin nhắn của người gửi (User), hiển thị avatar của người gửi
                        const CircleAvatar(
                          backgroundImage: AssetImage('assets/user_icon.png'),
                          radius: 20,
                        ),
                    ],
                  );
                },
              );
            },
          )),
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
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(50),
                        borderSide: BorderSide.none,
                      ),
                      hintText: localizations.enterMessage,
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

Widget RightButton(BuildContext context) {
  return IconButton(
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const RightBar()),
      );
    },
    icon: const Icon(Icons.more_vert),
  );
}
