import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sick_sense_mobile/auth/login/login_screen.dart';
import 'package:sick_sense_mobile/pages/chat.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:sick_sense_mobile/ask_disease/websocket_screen.dart';
import 'package:sick_sense_mobile/stripe_service.dart';

class LeftBar extends StatefulWidget {
  const LeftBar({super.key});

  @override
  State<LeftBar> createState() => _LeftBarState();
}

class _LeftBarState extends State<LeftBar> {
  bool? _cachedPaymentStatus;
  StreamSubscription<DocumentSnapshot>? _paymentStatusSubscription;

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

  Future<bool> _checkPaymentStatus() async {
    final firestore = FirebaseFirestore.instance;
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      final userDoc =
          await firestore.collection('User').doc(currentUser.uid).get();

      if (userDoc.exists) {
        return userDoc.data()?['HasPaid'] ?? false;
      }
    }
    return false;
  }

  Future<void> _savePaymentStatus() async {
    final firestore = FirebaseFirestore.instance;
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      await firestore.collection('User').doc(currentUser.uid).update({
        'HasPaid': true,
        'PaymentTimestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> _handlePayment(BuildContext context) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      );

      // Get current user
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      // Attempt payment
      await StripeService.instance.makePayment();

      // If payment is successful, update Firestore
      await FirebaseFirestore.instance
          .collection('User')
          .doc(currentUser.uid)
          .update({
        'HasPaid': true,
        'PaymentTimestamp': FieldValue.serverTimestamp(),
        'PaymentAmount': 100, // Store the amount paid
        'PaymentCurrency': 'usd'
      });

      // Close loading indicator
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment successful!'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Refresh the UI
      if (context.mounted) {
        setState(() {});
      }
    } catch (e) {
      // Close loading indicator if showing
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();

      if (context.mounted) {
        // Navigate to login screen and remove all previous routes
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => LoginScreen()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _setupPaymentStatusListener();
  }

  void _setupPaymentStatusListener() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _paymentStatusSubscription = FirebaseFirestore.instance
          .collection('User')
          .doc(currentUser.uid)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.exists) {
          final newPaymentStatus = snapshot.data()?['HasPaid'] ?? false;
          if (_cachedPaymentStatus != newPaymentStatus) {
            setState(() {
              _cachedPaymentStatus = newPaymentStatus;
            });
          }
        }
      });
    }
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
            color: Colors.black,
          ),
        ),
        children: [
          FutureBuilder<bool>(
            future: _checkPaymentStatus(),
            builder: (context, paymentSnapshot) {
              if (paymentSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (paymentSnapshot.data == false) {
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
                        onPressed: () async {
                          try {
                            // Hiển thị loading indicator trong BuildContext hiện tại
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (BuildContext context) {
                                return WillPopScope(
                                  onWillPop: () async => false,
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              },
                            );

                            // Thực hiện thanh toán
                            await StripeService.instance.makePayment();

                            // Cập nhật trạng thái thanh toán
                            await _savePaymentStatus();

                            // Đóng loading indicator
                            if (context.mounted) {
                              Navigator.pop(context); // Đóng loading indicator

                              // Hiển thị dialog thành công
                              await showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (BuildContext context) {
                                  return WillPopScope(
                                    onWillPop: () async => false,
                                    child: AlertDialog(
                                      title: const Text('Payment Successful'),
                                      content: const Text(
                                          'Payment completed successfully. Please log in again to continue.'),
                                      actions: [
                                        TextButton(
                                          onPressed: () async {
                                            Navigator.pop(
                                                context); // Đóng dialog thành công
                                            await _handleLogout(
                                                context); // Xử lý đăng xuất
                                          },
                                          child: const Text('OK'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            }
                          } catch (e) {
                            // Đóng loading indicator nếu có lỗi
                            if (context.mounted) {
                              Navigator.pop(context);

                              // Hiển thị thông báo lỗi
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content:
                                      Text('Payment failed: ${e.toString()}'),
                                  backgroundColor: Colors.red,
                                  duration: const Duration(seconds: 4),
                                ),
                              );
                            }
                          }
                        },
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
                            const Icon(
                              Icons.credit_card,
                              color: Colors.white,
                            ),
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

              // Nếu đã thanh toán, hiển thị danh sách
              return FutureBuilder<QuerySnapshot>(
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

  @override
  void dispose() {
    _paymentStatusSubscription?.cancel();
    super.dispose();
  }
}
