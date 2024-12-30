import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AccountSettingPage extends StatefulWidget {
  const AccountSettingPage({super.key});

  @override
  _AccountSettingPageState createState() => _AccountSettingPageState();
}

class _AccountSettingPageState extends State<AccountSettingPage> {
  Map<String, dynamic> userData = {};
  Map<String, bool> isEditing = {
    'Name': false,
    'Phone': false,
    'Email': false,
    'Gender': false,
    'Height': false,
    'Weight': false,
    'DateOfBirth': false,
    'IsDoctor': false,
  };

  final Map<String, TextEditingController> controllers = {
    'Name': TextEditingController(),
    'Phone': TextEditingController(),
    'Email': TextEditingController(),
    'Gender': TextEditingController(),
    'Height': TextEditingController(),
    'Weight': TextEditingController(),
    'DateOfBirth': TextEditingController(),
    'IsDoctor': TextEditingController(),
  };

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final ref = FirebaseFirestore.instance.collection('User').doc(user.uid);
        final docSnapshot = await ref.get();

        if (docSnapshot.exists) {
          final userDataFromFirestore =
              docSnapshot.data() as Map<String, dynamic>;

          setState(() {
            userData = userDataFromFirestore;
            _isLoading = false;

            controllers.forEach((key, controller) {
              controller.text = userDataFromFirestore[key]?.toString() ?? '';
            });
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User data not found')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
    }
  }

  Widget _buildEditableField(String label, String key) {
    final localizations = AppLocalizations.of(context)!;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: isEditing[key]!
              ? TextField(
                  controller: controllers[key],
                  decoration: InputDecoration(labelText: label),
                )
              : Text(
                  '$label: ${userData[key] ?? localizations.no_data}',
                  style: const TextStyle(fontSize: 18),
                ),
        ),
        IconButton(
          icon: Icon(isEditing[key]! ? Icons.save : Icons.edit),
          onPressed: () {
            if (isEditing[key]!) {
              _saveFieldToFirebase(key);
            } else {
              setState(() {
                isEditing[key] = true;
              });
            }
          },
        ),
      ],
    );
  }

  Future<void> _saveFieldToFirebase(String key) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final ref = FirebaseFirestore.instance.collection('User').doc(user.uid);

        await ref.update({
          key: controllers[key]!.text,
        });

        setState(() {
          userData[key] = controllers[key]!.text;
          isEditing[key] = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.update_success)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating $key: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.user_info),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildEditableField(localizations.name, 'Name'),
            const Divider(),
            _buildEditableField(localizations.phone, 'Phone'),
            const Divider(),
            _buildEditableField(localizations.email, 'Email'),
            const Divider(),
            _buildEditableField(localizations.gender, 'Gender'),
            const Divider(),
            _buildEditableField(localizations.height, 'Height'),
            const Divider(),
            _buildEditableField(localizations.weight, 'Weight'),
            const Divider(),
            _buildEditableField(localizations.dob, 'DateOfBirth'),
            const Divider(),
            _buildEditableField(localizations.is_doctor, 'IsDoctor'),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    controllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }
}
