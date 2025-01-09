import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class DoctorsListPage extends StatelessWidget {
  const DoctorsListPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final firestore = FirebaseFirestore.instance;
    final currentUser = FirebaseAuth.instance.currentUser;
    final localizations = AppLocalizations.of(context)!;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please login to access doctors list'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.availableDoctor),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: firestore.collection('User').doc(currentUser.uid).snapshots(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
            return Center(child: Text(localizations.noAvailableDoctor));
          }

          final userData = userSnapshot.data!.data() as Map<String, dynamic>;
          final hasPaid = userData['HasPaid'] ?? false;

          if (!hasPaid) {
            return const Center(
              child: Text(
                'Please subscribe to access our doctors list',
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          return StreamBuilder<QuerySnapshot>(
            stream: firestore
                .collection('User')
                .where('IsDoctor', isEqualTo: true)
                .snapshots(),
            builder: (context, doctorsSnapshot) {
              if (doctorsSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!doctorsSnapshot.hasData ||
                  doctorsSnapshot.data!.docs.isEmpty) {
                return Center(child: Text(localizations.noAvailableDoctor));
              }

              final doctors = doctorsSnapshot.data!.docs;

              return ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: doctors.length,
                itemBuilder: (context, index) {
                  final doctorData =
                      doctors[index].data() as Map<String, dynamic>;

                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: InkWell(
                      onTap: () => _handleDoctorSelection(
                        context,
                        doctors[index].id,
                        doctorData,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              doctorData['Name'] ?? 'No Name',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text('Gender: ${doctorData['Gender'] ?? 'N/A'}'),
                            const SizedBox(height: 4),
                            Text('Phone: ${doctorData['Phone'] ?? 'N/A'}'),
                            const SizedBox(height: 4),
                            Text('Email: ${doctorData['Email'] ?? 'N/A'}'),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  void _handleDoctorSelection(
    BuildContext context,
    String doctorId,
    Map<String, dynamic> doctorData,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text('Select ${doctorData['Name']}'),
        content: const Text('Would you like to select this doctor?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(); // Close the dialog
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final currentUser = FirebaseAuth.instance.currentUser;
              if (currentUser != null) {
                try {
                  // Generate the timestamp
                  final timestamp = Timestamp.now();

                  final doctorDataToUpdate = {
                    'UserId': doctorId,
                    'LastMessage': '',
                    'Timestamp': timestamp,
                  };

                  final userDataToUpdate = {
                    'UserId': currentUser.uid,
                    'LastMessage': '',
                    'Timestamp': timestamp,
                  };

                  // Get a reference to Firestore
                  final firestore = FirebaseFirestore.instance;

                  // Perform both updates in a batch for atomicity
                  final batch = firestore.batch();

                  // Update the user's TextedDoctors list
                  final currentUserDocRef =
                      firestore.collection('User').doc(currentUser.uid);
                  batch.update(currentUserDocRef, {
                    'TextedDoctors':
                        FieldValue.arrayUnion([doctorDataToUpdate]),
                  });

                  // Update the doctor's TextedUsers list
                  final doctorDocRef =
                      firestore.collection('User').doc(doctorId);
                  batch.update(doctorDocRef, {
                    'TextedUsers': FieldValue.arrayUnion([userDataToUpdate]),
                  });

                  // Commit the batch
                  await batch.commit();

                  // Close the dialog first
                  Navigator.of(dialogContext).pop();

                  // Safely navigate back to the previous page
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                } catch (e) {
                  Navigator.of(dialogContext).pop(); // Close the dialog
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to add doctor: $e')),
                    );
                  }
                }
              } else {
                Navigator.of(dialogContext).pop(); // Close the dialog
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('User not logged in')),
                  );
                }
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}
