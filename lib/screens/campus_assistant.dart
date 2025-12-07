import 'package:flutter/material.dart';

class CampusAssistantScreen extends StatelessWidget {
  const CampusAssistantScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: Center(
        child: Text(
          'Campus Assistant / Chatbot (Placeholder)',
          style: TextStyle(fontSize: 16),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}