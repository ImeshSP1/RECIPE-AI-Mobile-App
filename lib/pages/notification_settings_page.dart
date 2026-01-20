import 'package:flutter/material.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({Key? key}) : super(key: key);

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  bool _newRecipe = true;
  bool _tipsAndTricks = false;
  bool _reminders = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
        backgroundColor: const Color(0xFF4CAF50),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('New Recipes'),
            value: _newRecipe,
            onChanged: (val) {
              setState(() => _newRecipe = val);
              // TODO: Save preference
            },
          ),
          SwitchListTile(
            title: const Text('Cooking Tips & Tricks'),
            value: _tipsAndTricks,
            onChanged: (val) {
              setState(() => _tipsAndTricks = val);
              // TODO: Save preference
            },
          ),
          SwitchListTile(
            title: const Text('Daily Meal Reminders'),
            value: _reminders,
            onChanged: (val) {
              setState(() => _reminders = val);
              // TODO: Save preference
            },
          ),
        ],
      ),
    );
  }
}
