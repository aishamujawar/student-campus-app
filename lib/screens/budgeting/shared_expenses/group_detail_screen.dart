import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'controllers/expense_controller.dart';
import 'controllers/group_controller.dart';
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
  final GroupController groupController = Get.find();

  final currentUserId = FirebaseAuth.instance.currentUser!.uid;

  bool get isCreator => widget.groupData['createdBy'] == currentUserId;

  @override
  void initState() {
    super.initState();
    expenseController = Get.put(ExpenseController());
    expenseController.fetchExpenses(widget.groupId);
  }

  // ───────────────────────── ADD MEMBER DIALOG ─────────────────────────

  void _showAddMemberDialog() {
    final emailController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('Add Member'),
        content: TextField(
          controller: emailController,
          decoration: const InputDecoration(hintText: 'Enter email'),
        ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await groupController.addMemberToGroup(
                widget.groupId,
                emailController.text,
              );
              Get.back();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  // ───────────────────────── DELETE GROUP ─────────────────────────

  void _confirmDeleteGroup() {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Group'),
        content: const Text(
          'This will permanently delete the group and all expenses.',
        ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await groupController.deleteGroup(widget.groupId);
              Get.back();
              Get.back();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // ───────────────────────── SETTLE UP ─────────────────────────

  void _settleUp() {
    Get.snackbar(
      'Settle Up',
      'Settlement logic will be added next',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.groupData['name'] ?? 'Group'),
        actions: [
          if (isCreator)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _confirmDeleteGroup,
            ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('groups')
            .doc(widget.groupId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final members = List<String>.from(data['members'] ?? []);

          return Column(
            children: [
              // ───────────────────────── BALANCE CARD ─────────────────────────
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

              // ───────────────────────── SETTLE UP BUTTON ─────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Settle Up'),
                    onPressed: _settleUp,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // ───────────────────────── MEMBERS ─────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Members',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    if (isCreator)
                      IconButton(
                        icon: const Icon(Icons.person_add),
                        onPressed: _showAddMemberDialog,
                      ),
                  ],
                ),
              ),

              SizedBox(
                height: 70,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: members.length,
                  itemBuilder: (context, index) {
                    final memberId = members[index];
                    final isYou = memberId == currentUserId;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Chip(
                        label: Text(isYou ? 'You' : 'Member'),
                        deleteIcon: isCreator && !isYou
                            ? const Icon(Icons.close)
                            : null,
                        onDeleted: isCreator && !isYou
                            ? () async {
                                await groupController.removeMemberFromGroup(
                                  widget.groupId,
                                  memberId,
                                );
                              }
                            : null,
                      ),
                    );
                  },
                ),
              ),

              const Divider(),

              // ───────────────────────── ADD EXPENSE ─────────────────────────
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Add Expense'),
                    onPressed: () {
                      Get.to(
                        () => AddExpenseScreen(groupId: widget.groupId),
                      );
                    },
                  ),
                ),
              ),

              // ───────────────────────── EXPENSE LIST ─────────────────────────
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
          );
        },
      ),
    );
  }
}