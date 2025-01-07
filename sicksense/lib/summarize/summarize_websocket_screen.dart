// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:sick_sense_mobile/summarize/summarize_websocket_service.dart';
// import 'package:intl/intl.dart';
// import 'package:firebase_auth/firebase_auth.dart';

// class SummarizeWebsocketScreen extends StatefulWidget {
//   final String? userId;

//   const SummarizeWebsocketScreen({
//     Key? key,
//     required this.userId,
//   }) : super(key: key);

//   @override
//   _SummarizeWebsocketScreenState createState() =>
//       _SummarizeWebsocketScreenState();
// }

// class _SummarizeWebsocketScreenState extends State<SummarizeWebsocketScreen> {
//   late SummarizeWebSocketService _webSocketService;
//   List<String> _messages = [];
//   DateTime _selectedDate = DateTime.now();
//   String? _effectiveUserId;

//   @override
//   void initState() {
//     super.initState();
//     _webSocketService =
//         SummarizeWebSocketService("ws://192.168.1.16:8123/ws/summarize");
//     _connectAndListen();
//     _initializeUserId();
//   }

//   Future<void> _initializeUserId() async {
//     if (widget.userId != null) {
//       setState(() {
//         _effectiveUserId = widget.userId;
//       });
//     } else {
//       // Fallback to current user if no userId provided
//       final currentUser = FirebaseAuth.instance.currentUser;
//       if (currentUser != null) {
//         setState(() {
//           _effectiveUserId = currentUser.uid;
//         });
//       }
//     }
//   }

//   void _connectAndListen() {
//     _webSocketService.connect();
//     _webSocketService.getMessages().listen(
//       (message) {
//         setState(() {
//           _messages.add(message.toString());
//         });
//         if (message == "END") {
//           _webSocketService.closeConnection();
//         }
//       },
//       onError: (error) {
//         setState(() {
//           _messages.add("Error: $error");
//         });
//       },
//       onDone: () {
//         setState(() {
//           _messages.add("Connection closed.");
//         });
//       },
//     );
//   }

//   Future<void> _selectDate(BuildContext context) async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: _selectedDate,
//       firstDate: DateTime(2000),
//       lastDate: DateTime.now(),
//     );
//     if (picked != null && picked != _selectedDate) {
//       setState(() {
//         _selectedDate = picked;
//       });
//     }
//   }

//   Future<void> _requestSummary() async {
//     if (_effectiveUserId == null) {
//       setState(() {
//         _messages.add("Error: No user ID available");
//       });
//       return;
//     }

//     final startOfDay =
//         DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
//     final endOfDay = startOfDay.add(const Duration(days: 1));

//     try {
//       print("Start of day: $startOfDay");
//       print("End of day: $endOfDay");

//       final querySnapshot = await FirebaseFirestore.instance
//           .collection('requests')
//           .where('timestamp',
//               isGreaterThanOrEqualTo: startOfDay.toIso8601String())
//           .where('timestamp', isLessThan: endOfDay.toIso8601String())
//           .where('user.id', isEqualTo: _effectiveUserId) // Lọc theo user_id
//           .get();

//       print("Query snapshot docs: ${querySnapshot.docs.length}");

//       if (querySnapshot.docs.isEmpty) {
//         setState(() {
//           _messages.add("No conversations found for selected date");
//         });
//         return;
//       }

//       final requestData = {
//         "user_id": _effectiveUserId,
//         "timestamp": DateFormat('yyyy-MM-dd').format(_selectedDate),
//       };

//       _webSocketService.sendMessage(requestData); // Send the request data
//     } catch (e) {
//       setState(() {
//         _messages.add("Error: $e");
//       });
//     }
//   }

