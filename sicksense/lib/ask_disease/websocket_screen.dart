import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:sick_sense_mobile/nav_bar/leftBar.dart';
import 'package:sick_sense_mobile/nav_bar/rightbar.dart';
import 'package:sick_sense_mobile/summarize/summarize_websocket_screen.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WebSocketScreen extends StatefulWidget {
  const WebSocketScreen({super.key});

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
    final uri = Uri.parse("ws://26.223.117.204:8000/ws/query");
    print("Connecting to websocket at: $uri");
    try {
      _channel = WebSocketChannel.connect(uri);

      _channel.stream.listen((response) {
        setState(() {
          _responses.add(response); // Thêm phản hồi từ WebSocket
          _isUserQuery.add(false); // Đánh dấu là phản hồi từ server
        });
        if (response == "END") {
          _channel.sink.close();
        }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Nhắn tin AI'),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const SummarizeWebsocketScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black54,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Tóm tắt'),
            ),
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
                      const Padding(
                        padding: EdgeInsets.only(
                            left:
                                10.0), // Add right margin to avoid it being too close to the edge
                        child: CircleAvatar(
                          backgroundImage: AssetImage('assets/profile.jpg'),
                        ),
                      ),
                    Container(
                      margin: const EdgeInsets.symmetric(
                          vertical: 5,
                          horizontal: 8), // Điều chỉnh khoảng cách hai bên
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(
                          maxWidth: 280), // Đặt chiều rộng tối đa
                      decoration: BoxDecoration(
                        color: isUserQuery ? Colors.blue : Colors.grey,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _responses[index],
                        style: const TextStyle(color: Colors.white),
                        softWrap: true,
                        overflow: TextOverflow.visible,
                      ),
                    ),
                    if (isUserQuery)
                      const Padding(
                        padding: EdgeInsets.only(
                            right:
                                10.0), // Add right margin to avoid it being too close to the edge
                        child: CircleAvatar(
                          backgroundImage: AssetImage('assets/profile.jpg'),
                        ),
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
                      hintText: 'Enter your message...',
                      hintStyle: TextStyle(
                        color: Colors.grey
                            .withOpacity(1.0), // Chỉnh màu mờ cho hintText
                        fontSize: 16, // Chỉnh kích thước chữ nếu cần
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

// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:web_socket_channel/web_socket_channel.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// class WebSocketScreen extends StatefulWidget {
//   @override
//   _WebSocketScreenState createState() => _WebSocketScreenState();
// }

// class _WebSocketScreenState extends State<WebSocketScreen> {
//   late WebSocketChannel _channel;
//   final TextEditingController _controller = TextEditingController();
//   List<String> _responses = [];
//   bool _isConnected = false;
//   late User _currentUser;
//   Map<String, dynamic>? _userData;

//   @override
//   void initState() {
//     super.initState();
//     _connectWebSocket();
//     _getCurrentUser();
//   }

//   void _getCurrentUser() async {
//     final User? user = FirebaseAuth.instance.currentUser;
//     if (user != null) {
//       setState(() {
//         _currentUser = user;
//       });
//       await _fetchUserData();
//     }
//   }

//   Future<void> _fetchUserData() async {
//     final firestore = FirebaseFirestore.instance;
//     final userDoc =
//         await firestore.collection('User').doc(_currentUser.uid).get();

//     if (userDoc.exists) {
//       setState(() {
//         _userData = userDoc.data();
//       });
//     }
//   }

//   Future<String> _getCurrentUserName() async {
//     if (_userData != null) {
//       return _userData!['Name'] ?? 'Unknown User';
//     }
//     return 'Unknown User';
//   }

//   void _connectWebSocket() {
//     final uri = Uri.parse("ws://26.223.117.204:8000/ws/query");
//     print("Connecting to websocket at: $uri");
//     try {
//       _channel = WebSocketChannel.connect(uri);

//       _channel.stream.listen((response) {
//         setState(() {
//           _responses.add(response);
//         });
//         if (response == "END") {
//           _channel.sink.close();
//         }
//       }, onError: (error) {
//         setState(() {
//           _responses.add("Error: $error");
//         });
//       }, onDone: () {
//         setState(() {
//           _responses.add("Connection closed.");
//         });
//       });

//       setState(() {
//         _isConnected = true;
//       });
//     } catch (e) {
//       setState(() {
//         _responses.add("Connection error: $e");
//         _isConnected = false;
//       });
//     }
//   }

//   void _sendRequest() async {
//     if (_currentUser != null && _userData != null) {
//       final requestData = {
//         "query": _controller.text,
//         "metadata": {
//           "timestamp": DateTime.now().toString(),
//           "user": {
//             "id": _currentUser.uid,
//             "name": _userData!['Name'],
//             "email": _userData!['Email'],
//             "gender": _userData!['Gender']
//           }
//         }
//       };

//       await FirebaseFirestore.instance.collection('requests').add({
//         "query": _controller.text,
//         "timestamp": DateTime.now().toString(),
//         "user": {
//           "id": _currentUser.uid,
//           "name": _userData!['Name'],
//           "email": _userData!['Email'],
//           "gender": _userData!['Gender']
//         },
//       });
//       _channel.sink.add(jsonEncode(requestData));
//       setState(() {
//         _responses.add("Sent: ${jsonEncode(requestData)}");
//       });
//     }
//   }

//   @override
//   void dispose() {
//     _channel.sink.close();
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('WebSocket Example'),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           children: <Widget>[
//             FutureBuilder<String>(
//               future: _getCurrentUserName(),
//               builder: (context, snapshot) {
//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return CircularProgressIndicator();
//                 } else if (snapshot.hasError) {
//                   return Text('Error: ${snapshot.error}');
//                 } else {
//                   return Text('Welcome, ${snapshot.data}');
//                 }
//               },
//             ),
//             SizedBox(height: 10),
//             TextField(
//               controller: _controller,
//               decoration: InputDecoration(labelText: 'Enter Query'),
//             ),
//             SizedBox(height: 10),
//             ElevatedButton(
//               onPressed: _isConnected ? _sendRequest : null,
//               child: Text('Send Request'),
//             ),
//             SizedBox(height: 20),
//             Text('Response from server:'),
//             SizedBox(height: 10),
//             Expanded(
//               child: ListView.builder(
//                 itemCount: _responses.length,
//                 itemBuilder: (context, index) {
//                   return Text(_responses[index]);
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
