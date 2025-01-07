import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

class SummarizeWebSocketService {
  late WebSocketChannel _channel;

  // Hàm để kết nối với WebSocket
  void connect(String url) {
    _channel = WebSocketChannel.connect(Uri.parse(url));
  }

  // Hàm gửi tin nhắn qua WebSocket
  void sendMessage(String message) {
    _channel.sink.add(message);
  }

  // Stream nhận các tin nhắn từ WebSocket
  Stream<dynamic> get messages => _channel.stream;

  // Hàm đóng kết nối WebSocket
  void disconnect() {
    _channel.sink.close();
  }
}