//   @override
//   void dispose() {
//     _webSocketService.closeConnection();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Conversation Summary'),
//       ),
//       body: Column(
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 ElevatedButton(
//                   onPressed: () => _selectDate(context),
//                   child: Text(DateFormat('yyyy-MM-dd').format(_selectedDate)),
//                 ),
//                 const SizedBox(width: 16),
//                 ElevatedButton(
//                   onPressed: _effectiveUserId != null ? _requestSummary : null,
//                   child: const Text('Get Summary'),
//                 ),
//               ],
//             ),
//           ),
//           Expanded(
//             child: ListView.builder(
//               itemCount: _messages.length,
//               itemBuilder: (context, index) {
//                 return Padding(
//                   padding: const EdgeInsets.all(8.0),
//                   child: Card(
//                     child: Padding(
//                       padding: const EdgeInsets.all(16.0),
//                       child: Text(_messages[index]),
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:intl/intl.dart';

class SummarizeWebsocketScreen extends StatefulWidget {
  final String userId;

  const SummarizeWebsocketScreen({Key? key, required this.userId})
      : super(key: key);

  @override
  _SummarizeWebsocketScreenState createState() =>
      _SummarizeWebsocketScreenState();
}

class _SummarizeWebsocketScreenState extends State<SummarizeWebsocketScreen> {
  late WebSocketChannel _channel;
  bool _isConnected = false;
  List<String> _responses = [];
  String _buffer = "";
  DateTime? _selectedDate;
  List<bool> _isUserQuery = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _connectWebSocket();
  }

  void _connectWebSocket() {
    final uri = Uri.parse("ws://192.168.1.16:8123/ws/summarize");
    print("Connecting to websocket at: $uri");
    try {
      _channel = WebSocketChannel.connect(uri);

      String buffer = "";

      _channel.stream.listen((response) {
        setState(() {
          buffer += response;

          if (response.endsWith("\n") || response.endsWith("\r")) {
            _responses.add(buffer.trim());
            _isUserQuery.add(false);
            buffer = "";
            _isLoading = false; // Tắt loading khi nhận được response
          }
        });
      }, onError: (error) {
        setState(() {
          _responses.add("Error: $error");
          _isUserQuery.add(false);
          _isLoading = false;
        });
      }, onDone: () {
        setState(() {
          //_responses.add("Connection closed.");
          _isUserQuery.add(false);
          _isLoading = false;
        });
      });

      setState(() {
        _isConnected = true;
      });
    } catch (e) {
      setState(() {
        _responses.add("Connection error: $e");
        _isConnected = false;
        _isLoading = false;
      });
    }
  }

  void _sendRequest() {
    final requestData = {
      "user_id": widget.userId,
      "timestamp": _selectedDate != null
          ? DateFormat("yyyy-MM-dd").format(_selectedDate!)
          : "N/A",
    };
    print(requestData);
    _channel.sink.add(jsonEncode(requestData));
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // Hàm xử lý định dạng văn bản đã được cập nhật
  Widget _formatResponse(String response) {
    List<InlineSpan> spans = [];
    List<String> parts = response.split('**');

    for (int i = 0; i < parts.length; i++) {
      if (parts[i].isEmpty) continue;

      spans.add(TextSpan(
        text: parts[i],
        style: TextStyle(
          fontSize: 14,
          height: 1.5,
          color: Colors.black87,
          fontWeight: i % 2 == 1 ? FontWeight.bold : FontWeight.normal,
        ),
      ));
    }

    return RichText(
      text: TextSpan(children: spans),
      textAlign: TextAlign.left,
    );
  }

  @override
  void dispose() {
    _channel.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.blue,
        title: const Text(
          'Daily Summary',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isConnected ? Icons.wifi : Icons.wifi_off,
              color: _isConnected ? Colors.green : Colors.red,
            ),
            onPressed: () {
              if (!_isConnected) _connectWebSocket();
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        "Select Date for Summary",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: _pickDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.blue.shade200),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.calendar_today,
                                  color: Colors.blue.shade700),
                              const SizedBox(width: 8),
                              Text(
                                _selectedDate != null
                                    ? DateFormat("yyyy-MM-dd")
                                        .format(_selectedDate!)
                                    : "Choose Date",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _selectedDate == null || _isLoading
                            ? null
                            : () {
                                setState(() => _isLoading = true);
                                _sendRequest();
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_isLoading)
                              Container(
                                width: 16,
                                height: 16,
                                margin: const EdgeInsets.only(right: 8),
                                child: const CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                            const Text(
                              'Get Summary',
                              style:
                                  TextStyle(fontSize: 16, color: Colors.black),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: _responses.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.summarize,
                            size: 64,
                            color: Colors.blue.shade200,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Select a date to view summary',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _responses.length,
                      itemBuilder: (context, index) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      _isUserQuery[index]
                                          ? Icons.person
                                          : Icons.computer,
                                      size: 20,
                                      color: Colors.blue.shade700,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _isUserQuery[index]
                                          ? 'Your Query'
                                          : 'Summary',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                _formatResponse(_responses[index]),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
