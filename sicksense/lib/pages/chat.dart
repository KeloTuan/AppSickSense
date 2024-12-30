import 'package:flutter/material.dart';
import 'package:sick_sense_mobile/nav_bar/leftBar.dart';
import 'package:sick_sense_mobile/nav_bar/rightbar.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
      MaterialPageRoute(builder: (context) => const LeftBar()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Use AppLocalizations to get translated text
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(localizations
            .chatWithAI), // Get the localized string for 'Chat with AI'
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: _openLeftBar,
        ),
        actions: [RightButton(context)],
        backgroundColor: Colors.white,
      ),
      body: GestureDetector(
        onPanUpdate: (details) {
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
                color: Colors.black12,
                borderRadius: BorderRadius.circular(32),
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
                            title: Text(
                                localizations.warning), // Translated 'Warning'
                            content: Text(localizations
                                .newConversationPrompt), // Translated 'Do you want to create a new conversation?'

                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },

                                child: Text(localizations
                                    .cancel), // Translated 'Cancel'
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },

                                child: Text(localizations
                                    .confirm), // Translated 'Confirm'
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
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(50),
                          borderSide: BorderSide.none,
                        ),

                        hintText: localizations
                            .enterMessage, // Translated 'Enter your message'

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
        MaterialPageRoute(builder: (context) => const RightBar()),
      );
    },
    icon: const Icon(Icons.more_vert),
  );
}
