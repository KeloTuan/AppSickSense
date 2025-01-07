import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sick_sense_mobile/summarize/summarize_websocket_service.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SummarizeWebsocketScreen extends StatefulWidget {
  final String? userId;

  const SummarizeWebsocketScreen({
    Key? key,
    this.userId,
  }) : super(key: key);

  @override
  _SummarizeWebsocketScreenState createState() =>
      _SummarizeWebsocketScreenState();
}

class _SummarizeWebsocketScreenState extends State<SummarizeWebsocketScreen> {
  late SummarizeWebSocketService _webSocketService;
  List<String> _messages = [];
  DateTime _selectedDate = DateTime.now();
  String? _effectiveUserId;

  @override
  void initState() {
    super.initState();
    _webSocketService =
        SummarizeWebSocketService("ws://localhost:8000/ws/summarize");
    _connectAndListen();
    _initializeUserId();
  }

  Future<void> _initializeUserId() async {
    if (widget.userId != null) {
      setState(() {
        _effectiveUserId = widget.userId;
      });
    } else {
      // Fallback to current user if no userId provided
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        setState(() {
          _effectiveUserId = currentUser.uid;
        });
      }
    }
  }

  void _connectAndListen() {
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

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _requestSummary() async {
    if (_effectiveUserId == null) {
      setState(() {
        _messages.add("Error: No user ID available");
      });
      return;
    }

    final startOfDay =
        DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('requests')
          .where('timestamp',
              isGreaterThanOrEqualTo: startOfDay.toIso8601String())
          .where('timestamp', isLessThan: endOfDay.toIso8601String())
          .where('user.id', isEqualTo: _effectiveUserId)
          .get();

      if (querySnapshot.docs.isEmpty) {
        setState(() {
          _messages.add("No conversations found for selected date");
        });
        return;
      }

      final requestData = {
        "user_id": _effectiveUserId,
        "timestamp": DateFormat('yyyy-MM-dd').format(_selectedDate),
      };

      _webSocketService.sendMessage(requestData);
    } catch (e) {
      setState(() {
        _messages.add("Error: $e");
      });
    }
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
        title: const Text('Conversation Summary'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => _selectDate(context),
                  child: Text(DateFormat('yyyy-MM-dd').format(_selectedDate)),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _effectiveUserId != null ? _requestSummary : null,
                  child: const Text('Get Summary'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(_messages[index]),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
