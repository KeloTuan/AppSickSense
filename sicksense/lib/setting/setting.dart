import 'package:flutter/material.dart';
import 'package:sick_sense_mobile/main.dart';
import 'package:sick_sense_mobile/pages/change_password.dart';
import 'package:sick_sense_mobile/pages/chat.dart';
import 'package:sick_sense_mobile/setting/accountSettingPage.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sick_sense_mobile/pages/change_password.dart';
import 'package:sick_sense_mobile/setting/accountSettingPage.dart';

class SettingPage extends StatelessWidget {
  const SettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60.0),
        child: AppBar(
          automaticallyImplyLeading: false,
          flexibleSpace: Padding(
            padding: const EdgeInsets.only(top: 30.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const Chat(
                                friendId: '',
                              )),
                    );
                  },
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      localizations.settings,
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(0.0),
        children: [
          // Tài khoản
          ListTile(
            leading: const Icon(Icons.account_circle, color: Colors.black),
            title: Text(
              localizations.account,
              style: const TextStyle(fontSize: 20),
            ),
            subtitle: Text(
              localizations.accountDescription,
              style: const TextStyle(fontSize: 16),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const AccountSettingPage()),
              );
            },
          ),
          const Divider(),

          // Mật khẩu
          ListTile(
            leading: const Icon(Icons.password, color: Colors.black),
            title: Text(
              localizations.password,
              style: const TextStyle(fontSize: 20),
            ),
            subtitle: Text(
              localizations.changePassword,
              style: const TextStyle(fontSize: 16),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ChangePassword()),
              );
            },
          ),
          const Divider(),

          // Ngôn ngữ
          ListTile(
            leading: const Icon(Icons.language, color: Colors.black),
            title: Text(
              localizations.language,
              style: const TextStyle(fontSize: 20),
            ),
            subtitle: Text(
              localizations.changeLanguage,
              style: const TextStyle(fontSize: 16),
            ),
            onTap: () {
              // Hiển thị Dialog chọn ngôn ngữ
              _showLanguageDialog(context);
            },
          ),
          const Divider(),
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.changeLanguage),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('Tiếng Việt'),
                onTap: () {
                  _changeLanguage(context, Locale('vi'));
                },
              ),
              ListTile(
                title: Text('English'),
                onTap: () {
                  _changeLanguage(context, Locale('en'));
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _changeLanguage(BuildContext context, Locale locale) {
    Navigator.of(context).pop(); // Đóng dialog
    MyApp.of(context).setLocale(locale); // Thay đổi ngôn ngữ
  }
}
