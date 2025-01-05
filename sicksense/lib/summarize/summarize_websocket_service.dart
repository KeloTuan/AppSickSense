import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

class SummarizeWebSocketService {
  final String uri;
  late WebSocketChannel _channel;

  SummarizeWebSocketService(this.uri);

  void connect() {
    _channel = WebSocketChannel.connect(Uri.parse(uri));
  }

  void sendMessage(Map<String, dynamic> message) {
    final jsonMessage = jsonEncode(message);
    _channel.sink.add(jsonMessage);
  }

  Stream<dynamic> getMessages() {
    return _channel.stream;
  }

  void closeConnection() {
    _channel.sink.close(status.goingAway);
  }
}
