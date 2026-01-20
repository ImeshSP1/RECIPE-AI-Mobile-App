import 'package:flutter/material.dart';

class LanguagePage extends StatelessWidget {
  const LanguagePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Change Language'), backgroundColor: const Color(0xFF4CAF50)),
      body: const Center(child: Text('Language Settings Page')),
    );
  }
}
