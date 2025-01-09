import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sick_sense_mobile/pages/chat.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:sick_sense_mobile/ask_disease/websocket_screen.dart';
import 'package:sick_sense_mobile/stripe_service.dart';
import 'package:sick_sense_mobile/doctor_list.dart';
import 'package:sick_sense_mobile/setting/base64_image.dart';

class LeftBar extends StatefulWidget {
  const LeftBar({super.key});

  @override
  State<LeftBar> createState() => _LeftBarState();
}

class _LeftBarState extends State<LeftBar> {
// Use StreamController to manage payment status updates
  final firestore = FirebaseFirestore.instance;
  final currentUser = FirebaseAuth.instance.currentUser;

  Future<bool> _isCurrentUserDoctor() async {
    if (currentUser != null) {
      final userDoc =
          await firestore.collection('User').doc(currentUser!.uid).get();
      return userDoc.data()?['IsDoctor'] ?? false;
    }
    return false;
  }

  Stream<QuerySnapshot> _getDoctorsList(bool isDoctor) {
    // Changed to Stream instead of Future for real-time updates
    return firestore
        .collection('User')
        .where('IsDoctor', isEqualTo: !isDoctor)
        .snapshots();
  }

  Stream<String> _getCurrentUserName() {
    // Changed to Stream for real-time updates
    if (currentUser?.uid != null) {
      // Safely access uid using ?. operator
      return firestore
          .collection('User')
          .doc(currentUser!.uid) // Can use ! here since we checked above
          .snapshots()
          .map((doc) => doc.data()?['Name'] ?? 'Unknown User');
    }
    return Stream.value('Unknown User');
  }

  Stream<bool> _getPaymentStatus() {
    // Changed to Stream for real-time updates
    if (currentUser != null) {
      return firestore
          .collection('User')
          .doc(currentUser!.uid)
          .snapshots()
          .map((doc) => doc.data()?['HasPaid'] ?? false);
    }
    return Stream.value(false);
  }

