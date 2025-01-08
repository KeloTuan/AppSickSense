import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:sick_sense_mobile/setting/base64_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';

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
    //'IsDoctor': false,
  };

  final Map<String, TextEditingController> controllers = {
    'Name': TextEditingController(),
    'Phone': TextEditingController(),
    'Email': TextEditingController(),
    'Gender': TextEditingController(),
    'Height': TextEditingController(),
    'Weight': TextEditingController(),
    'DateOfBirth': TextEditingController(),
    //'IsDoctor': TextEditingController(),
  };

  bool _isLoading = true;
  File? _selectedImage;

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

  Future<void> _pickImageFromGallery() async {
    try {
      final pickedImage =
          await ImagePicker().pickImage(source: ImageSource.gallery);

      if (pickedImage != null) {
        // Read the image file as bytes
        Uint8List imageBytes = await pickedImage.readAsBytes();

        // Convert the bytes to Base64 and save it
        await _uploadImage(imageBytes);
      }
    } catch (e) {
      print("Error picking image: $e");
    }
  }

  Future<void> _uploadImage(Uint8List imageBytes) async {
    final Base64ImageService imageService = Base64ImageService();
    try {
      // Convert image to Base64
      String base64Image = imageService.encodeImageToBase64(imageBytes);

      // Save Base64 string to Firestore
      await _saveAvatarToFirestore(base64Image);

      // Optionally, upload the image to Firebase Storage and get the download URL
      String fileName = "${FirebaseAuth.instance.currentUser?.uid}_avatar.jpg";
      String downloadUrl = await imageService.uploadImage(imageBytes, fileName);

      print("Image uploaded successfully. Download URL: $downloadUrl");
    } catch (e) {
      print("Error uploading image: $e");
    }
  }

  Future<void> _saveAvatarToFirestore(String base64Image) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('No user logged in');
      }

      await FirebaseFirestore.instance
          .collection('User')
          .doc(currentUser.uid)
          .update({
        'avatar': base64Image,
        'avatarUpdatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error saving avatar: $e');
      rethrow; // Allow caller to handle error
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
              color: Colors.blue.withOpacity(0.1),
              border: Border.all(
                color: Colors.blue,
                width: 2,
              ),
            ),
            child: userData['avatar'] != null && userData['avatar'].isNotEmpty
                ? ClipOval(
                    child: Image.memory(
                      base64Decode(userData['avatar']),
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  )
                : const Icon(
                    Icons.person_outline,
                    size: 50,
                    color: Colors.blue,
                  ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _pickImageFromGallery,
            child: const Text("Thay đổi Avatar"),
          ),
          Text(
            userData['Name']?.toString() ??
                AppLocalizations.of(context)!.no_data,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableField(String key, IconData icon) {
    final localizations = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.black54, // Màu của viền
          width: 1.0, // Độ dày của viền
        ),
      ),
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
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 20, color: Colors.blue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: isEditing[key]!
                      ? TextField(
                          controller: controllers[key],
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.blue.withOpacity(0.3),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.blue.withOpacity(0.3),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Colors.blue,
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.all(16),
                          ),
                        )
                      : Text(
                          userData[key]?.toString() ?? localizations.no_data,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                          ),
                        ),
                ),
                const SizedBox(width: 8),
                if (!isEditing[key]!)
                  IconButton(
                    icon: const Icon(
                      Icons.edit_outlined,
                      size: 20,
                      color: Colors.black,
                    ),
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
                    color: Colors.red,
                  ),
                  IconButton(
                    onPressed: () => _saveFieldToFirebase(key),
                    icon: const Icon(Icons.check, size: 18),
                    color: Colors.green,
                  ),
                ]
              ],
            ),
          ],
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
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
              const SizedBox(height: 16),
              Text(
                'Loading profile...',
                style: TextStyle(
                  color: Colors.blue.shade800,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          localizations.user_info,
          style: const TextStyle(color: Colors.black),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
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
