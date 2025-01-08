import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:sick_sense_mobile/nav_bar/leftBar.dart';
import 'package:sick_sense_mobile/nav_bar/rightbar.dart';
import 'package:sick_sense_mobile/summarize/summarize_websocket_screen.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WebSocketScreen extends StatefulWidget {
  @override
  _WebSocketScreenState createState() => _WebSocketScreenState();
}

class _WebSocketScreenState extends State<WebSocketScreen> {
  late WebSocketChannel _channel;
  final TextEditingController _controller = TextEditingController();
  List<String> _responses = [];
  bool _isConnected = false;
  late User _currentUser;
  Map<String, dynamic>? _userData;
  List<bool> _isUserQuery = [];

  @override
  void initState() {
    super.initState();
    _connectWebSocket();
    _getCurrentUser();
  }

  void _getCurrentUser() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _currentUser = user;
      });
      await _fetchUserData();
    }
  }

  Future<void> _fetchUserData() async {
    final firestore = FirebaseFirestore.instance;
    final userDoc =
        await firestore.collection('User').doc(_currentUser.uid).get();

    if (userDoc.exists) {
      setState(() {
        _userData = userDoc.data();
      });
    }
  }

  Future<String> _getCurrentUserName() async {
    if (_userData != null) {
      return _userData!['Name'] ?? 'Unknown User';
    }
    return 'Unknown User';
  }

  void _sendRequest() async {
    if (_currentUser != null &&
        _userData != null &&
        _controller.text.isNotEmpty) {
      final requestData = {
        "query": _controller.text,
        "metadata": {
          "timestamp": DateTime.now().toString(),
          "user": {
            "id": _currentUser.uid,
            "name": _userData!['Name'],
            "email": _userData!['Email'],
            "gender": _userData!['Gender']
          }
        }
      };

      // Lưu dữ liệu đầy đủ vào Firestore
      await FirebaseFirestore.instance.collection('requests').add({
        "query": _controller.text,
        "timestamp": DateTime.now().toString(),
        "user": {
          "id": _currentUser.uid,
          "name": _userData!['Name'],
          "email": _userData!['Email'],
          "gender": _userData!['Gender']
        },
      });

      // Gửi dữ liệu qua WebSocket
      _channel.sink.add(jsonEncode(requestData));

      // Cập nhật danh sách
      setState(() {
        _responses.add(_controller.text); // Thêm câu query
        _isUserQuery.add(true); // Đánh dấu là query của người dùng
      });

      _controller.clear(); // Xóa nội dung ô nhập
    }
  }

  void _connectWebSocket() {
    final uri = Uri.parse("ws://192.168.1.16:8123/ws/query");
    print("Connecting to websocket at: $uri");
    try {
      _channel = WebSocketChannel.connect(uri);

      String buffer = ""; // Bộ đệm để ghép dữ liệu từ server

      _channel.stream.listen((response) {
        setState(() {
          buffer += response; // Ghép đoạn dữ liệu vào bộ đệm

          // Kiểm tra nếu response chứa tín hiệu kết thúc (tuỳ vào cấu trúc của server)
          if (response.endsWith("\n") || response.endsWith("\r")) {
            // Khi nhận đủ nội dung, thêm vào danh sách hiển thị
            _responses.add(buffer.trim());
            _isUserQuery.add(false); // Đánh dấu là phản hồi từ server

            // Xóa bộ đệm sau khi đã xử lý
            buffer = "";
          }
        });
      }, onError: (error) {
        setState(() {
          _responses.add("Error: $error");
          _isUserQuery.add(false);
        });
      }, onDone: () {
        setState(() {
          _responses.add("Connection closed.");
          _isUserQuery.add(false);
        });
      });

      setState(() {
        _isConnected = true;
      });
    } catch (e) {
      setState(() {
        _responses.add("Connection error: $e");
        _isUserQuery.add(false);
        _isConnected = false;
      });
    }
  }

  @override
  void dispose() {
    _channel.sink.close();
    _controller.dispose();
    super.dispose();
  }

  // Hàm xử lý in đậm các đoạn văn bản giữa dấu **
  Text _formatResponse(String response) {
    List<TextSpan> textSpans = [];
    bool isBold = false; // Trạng thái để kiểm tra có in đậm hay không
    int start = 0;

    for (int i = 0; i < response.length; i++) {
      if (response[i] == '*' &&
          i + 1 < response.length &&
          response[i + 1] == '*') {
        // Khi gặp dấu **, tạo TextSpan với phần trước đó
        if (start < i) {
          textSpans.add(TextSpan(
            text: response.substring(start, i),
            style: TextStyle(
                color: Colors.white,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal),
          ));
        }
        isBold = !isBold; // Đổi trạng thái in đậm
        i++; // Bỏ qua ký tự tiếp theo vì đã xử lý dấu **
        start = i + 1; // Cập nhật điểm bắt đầu của chuỗi tiếp theo
      }
    }

    // Thêm phần còn lại của chuỗi
    if (start < response.length) {
      textSpans.add(TextSpan(
        text: response.substring(start),
        style: TextStyle(
            color: Colors.white,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal),
      ));
    }

    return Text.rich(TextSpan(children: textSpans));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Nhắn tin AI'),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const LeftBar()),
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RightBar()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _responses.isEmpty ? 0 : _responses.length,
              itemBuilder: (context, index) {
                if (_responses.isEmpty) {
                  return const Center(child: Text("No data available"));
                }

                bool isUserQuery =
                    _isUserQuery.isEmpty ? false : _isUserQuery[index];

                return Row(
                  mainAxisAlignment: isUserQuery
                      ? MainAxisAlignment.end
                      : MainAxisAlignment.start,
                  children: [
                    if (!isUserQuery)
                      const CircleAvatar(
                        backgroundImage: AssetImage('assets/profile.jpg'),
                      ),
                    Container(
                      margin: const EdgeInsets.symmetric(
                          vertical: 5, horizontal: 8),
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(
                        maxWidth: 300, // Điều chỉnh giới hạn chiều rộng
                      ),
                      decoration: BoxDecoration(
                        color: isUserQuery ? Colors.blue : Colors.grey,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: _formatResponse(_responses[index]
                          // style: const TextStyle(color: Colors.white),
                          // softWrap: true, // Cho phép xuống dòng tự động
                          // overflow:
                          //     TextOverflow.visible, // Đảm bảo không cắt nội dung
                          ),
                    ),
                    if (isUserQuery)
                      const CircleAvatar(
                        backgroundImage: AssetImage('assets/profile.jpg'),
                      ),
                  ],
                );
              },
            ),
          ),

          // Query input section
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
                      hintText: 'Enter your query...',
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
                  onPressed: _isConnected ? _sendRequest : null,
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
