import 'package:flutter/material.dart';
import 'change_name_page.dart';
import 'update_email_page.dart';
import 'change_password_page.dart';
import 'language_page.dart';
import 'notification_settings_page.dart';
//import 'theme_toggle_provider.dart'; // Optional: If you're using Provider for dark mode

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8E9),
      appBar: AppBar(
        title: const Text('Account Settings'),
        backgroundColor: const Color(0xFF4CAF50),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionTitle('Personal Info'),
          _buildSettingTile(
            icon: Icons.person,
            title: 'Change Name',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangeNamePage()));
            },
          ),
          _buildSettingTile(
            icon: Icons.email,
            title: 'Update Email',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const UpdateEmailPage()));
            },
          ),
          _buildSettingTile(
            icon: Icons.lock,
            title: 'Change Password',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangePasswordPage()));
            },
          ),
          const SizedBox(height: 20),

          _buildSectionTitle('Preferences'),
          _buildSettingTile(
            icon: Icons.dark_mode,
            title: 'Dark Mode',
            onTap: () {
              // Toggle theme using your provider or state management
             // ThemeToggleProvider.of(context).toggleTheme();
            },
          ),
          _buildSettingTile(
            icon: Icons.language,
            title: 'Change Language',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const LanguagePage()));
            },
          ),
          _buildSettingTile(
            icon: Icons.notifications,
            title: 'Notification Settings',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationSettingsPage()));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF4CAF50)),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }
}
