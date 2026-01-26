import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'controllers/expense_controller.dart';

class AddExpenseScreen extends StatefulWidget {
  final String groupId;

  const AddExpenseScreen({super.key, required this.groupId});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final titleController = TextEditingController();
  final amountController = TextEditingController();

  final ExpenseController expenseController = Get.find<ExpenseController>();

  bool isLoading = false;
  DateTime selectedDate = DateTime.now(); // ✅ default today

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Expense')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Expense title'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount'),
            ),
            const SizedBox(height: 16),

            /// 📅 DATE PICKER
            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Expense Date',
                  border: OutlineInputBorder(),
                ),
                child: Text(
                  '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                ),
              ),
            ),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : _submit,
                child: isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Add Expense'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() => selectedDate = picked);
    }
  }

  Future<void> _submit() async {
    final title = titleController.text.trim();
    final rawAmount = amountController.text.trim();

    if (title.isEmpty || rawAmount.isEmpty) {
      Get.snackbar('Error', 'Please fill all fields');
      return;
    }

    final amount = double.tryParse(rawAmount);
    if (amount == null) {
      Get.snackbar('Error', 'Invalid amount');
      return;
    }

    try {
      setState(() => isLoading = true);

      await expenseController.addExpense(
        groupId: widget.groupId,
        title: title,
        amount: amount,
        createdAt: selectedDate, // ✅ date passed
      );

      Get.back();
    } catch (e) {
      Get.snackbar('Error', 'Failed to add expense');
    } finally {
      setState(() => isLoading = false);
    }
  }
}
