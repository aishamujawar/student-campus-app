import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/expense_model.dart';

class ExpenseController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final RxList<ExpenseModel> expenses = <ExpenseModel>[].obs;

  /// FETCH EXPENSES
  Future<void> fetchExpenses(String groupId) async {
    final snapshot = await _db
        .collection('groups')
        .doc(groupId)
        .collection('expenses')
        .orderBy('createdAt', descending: true)
        .get();

    expenses.value = snapshot.docs.map((e) => ExpenseModel.fromDoc(e)).toList();
  }

  /// ADD EXPENSE
  Future<void> addExpense({
    required String groupId,
    required String title,
    required double amount,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    await _db.collection('groups').doc(groupId).collection('expenses').add({
      'title': title,
      'amount': amount,
      'paidBy': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await fetchExpenses(groupId);
  }

  /// ✅ CORRECT SPLIT LOGIC
  Map<String, double> calculateBalances(List<String> members) {
    final Map<String, double> balances = {
      for (final m in members) m: 0.0,
    };

    if (members.isEmpty) return balances;

    for (final expense in expenses) {
      final splitAmount = expense.amount / members.length;

      // Everyone owes their share
      for (final member in members) {
        balances[member] = balances[member]! - splitAmount;
      }

      // Payer gets full amount
      balances[expense.paidBy] = balances[expense.paidBy]! + expense.amount;
    }

    return balances;
  }
}
