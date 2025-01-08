import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sick_sense_mobile/setting/setting.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ChangePassword extends StatefulWidget {
  const ChangePassword({super.key});

  @override
  _ChangePasswordPageState createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePassword> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _showOldPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: AppLocalizations.of(context)!.pleaseReloginMessage,
        );
      }

      await user.reauthenticateWithCredential(
        EmailAuthProvider.credential(
          email: user.email!,
          password: _oldPasswordController.text.trim(),
        ),
      );

      await user.updatePassword(_newPasswordController.text.trim());

      if (!mounted) return;

      Get.snackbar(
        AppLocalizations.of(context)!.success,
        AppLocalizations.of(context)!.passwordChangeSuccess,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green[100],
        colorText: Colors.green[900],
        duration: const Duration(seconds: 2),
        borderRadius: 10,
        margin: const EdgeInsets.all(10),
      );

      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;
      Get.back();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String errorMessage = switch (e.code) {
        'invalid-credential' =>
          AppLocalizations.of(context)!.incorrectCurrentPassword,
        'weak-password' => AppLocalizations.of(context)!.weakPassword,
        'requires-recent-login' =>
          AppLocalizations.of(context)!.pleaseReloginMessage,
        _ => e.message ?? AppLocalizations.of(context)!.unknownError
      };

      Get.snackbar(
        AppLocalizations.of(context)!.error,
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
        duration: const Duration(seconds: 2),
        borderRadius: 10,
        margin: const EdgeInsets.all(10),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  InputDecoration _getInputDecoration({
    required String label,
    required bool showPassword,
    required VoidCallback onToggleVisibility,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        color: Colors.grey,
        fontSize: 16,
      ),
      filled: true,
      fillColor: Colors.grey[50],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.grey, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.blue[300]!, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red[300]!, width: 1),
      ),
      suffixIcon: IconButton(
        icon: Icon(
          showPassword ? Icons.visibility_off : Icons.visibility,
          color: Colors.grey[600],
        ),
        onPressed: onToggleVisibility,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          localizations.changePassword,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SettingPage()),
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                const Icon(
                  Icons.lock_outline,
                  size: 64,
                  color: Colors.blue,
                ),
                const SizedBox(height: 16),
                Text(
                  localizations.createNewSecurePassword,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  localizations.passwordRequirements,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _oldPasswordController,
                  obscureText: !_showOldPassword,
                  decoration: _getInputDecoration(
                    label: localizations.currentPassword,
                    showPassword: _showOldPassword,
                    onToggleVisibility: () =>
                        setState(() => _showOldPassword = !_showOldPassword),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return localizations.pleaseEnterCurrentPassword;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _newPasswordController,
                  obscureText: !_showNewPassword,
                  decoration: _getInputDecoration(
                    label: localizations.newPassword,
                    showPassword: _showNewPassword,
                    onToggleVisibility: () =>
                        setState(() => _showNewPassword = !_showNewPassword),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return localizations.pleaseEnterNewPassword;
                    }
                    if (value!.length < 6) {
                      return localizations.passwordMinLength;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: !_showConfirmPassword,
                  decoration: _getInputDecoration(
                    label: localizations.confirmNewPassword,
                    showPassword: _showConfirmPassword,
                    onToggleVisibility: () => setState(
                        () => _showConfirmPassword = !_showConfirmPassword),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return localizations.pleaseConfirmNewPassword;
                    }
                    if (value != _newPasswordController.text) {
                      return localizations.passwordsDoNotMatch;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isLoading ? null : _changePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[300],
                    foregroundColor: Colors.grey[900],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          localizations.changePassword,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
