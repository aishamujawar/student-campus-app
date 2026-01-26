import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'controllers/expense_controller.dart';
import 'controllers/group_controller.dart';
import 'add_expense_screen.dart';
import 'groups_list_screen.dart';
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

  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  bool get isCreator => widget.groupData['createdBy'] == currentUserId;

  final RxMap<String, String> memberNames = <String, String>{}.obs;
  List<String> _cachedMembers = [];

  bool _handledDeletion = false;

  @override
  void initState() {
    super.initState();
    expenseController = Get.put(ExpenseController());
    expenseController.fetchExpenses(widget.groupId);
  }

  Future<void> _ensureMemberNames(List<String> memberIds) async {
    for (final uid in memberIds) {
      if (memberNames.containsKey(uid)) continue;

      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      final fullName = doc.data()?['fullName'] ?? 'User';
      memberNames[uid] = fullName.toString().split(' ').first;
    }
  }

  /// ───────── SETTLE UP ─────────
  Future<void> _settleUp() async {
    await expenseController.settleGroup(widget.groupId);
    Get.snackbar('Settled', 'New cycle started');
  }

  /// ➕ ADD MEMBER
  void _showAddMemberDialog() {
    final emailController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('Add Member'),
        content: TextField(
          controller: emailController,
          decoration: const InputDecoration(labelText: 'Member email'),
        ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final email = emailController.text.trim();
              if (email.isEmpty) return;

              await groupController.addMemberToGroup(
                widget.groupId,
                email,
              );
              Get.back();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  /// 🗑️ DELETE GROUP
  void _confirmDeleteGroup() {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Group'),
        content: const Text(
          'This will permanently delete the group and all its expenses.',
        ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Cancel')),
          TextButton(
            onPressed: _deleteGroup,
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteGroup() async {
    Get.back();
    await groupController.deleteGroup(widget.groupId);
    // Navigation handled by stream safely
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.groupData['name'] ?? 'Group'),
        actions: [
          if (isCreator)
            IconButton(
              icon: const Icon(Icons.delete_outline),
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
          /// ⏳ WAIT PROPERLY
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          /// 🔥 GROUP DELETED — SAFE CHECK
          if (snapshot.hasData &&
              snapshot.data != null &&
              !snapshot.data!.exists) {
            if (!_handledDeletion) {
              _handledDeletion = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Get.snackbar('Deleted', 'Group deleted successfully');
                Get.offAll(() => const GroupsListScreen());
              });
            }
            return const SizedBox.shrink();
          }

          /// 🚫 SAFETY
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Something went wrong'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final members = List<String>.from(data['members'] ?? []);
          final Timestamp? ts = data['lastSettledAt'];
          final DateTime? lastSettledAt = ts?.toDate();

          if (_cachedMembers.toString() != members.toString()) {
            _cachedMembers = List.from(members);
            _ensureMemberNames(members);
          }

          return Column(
            children: [
              /// ───────── BALANCE ─────────
              Obx(() {
                expenseController.expenses.length;
                final balances = expenseController.calculateBalances(
                  members: members,
                  lastSettledAt: lastSettledAt,
                );
                final yourBalance = balances[currentUserId] ?? 0.0;

                return BalanceCard(
                  balanceText: yourBalance == 0
                      ? 'You are settled up'
                      : yourBalance > 0
                          ? 'You will receive ₹${yourBalance.toStringAsFixed(2)}'
                          : 'You owe ₹${yourBalance.abs().toStringAsFixed(2)}',
                );
              }),

              if (isCreator)
                TextButton(
                  onPressed: _settleUp,
                  child: const Text(
                    'Settle up',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),

              /// ───────── MEMBERS ─────────
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
                        icon: const Icon(Icons.add),
                        onPressed: _showAddMemberDialog,
                      ),
                  ],
                ),
              ),

              Obx(() {
                return Wrap(
                  spacing: 8,
                  children: members.map((uid) {
                    final name = uid == currentUserId
                        ? 'You'
                        : memberNames[uid] ?? 'Member';

                    return Chip(
                      label: Text(name),
                      deleteIcon: isCreator && uid != currentUserId
                          ? const Icon(Icons.close)
                          : null,
                      onDeleted: isCreator && uid != currentUserId
                          ? () {
                              groupController.removeMemberFromGroup(
                                widget.groupId,
                                uid,
                              );
                            }
                          : null,
                    );
                  }).toList(),
                );
              }),

              /// ───────── ADD EXPENSE ─────────
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add Expense'),
                  onPressed: () {
                    Get.to(() => AddExpenseScreen(groupId: widget.groupId));
                  },
                ),
              ),

              if (lastSettledAt != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(
                    'Settled on ${lastSettledAt.day}/${lastSettledAt.month}/${lastSettledAt.year}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),

              /// ───────── EXPENSE LIST ─────────
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
                        title:
                            '${expense.title} • ${expense.createdAt.day}/${expense.createdAt.month}/${expense.createdAt.year}',
                        amount: expense.amount,
                        paidByName: paidByYou
                            ? 'You'
                            : memberNames[expense.paidBy] ?? 'Member',
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
