import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'controllers/expense_controller.dart';
import 'add_expense_screen.dart';
import 'widgets/expense_tile.dart';
import 'widgets/balance_card.dart';

class GroupDetailScreen extends StatefulWidget {
  final String groupId;
  final Map<String, dynamic> groupData;

  const GroupDetailScreen({
    super.key,
    required this.groupId,
    required this.groupData,
  });

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  late final ExpenseController expenseController;

  @override
  void initState() {
    super.initState();
    expenseController = Get.put(ExpenseController());
    expenseController.fetchExpenses(widget.groupId);
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    final List<String> members =
        List<String>.from(widget.groupData['members'] ?? []);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.groupData['name'] ?? 'Group'),
      ),
      body: Column(
        children: [
          /// BALANCE CARD
          Obx(() {
            final balances = expenseController.calculateBalances(members);

            final yourBalance = balances[currentUserId] ?? 0.0;

            return BalanceCard(
              balanceText: yourBalance == 0
                  ? 'You are settled up'
                  : yourBalance > 0
                      ? 'You will receive ₹${yourBalance.toStringAsFixed(2)}'
                      : 'You owe ₹${yourBalance.abs().toStringAsFixed(2)}',
            );
          }),

          /// ADD EXPENSE BUTTON
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add Expense'),
                onPressed: () {
                  Get.to(() => AddExpenseScreen(groupId: widget.groupId));
                },
              ),
            ),
          ),

          /// EXPENSE LIST
          Expanded(
            child: Obx(() {
              if (expenseController.expenses.isEmpty) {
                return const Center(child: Text('No expenses yet'));
              }

              return ListView.builder(
                itemCount: expenseController.expenses.length,
                itemBuilder: (context, index) {
                  final expense = expenseController.expenses[index];
                  final paidByYou = expense.paidBy == currentUserId;

                  return ExpenseTile(
                    title: expense.title,
                    amount: expense.amount,
                    paidByName: paidByYou ? 'You' : 'Another member',
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}
