import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'add_expense_screen.dart';
import 'widgets/expense_tile.dart';
import 'widgets/balance_card.dart';

class GroupDetailScreen extends StatelessWidget {
  final String groupId;
  final Map<String, dynamic> groupData;

  const GroupDetailScreen({
    super.key,
    required this.groupId,
    required this.groupData,
  });

  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text(groupData['name'] ?? 'Group'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Get.to(
                () => AddExpenseScreen(groupId: groupId),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          /// 🔹 Balance Summary (placeholder for now)
          const BalanceCard(
            balanceText: 'Balance will be calculated',
          ),

          /// 🔹 Expenses List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('groups')
                  .doc(groupId)
                  .collection('expenses')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('No expenses yet'),
                  );
                }

                final expenses = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: expenses.length,
                  itemBuilder: (context, index) {
                    final expense =
                        expenses[index].data() as Map<String, dynamic>;

                    final bool paidByYou = expense['paidBy'] == currentUserId;

                    return ExpenseTile(
                      title: expense['title'],
                      amount: (expense['amount'] as num).toDouble(),
                      paidByName: paidByYou ? 'You' : 'Another member',
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
