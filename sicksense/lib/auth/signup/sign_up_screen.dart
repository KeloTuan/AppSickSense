import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sick_sense_mobile/auth/login/login_screen.dart';
import 'package:sick_sense_mobile/auth/login/wrapper.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();

  String _selectedGender = 'Nam'; // Default gender
  bool _isDoctor = false; // Doctor switch
  DateTime? _selectedDate; // Birthdate

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _signUp() async {
    try {
      // Create user account
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      // Get user UID
      String uid = userCredential.user!.uid;

      // Save user data to Firestore
      await _firestore.collection('User').doc(uid).set({
        'Name': _nameController.text,
        'Email': _emailController.text,
        'Phone': _phoneController.text,
        'Gender': _selectedGender,
        'Height': double.tryParse(_heightController.text) ?? 0.0,
        'Weight': double.tryParse(_weightController.text) ?? 0.0,
        'IsDoctor': _isDoctor,
        'DateOfBirth': _selectedDate == null
            ? null
            : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Đăng kí thành công. Bạn cần xác nhận Email để hoàn tất đăng kí'),
          duration: Duration(seconds: 8),
        ),
      );

      // Navigate to the next screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Wrapper()),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.message}')),
      );
    }
  }

  void _selectDate(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final InputDecoration inputDecoration = InputDecoration(
      labelStyle: const TextStyle(color: Colors.purple),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.purple),
      ),
    );

    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.signUp),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Full name field
            TextField(
              controller: _nameController,
              decoration:
                  inputDecoration.copyWith(labelText: localizations.fullName),
            ),
            const SizedBox(height: 20),
            // Email field
            TextField(
              controller: _emailController,
              decoration:
                  inputDecoration.copyWith(labelText: localizations.email),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            // Password field
            TextField(
              controller: _passwordController,
              decoration:
                  inputDecoration.copyWith(labelText: localizations.password),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            // Phone number field
            TextField(
              controller: _phoneController,
              decoration:
                  inputDecoration.copyWith(labelText: localizations.phone),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            // Gender selection (Radio buttons)
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  localizations.gender,
                  style: const TextStyle(fontSize: 16, color: Colors.purple),
                ),
                const SizedBox(width: 20),
                Row(
                  children: [
                    Radio<String>(
                      value: 'Nam',
                      groupValue: _selectedGender,
                      onChanged: (value) {
                        setState(() {
                          _selectedGender = value!;
                        });
                      },
                    ),
                    Text(localizations.male),
                  ],
                ),
                const SizedBox(width: 20),
                Row(
                  children: [
                    Radio<String>(
                      value: 'Nữ',
                      groupValue: _selectedGender,
                      onChanged: (value) {
                        setState(() {
                          _selectedGender = value!;
                        });
                      },
                    ),
                    Text(localizations.female),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Date of birth selection
            Row(
              children: [
                Text(
                  localizations.birthDate,
                  style: const TextStyle(fontSize: 16, color: Colors.purple),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _selectDate(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _selectedDate == null
                            ? localizations.selectDate
                            : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Height field
            TextField(
              controller: _heightController,
              decoration:
                  inputDecoration.copyWith(labelText: localizations.height),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            // Weight field
            TextField(
              controller: _weightController,
              decoration:
                  inputDecoration.copyWith(labelText: localizations.weight),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            // Doctor switch
            Row(
              children: [
                Text(
                  localizations.isDoctor,
                  style: const TextStyle(fontSize: 16, color: Colors.purple),
                ),
                Switch(
                  value: _isDoctor,
                  onChanged: (value) {
                    setState(() {
                      _isDoctor = value;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Sign Up button
            ElevatedButton(
              onPressed: _signUp,
              child: Text(localizations.signUp),
            ),
          ],
        ),
      ),
    );
  }
}
