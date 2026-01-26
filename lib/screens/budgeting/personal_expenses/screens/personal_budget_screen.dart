import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PersonalBudgetScreen extends StatelessWidget {
  PersonalBudgetScreen({super.key});

  final TextEditingController budgetController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monthly Budget'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: budgetController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Monthly Budget (Coming Soon)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Get.snackbar(
                  'Not Available',
                  'Budget feature not implemented yet',
                );
              },
              child: const Text('Save Budget'),
            ),
          ],
        ),
      ),
    );
  }
}
