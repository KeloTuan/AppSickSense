import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  _ChangePasswordPageState createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;

  Future<void> _changePassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final user = FirebaseAuth.instance.currentUser;
        final currentPassword = _currentPasswordController.text;
        final newPassword = _newPasswordController.text;

        // Reauthenticate user
        final cred = EmailAuthProvider.credential(
          email: user!.email!,
          password: currentPassword,
        );

        await user.reauthenticateWithCredential(cred);
        await user.updatePassword(newPassword);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(AppLocalizations.of(context)!.passwordChangeSuccess)),
        );

        Navigator.pop(context); // Quay lại trang trước
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.error}: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Lấy đối tượng AppLocalizations để sử dụng chuỗi ngôn ngữ
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.changePassword), // Dùng chuỗi ngôn ngữ
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Mật khẩu hiện tại
              TextFormField(
                controller: _currentPasswordController,
                decoration: InputDecoration(
                  labelText:
                      localizations.currentPassword, // Dùng chuỗi ngôn ngữ
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return localizations
                        .enterCurrentPassword; // Dùng chuỗi ngôn ngữ
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Mật khẩu mới
              TextFormField(
                controller: _newPasswordController,
                decoration: InputDecoration(
                  labelText: localizations.newPassword, // Dùng chuỗi ngôn ngữ
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return localizations
                        .enterNewPassword; // Dùng chuỗi ngôn ngữ
                  }
                  if (value.length < 6) {
                    return localizations
                        .passwordMinLengthError; // Dùng chuỗi ngôn ngữ
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Xác nhận mật khẩu
              TextFormField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(
                  labelText:
                      localizations.confirmNewPassword, // Dùng chuỗi ngôn ngữ
                ),
                obscureText: true,
                validator: (value) {
                  if (value != _newPasswordController.text) {
                    return localizations
                        .passwordMismatchError; // Dùng chuỗi ngôn ngữ
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Nút lưu
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _changePassword,
                      child: Text(
                          localizations.savePassword), // Dùng chuỗi ngôn ngữ
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
