import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:sick_sense_mobile/pages/chat.dart';
import 'package:sick_sense_mobile/setting/accountSettingPage.dart';

class LeftBar extends StatelessWidget {
  final Function(String) onDoctorSelected;

  const LeftBar({super.key, required this.onDoctorSelected});

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            // Left Section (Main Content)
            Expanded(
              flex: 4,
              child: Container(
                color: Colors.grey[200],
                child: Column(
                  children: [
                    // Header with profile info
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: FutureBuilder<DocumentSnapshot>(
                        future: _getUserData(currentUser),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const CircularProgressIndicator();
                          }

                          if (!snapshot.hasData ||
                              snapshot.data!.data() == null) {
                            return Text(localizations.userInfoNotAvailable);
                          }

                          final userData =
                          snapshot.data!.data() as Map<String, dynamic>;
                          final String userName =
                              userData['Name'] ?? 'Anonymous';

                          return Row(
                            children: [
                              const CircleAvatar(
                                radius: 30,
                                backgroundImage:
                                AssetImage('assets/profile.jpg'),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      userName,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),

                    // Divider
                    const Divider(thickness: 1),

                    // Expandable Menu
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _buildExpandableTile(
                            localizations.chatWithAI,
                            context,
                            onTap: () {
                              onDoctorSelected('AI');
                              Navigator.pop(context);
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildExpandableTile(
                            localizations.chatWithDoctor,
                            context,
                            showDoctors: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Right Section (Menu Button)
            Expanded(
              flex: 1,
              child: Container(
                color: Colors.white,
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    IconButton(
                      icon: const Icon(Icons.menu),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<DocumentSnapshot> _getUserData(User? currentUser) async {
    final firestore = FirebaseFirestore.instance;
    return await firestore.collection('User').doc(currentUser?.uid).get();
  }

  Widget _buildExpandableTile(String title, BuildContext context,
      {bool showDoctors = false, VoidCallback? onTap}) {
    return ExpansionTile(
      leading: const Icon(Icons.add, color: Colors.black),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      children: showDoctors
          ? [
        FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance
              .collection('User')
              .where('IsDoctor', isEqualTo: true)
              .get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text('No doctors available.'),
              );
            }

            final doctors = snapshot.data!.docs;

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: doctors.length,
              itemBuilder: (context, index) {
                final doctor =
                doctors[index].data() as Map<String, dynamic>;
                final String doctorName = doctor['Name'] ?? 'Unknown';

                return ListTile(
                  leading: const CircleAvatar(
                    backgroundImage: AssetImage('assets/doctor_icon.png'),
                  ),
                  title: Text(doctorName),
                  onTap: () {
                    onDoctorSelected(doctorName);
                    Navigator.pop(context);
                  },
                );
              },
            );
          },
        ),
      ]
          : [
        ListTile(
          title: Text(title),
          onTap: onTap,
        ),
      ],
    );
  }
}
