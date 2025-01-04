import 'package:flutter/material.dart';
import 'package:sick_sense_mobile/summarize/summarize_websocket_service.dart';

class SummarizeWebsocketScreen extends StatefulWidget {
  const SummarizeWebsocketScreen({Key? key}) : super(key: key);

  @override
  _SummarizeWebsocketScreenState createState() =>
      _SummarizeWebsocketScreenState();
}

class _SummarizeWebsocketScreenState extends State<SummarizeWebsocketScreen> {
  late SummarizeWebSocketService _webSocketService;
  List<String> _messages = [];

  @override
  void initState() {
    super.initState();
    _webSocketService =
        SummarizeWebSocketService("ws://localhost:8000/ws/summarize");
    _webSocketService.connect();
    _webSocketService.getMessages().listen((message) {
      setState(() {
        _messages.add(message.toString());
      });
      if (message == "END") {
        _webSocketService.closeConnection();
      }
    }, onError: (error) {
      setState(() {
        _messages.add("Error: $error");
      });
    }, onDone: () {
      setState(() {
        _messages.add("Connection closed.");
      });
    });
  }

  void _sendRequest() {
    final requestData = {
      "user_id": "12345",
      "timestamp": "02/01/2025 12:00:00"
    };
    _webSocketService.sendMessage(requestData);
  }

  @override
  void dispose() {
    _webSocketService.closeConnection();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WebSocket Test'),
      ),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: _sendRequest,
            child: const Text('Send Request'),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_messages[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
