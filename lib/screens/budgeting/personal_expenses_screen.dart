import 'package:flutter/material.dart';

class PersonalExpensesScreen extends StatelessWidget {
  const PersonalExpensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Personal Expenses')),
      body: const Center(
        child: Text(
          'Personal expense tracking coming soon',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