  Future<void> _handlePayment(BuildContext context) async {
    try {
      await StripeService.instance.makePayment();
      if (currentUser != null) {
        await firestore.collection('User').doc(currentUser!.uid).update({
          'HasPaid': true,
          'PaymentTimestamp': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment failed: ${e.toString()}')),
        );
      }
    }
  }

  Widget _buildUserList(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return const Center(child: Text("User not authenticated."));
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('Users').doc(userId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text("No data found."));
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>?;
        final textedUsers = (userData?['TextedUsers'] as List<dynamic>?)
                ?.map((entry) => entry['UserId'] as String)
                .toList() ??
            [];

        if (textedUsers.isEmpty) {
          return const Center(child: Text("You haven't texted anyone yet."));
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('Users').snapshots(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!userSnapshot.hasData) {
              return const Center(child: Text("No users found."));
            }

            final allUsers = userSnapshot.data!.docs;

            // Filter users based on the TextedUsers list
            final filteredUsers = allUsers.where((doc) {
              final userId = doc.id;
              return textedUsers.contains(userId);
            }).toList();

            if (filteredUsers.isEmpty) {
              return const Center(child: Text("No matching users found."));
            }

            return ListView.builder(
              itemCount: filteredUsers.length,
              itemBuilder: (context, index) {
                final userDoc = filteredUsers[index];
                return _buildUserListItem(context, userDoc);
              },
            );
          },
        );
      },
    );
  }

  Future<DocumentSnapshot> _fetchCurrentUser() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      return FirebaseFirestore.instance
          .collection('User') // Adjust the collection name if necessary
          .doc(currentUser.uid)
          .get();
    } else {
      throw Exception('User not logged in');
    }
  }

  Widget _buildUserListItem(BuildContext context, DocumentSnapshot doc) {
    // Extract user data from the document
    final userData = doc.data() as Map<String, dynamic>;
    final userName = userData['Name'] as String? ?? 'Unknown User';
    final avatarBase64 =
        userData['avatar'] as String?; // Extract avatar in Base64 format

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 30,
          backgroundColor: Colors.blue.shade100,
          backgroundImage: (avatarBase64 != null && avatarBase64.isNotEmpty)
              ? MemoryImage(
                  Base64ImageService().decodeBase64Image(avatarBase64))
              : null, // Load image if Base64 string is available
          child: (avatarBase64 == null || avatarBase64.isEmpty)
              ? Text(
                  userName.isNotEmpty
                      ? userName[0].toUpperCase()
                      : '?', // Fallback to initials
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        title: Text(
          userName,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Chat(friendId: doc.id),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentPrompt(
      BuildContext context, AppLocalizations localizations) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.payment_outlined,
            size: 64,
            color: Colors.orange,
          ),
          const SizedBox(height: 16),
          Text(
            localizations.paymentRequired,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => _handlePayment(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.credit_card, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  localizations.goToPayment,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyListMessage(AppLocalizations localizations) {
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

  Widget _buildExpandableTile(
      BuildContext context, String title, double fontSize, bool isDoctor) {
    final localizations = AppLocalizations.of(context)!;

    return Theme(
      data: ThemeData(dividerColor: Colors.transparent),
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
            color: Colors.black,
          ),
        ),
        children: [
          if (!isDoctor)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DoctorsListPage(),
                  ),
                ),
                icon: const Icon(Icons.search),
                label: Text(localizations.findDoctor),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ),
          StreamBuilder<bool>(
            stream: _getPaymentStatus(),
            builder: (context, paymentSnapshot) {
              if (paymentSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (paymentSnapshot.data == false && !isDoctor) {
                return _buildPaymentPrompt(context, localizations);
              }

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('User')
                    .doc(FirebaseAuth.instance.currentUser!.uid)
                    .get(),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                    return Center(
                      child: Text(localizations.noUsersFound),
                    );
                  }

                  final userData =
                      userSnapshot.data!.data() as Map<String, dynamic>?;
                  final isDoctor = userData?['IsDoctor'] ?? false;

                  final textedUsers =
                      (userData?[isDoctor ? 'TextedUsers' : 'TextedDoctors']
                                  as List<dynamic>?)
                              ?.map((entry) => entry['UserId'] as String)
                              .toList() ??
                          [];

                  if (textedUsers.isEmpty) {
                    return Center(
                      child: Text(isDoctor
                          ? localizations.noUsersFound
                          : localizations.noDoctorsFound),
                    );
                  }

                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('User')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      if (!snapshot.hasData) {
                        return Center(
                          child: Text(isDoctor
                              ? localizations.noUsersFound
                              : localizations.noDoctorsFound),
                        );
                      }

                      final allUsers = snapshot.data!.docs;

                      // Filter users based on TextedDoctors or TextedUsers
                      final filteredUsers = allUsers.where((doc) {
                        return textedUsers.contains(doc.id);
                      }).toList();

                      if (filteredUsers.isEmpty) {
                        return Center(
                          child: Text(isDoctor
                              ? localizations.noUsersFound
                              : localizations.noDoctorsFound),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredUsers.length,
                        itemBuilder: (context, index) {
                          final userDoc = filteredUsers[index];
                          return _buildUserListItem(context, userDoc);
                        },
                      );
                    },
                  );
                },
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
                MaterialPageRoute(builder: (context) => WebSocketScreen()),
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
                        // Conditionally show _buildWebSocketTile
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
                            final isDoctor = snapshot.data ?? false;
                            return isDoctor
                                ? const SizedBox.shrink()
                                : _buildWebSocketTile(
                                    context, localizations.chatWithAI, 20.0);
                          },
                        ),
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
                            final isDoctor = snapshot.data ?? false;
                            final title = isDoctor
                                ? localizations.chatWithPatients
                                : localizations.chatWithDoctors;
                            return _buildExpandableTile(
                              context,
                              title,
                              20.0,
                              isDoctor,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  // User info at bottom
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin:
                        const EdgeInsets.only(right: 16, top: 16, bottom: 16),
                    child: Row(
                      children: [
                        FutureBuilder<DocumentSnapshot>(
                          future: _fetchCurrentUser(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return CircleAvatar(
                                radius: 30,
                                backgroundColor: Colors.blue.shade100,
                                child: const CircularProgressIndicator(),
                              );
                            }

                            if (snapshot.hasError) {
                              return CircleAvatar(
                                radius: 30,
                                backgroundColor: Colors.red.shade100,
                                child:
                                    const Icon(Icons.error, color: Colors.red),
                              );
                            }

                            final userData =
                                snapshot.data?.data() as Map<String, dynamic>?;
                            final avatarBase64 = userData?['avatar'] as String?;
                            return CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.blue.shade100,
                              backgroundImage: (avatarBase64 != null &&
                                      avatarBase64.isNotEmpty)
                                  ? MemoryImage(Base64ImageService()
                                      .decodeBase64Image(avatarBase64))
                                  : null, // Display avatar if available
                              child: (avatarBase64 == null ||
                                      avatarBase64.isEmpty)
                                  ? const Icon(Icons.person, color: Colors.blue)
                                  : null, // Fallback to icon if no avatar
                            );
                          },
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: StreamBuilder<String>(
                            stream: _getCurrentUserName(),
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
