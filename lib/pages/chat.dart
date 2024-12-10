import 'package:flutter/material.dart';
// import 'package:sicksense/left_bar/leftBar.dart';
// import 'package:sicksense/right_bar/rightbar.dart';

class Chat extends StatefulWidget {
  const Chat({super.key});

  @override
  State<Chat> createState() => _ChatState();
}

class _ChatState extends State<Chat> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat với AI'),
        centerTitle: true,
        leading: LeftButton(context), // Truyền context vào
        actions: [RightButton(context)],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              children: [
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                      padding: const EdgeInsets.all(8.0),
                      child: const Text(
                        'Chào AI',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      margin: const EdgeInsets.only(right: 15),
                      child: const CircleAvatar(
                        backgroundImage: AssetImage('assets/Duck.png'),
                        radius: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(left: 15),
                      child: const CircleAvatar(
                        backgroundImage: AssetImage('assets/Duck.png'),
                        radius: 20,
                      ),
                    ),
                    Container(
                      decoration: const BoxDecoration(
                        color: Colors.grey,
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                      padding: const EdgeInsets.all(8.0),
                      margin: const EdgeInsets.all(10),
                      child: const Text(
                        'Chào bạn, tôi có thể giúp gì cho bạn',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.0,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.add),
                ),
                Expanded(
                  child: TextField(
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
                  onPressed: () {},
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
      // Điều hướng tới trang LeftBar
      // Navigator.push(
      //   context,
      //   MaterialPageRoute(builder: (context) => LeftBar()),
      // );
    },
    icon: const Icon(Icons.menu),
  );
}

Widget RightButton(BuildContext context) {
  return IconButton(
    onPressed: () {
      // Navigator.push(
      //   context,
      //   MaterialPageRoute(builder: (context) => RightBar()),
      // );
    },
    icon: const Icon(Icons.more_vert),
  );
}
