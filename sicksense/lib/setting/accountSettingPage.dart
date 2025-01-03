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
          _showSnackBar('User data not found');
        }
      }
    } catch (e) {
      _showSnackBar('Error loading data: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
            ),
            child: Icon(
              Icons.person_outline,
              size: 50,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            userData['Name']?.toString() ??
                AppLocalizations.of(context)!.no_data,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          // const SizedBox(height: 8),
          // Text(
          //   userData['Email']?.toString() ??
          //       AppLocalizations.of(context)!.no_data,
          //   style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          //         color:
          //             Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          //       ),
          // ),
        ],
      ),
    );
  }

  Widget _buildEditableField(String key, IconData icon) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child:
                        Icon(icon, size: 20, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(width: 12),
                  // Horizontal alignment for data
                  Expanded(
                    child: isEditing[key]!
                        ? TextField(
                            controller: controllers[key],
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: theme.colorScheme.surface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: theme.colorScheme.outline
                                      .withOpacity(0.3),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: theme.colorScheme.outline
                                      .withOpacity(0.3),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: theme.colorScheme.primary,
                                  width: 2,
                                ),
                              ),
                              contentPadding: const EdgeInsets.all(16),
                            ),
                          )
                        : Text(
                            userData[key]?.toString() ?? localizations.no_data,
                            style: theme.textTheme.bodyLarge,
                          ),
                  ),
                  const SizedBox(width: 8),
                  if (!isEditing[key]!)
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      onPressed: () => setState(() => isEditing[key] = true),
                    ),

                  if (isEditing[key]!) ...[
                    IconButton(
                      onPressed: () {
                        setState(() {
                          isEditing[key] = false;
                          controllers[key]!.text =
                              userData[key]?.toString() ?? '';
                        });
                      },
                      icon: const Icon(Icons.close, size: 18),
                      color: Theme.of(context)
                          .colorScheme
                          .error, // Set color to red for 'close' icon
                    ),
                    IconButton(
                      onPressed: () => _saveFieldToFirebase(key),
                      icon: const Icon(Icons.check, size: 18),
                      color: Colors.green, // Green color for check icon
                    ),
                  ]
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveFieldToFirebase(String key) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final ref = FirebaseFirestore.instance.collection('User').doc(user.uid);
        await ref.update({key: controllers[key]!.text});

        setState(() {
          userData[key] = controllers[key]!.text;
          isEditing[key] = false;
        });

        _showSnackBar(AppLocalizations.of(context)!.update_success);
      }
    } catch (e) {
      _showSnackBar('Error updating $key: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Loading profile...',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      );
    }

    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: Text(localizations.user_info),
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildProfileHeader(),
          const SizedBox(height: 16),
          _buildEditableField('Name', Icons.person_outline),
          _buildEditableField('Phone', Icons.phone_outlined),
          _buildEditableField('Email', Icons.email_outlined),
          _buildEditableField('Gender', Icons.people_outline),
          _buildEditableField('Height', Icons.height_outlined),
          _buildEditableField('Weight', Icons.monitor_weight_outlined),
          _buildEditableField('DateOfBirth', Icons.calendar_today_outlined),
          _buildEditableField('IsDoctor', Icons.medical_services_outlined),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  @override
  void dispose() {
    controllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }
}
