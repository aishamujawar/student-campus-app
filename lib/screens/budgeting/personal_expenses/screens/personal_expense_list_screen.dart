import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../controllers/personal_expense_controller.dart';
import '../models/personal_expense_model.dart';

class PersonalExpenseListScreen extends StatelessWidget {
  PersonalExpenseListScreen({super.key});

  final PersonalExpenseController controller =
      Get.find<PersonalExpenseController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('All Expenses')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.toNamed('/add-personal-expense'),
        child: const Icon(Icons.add),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.expenses.isEmpty) {
          return const Center(
            child: Text(
              'No expenses yet.\nTap + to add one.',
              textAlign: TextAlign.center,
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: controller.expenses.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (_, index) {
            final PersonalExpense e = controller.expenses[index];

            return ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue.shade100,
                child: Text(e.category[0].toUpperCase()),
              ),
              title: Text(e.title),
              subtitle: Text(
                DateFormat('dd MMM yyyy').format(e.expenseDate),
              ),
              trailing: Text(
                '₹${e.amount.toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              onLongPress: () {
                Get.defaultDialog(
                  title: 'Delete Expense',
                  middleText: 'Are you sure?',
                  textCancel: 'Cancel',
                  textConfirm: 'Delete',
                  confirmTextColor: Colors.white,
                  onConfirm: () {
                    Get.back(); // ✅ CLOSE DIALOG FIRST
                    controller.deleteExpenseWithUndo(e); // ✅ THEN DELETE
                  },
                );
              },
            );
          },
        );
      }),
    );
  }
}
