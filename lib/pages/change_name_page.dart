import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChangeNamePage extends StatefulWidget {
  const ChangeNamePage({Key? key}) : super(key: key);

  @override
  State<ChangeNamePage> createState() => _ChangeNamePageState();
}

class _ChangeNamePageState extends State<ChangeNamePage> {
  final _nameController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  bool _isLoading = false;

  void _updateDisplayName() async {
    setState(() => _isLoading = true);
    try {
      await _auth.currentUser?.updateDisplayName(_nameController.text.trim());
      await _auth.currentUser?.reload();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name updated successfully')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update name: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentName = _auth.currentUser?.displayName ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Change Name'), backgroundColor: const Color(0xFF4CAF50)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameController..text = currentName,
              decoration: const InputDecoration(labelText: 'New Display Name'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _updateDisplayName,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
