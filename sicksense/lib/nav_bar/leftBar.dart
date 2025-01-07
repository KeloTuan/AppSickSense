import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sick_sense_mobile/pages/chat.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:sick_sense_mobile/ask_disease/websocket_screen.dart';

class LeftBar extends StatelessWidget {
  const LeftBar({super.key});

  Future<bool> _isCurrentUserDoctor() async {
    final firestore = FirebaseFirestore.instance;
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      final userDoc =
          await firestore.collection('User').doc(currentUser.uid).get();
      if (userDoc.exists) {
        return userDoc.data()?['IsDoctor'] ?? false;
      }
    }
    return false;
  }

  Future<QuerySnapshot> _getDoctorsList() async {
    final firestore = FirebaseFirestore.instance;
    final isDoctor = await _isCurrentUserDoctor();

    if (isDoctor) {
      return await firestore
          .collection('User')
          .where('IsDoctor', isEqualTo: false)
          .get();
    } else {
      return await firestore
          .collection('User')
          .where('IsDoctor', isEqualTo: true)
          .get();
    }
  }

  Future<String> _getCurrentUserName() async {
    final firestore = FirebaseFirestore.instance;
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      final userDoc =
          await firestore.collection('User').doc(currentUser.uid).get();
      if (userDoc.exists) {
        return userDoc.data()?['Name'] ?? 'Unknown User';
      }
    }
    return 'Unknown User';
  }

  Widget _buildUserListItem(BuildContext context, DocumentSnapshot doc) {
    var userData = doc.data() as Map<String, dynamic>;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          child: Text(
            userData['Name'][0].toUpperCase(),
            style: TextStyle(
              color: Colors.blue.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          userData['Name'],
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Chat(friendId: doc.id),
            ),
          );
        },
      ),
    );
  }

  Widget _buildExpandableTile(BuildContext context, String title,
      double fontSize, Future<QuerySnapshot> futureList) {
    final localizations = AppLocalizations.of(context)!;

    return Theme(
      data: ThemeData(
        dividerColor: Colors.transparent,
      ),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          child: const Icon(Icons.people_alt_outlined, color: Colors.black),
        ),
        title: Text(
          title,
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: fontSize,
              color: Colors.black),
        ),
        children: [
          FutureBuilder<QuerySnapshot>(
            future: futureList,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      const Icon(
                        Icons.person_off_outlined,
                        size: 48,
                        color: Colors.black,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        localizations.noUsersFound,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: snapshot.data!.docs
                    .map((doc) => _buildUserListItem(context, doc))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWebSocketTile(
      BuildContext context, String title, double fontSize) {
    final localizations = AppLocalizations.of(context)!;

    return Theme(
      data: ThemeData(
        dividerColor: Colors.transparent,
      ),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          child: const Icon(Icons.wifi, color: Colors.black),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: fontSize,
            color: Colors.black,
          ),
        ),
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            leading: const Icon(
              Icons.arrow_forward_ios,
              color: Colors.blue,
            ),
            title: Text(
              localizations.goToChatWithAI,
              style: const TextStyle(fontSize: 16),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const WebSocketScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      body: Row(
        children: [
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            child: Container(
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ListView(
                      children: [
                        _buildWebSocketTile(
                            context, localizations.chatWithAI, 20.0),
                        FutureBuilder<bool>(
                          future: _isCurrentUserDoctor(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(20.0),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                            final title = snapshot.data == true
                                ? localizations.chatWithPatients
                                : localizations.chatWithDoctors;
                            return _buildExpandableTile(
                              context,
                              title,
                              20.0,
                              _getDoctorsList(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin:
                        const EdgeInsets.only(right: 16, top: 16, bottom: 16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.blue.shade100,
                          child: const Icon(
                            Icons.person,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FutureBuilder<String>(
                            future: _getCurrentUserName(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const CircularProgressIndicator();
                              }
                              return Text(
                                snapshot.data ?? localizations.unknownUser,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            width: MediaQuery.of(context).size.width * 0.2,
            decoration: BoxDecoration(
              color: Colors.grey[200],
            ),
            child: Column(
              children: [
                const SizedBox(height: 40),
                IconButton(
                  icon: const Icon(
                    Icons.menu,
                    size: 24,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
