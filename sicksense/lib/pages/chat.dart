import 'package:flutter/material.dart';
import 'package:sick_sense_mobile/nav_bar/leftBar.dart';
import 'package:sick_sense_mobile/nav_bar/rightbar.dart';

class Chat extends StatefulWidget {
  const Chat({super.key});

  @override
  State<Chat> createState() => _ChatState();
}

class _ChatState extends State<Chat> {
  final List<Map<String, String>> messages = []; // List to store chat messages
  final TextEditingController _controller =
      TextEditingController(); // Controller for TextField

  // Function to add message
  void _sendMessage(String message) {
    setState(() {
      messages.add({
        'sender': 'user', // 'user' for the sender, 'replier' for the AI
        'message': message,
      });
    });
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat với AI'),
        centerTitle: true,
        leading: LeftButton(context),
        actions: [RightButton(context)],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                bool isSender = messages[index]['sender'] ==
                    'user'; // Check if the sender is the user
                return Row(
                  mainAxisAlignment: isSender
                      ? MainAxisAlignment.end
                      : MainAxisAlignment.start,
                  children: [
                    // Avatar
                    if (!isSender) // If it's not the sender (i.e., AI reply), show on the right
                      Container(
                        margin: const EdgeInsets.only(right: 10),
                        child: const CircleAvatar(
                          backgroundImage: AssetImage('assets/Duck.png'),
                          radius: 20,
                        ),
                      ),
                    // Message bubble
                    Flexible(
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSender
                              ? Colors.blue
                              : Colors
                                  .grey, // Blue for sender, grey for AI reply
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),
                        padding: const EdgeInsets.all(8.0),
                        margin: const EdgeInsets.symmetric(
                            vertical: 5.0, horizontal: 10.0),
                        child: Text(
                          messages[index]['message']!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16.0,
                          ),
                        ),
                      ),
                    ),
                    if (isSender) // If it's the sender, show the avatar on the left
                      Container(
                        margin: const EdgeInsets.only(left: 10),
                        child: const CircleAvatar(
                          backgroundImage: AssetImage('assets/Duck.png'),
                          radius: 20,
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                IconButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text("Cảnh báo"),
                          content:
                              const Text("Bạn muốn tạo cuộc trò chuyện mới?"),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop(); // Close the dialog
                              },
                              child: const Text("Hủy"),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                // Add your logic for creating a new chat here
                                Navigator.of(context).pop(); // Close the dialog
                              },
                              child: const Text("Đồng ý"),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  icon: const Icon(Icons.add),
                ),
                Expanded(
                  child: TextField(
                    controller: _controller, // Link the controller
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color.fromARGB(255, 206, 228, 245),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(50),
                        borderSide: BorderSide.none,
                      ),
                      hintText: 'Nhập tin nhắn',
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  onPressed: () {
                    if (_controller.text.isNotEmpty) {
                      _sendMessage(_controller.text); // Send message
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

Widget LeftButton(BuildContext context) {
  return IconButton(
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => LeftBar()),
      );
    },
    icon: const Icon(Icons.menu),
  );
}

Widget RightButton(BuildContext context) {
  return IconButton(
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => RightBar()),
      );
    },
    icon: const Icon(Icons.more_vert),
  );
}
