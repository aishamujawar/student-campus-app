import 'package:flutter/material.dart';

class AssignmentsPage extends StatelessWidget {
  const AssignmentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assignments'),
      ),
      body: const Center(
        child: Text(
          'This is the Assignments page',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}