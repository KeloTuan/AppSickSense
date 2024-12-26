import 'package:flutter/material.dart';
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

  void _sendMessage(String message) {
    setState(() {
      messages.add({
        'sender': 'user',
        'message': message,
      });
    });
    _controller.clear();
  }

  void _openLeftBar() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LeftBar()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Colors.white, // Thêm dòng này để thay đổi nền thành màu trắng
      appBar: AppBar(
        title: const Text('Chat với AI'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.menu), // Biểu tượng menu thay vì mũi tên
          onPressed: _openLeftBar, // Mở LeftBar khi nhấn
        ),
        actions: [RightButton(context)],
        backgroundColor: Colors.white,
      ),
      body: GestureDetector(
        onPanUpdate: (details) {
          // Check if the swipe is from left to right
          if (details.delta.dx > 10) {
            _openLeftBar();
          }
        },
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  bool isSender = messages[index]['sender'] == 'user';
                  return Row(
                    mainAxisAlignment: isSender
                        ? MainAxisAlignment.end
                        : MainAxisAlignment.start,
                    children: [
                      if (!isSender)
                        Container(
                          margin: const EdgeInsets.only(right: 10),
                          child: const CircleAvatar(
                            backgroundImage: AssetImage('assets/Duck.png'),
                            radius: 20,
                          ),
                        ),
                      Flexible(
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSender ? Colors.blue : Colors.grey,
                            borderRadius: BorderRadius.circular(10),
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
                      if (isSender)
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
              margin: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.black12, // Thay đổi màu nền theo ý bạn
                borderRadius: BorderRadius.circular(32), // Bo góc nếu cần
              ),
              padding: const EdgeInsets.all(0),
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
                                  Navigator.of(context).pop();
                                },
                                child: const Text("Hủy"),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
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
                      controller: _controller,
                      decoration: InputDecoration(
                        //filled: true,
                        //fillColor: const Color.fromARGB(255, 206, 228, 245),
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
                        _sendMessage(_controller.text);
                      }
                    },
                    icon: const Icon(Icons.arrow_circle_up),
                  ),
                ],
              ),
            ),
            //SizedBox(height: 10)
          ],
        ),
      ),
    );
  }
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
