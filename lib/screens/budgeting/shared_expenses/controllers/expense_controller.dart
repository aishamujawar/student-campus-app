import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/expense_model.dart';

class ExpenseController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final RxList<ExpenseModel> expenses = <ExpenseModel>[].obs;

  // ───────────────────────── FETCH EXPENSES ─────────────────────────

  Future<void> fetchExpenses(String groupId) async {
    final snapshot = await _db
        .collection('groups')
        .doc(groupId)
        .collection('expenses')
        .orderBy('createdAt', descending: true)
        .get();

    expenses.value = snapshot.docs.map((e) => ExpenseModel.fromDoc(e)).toList();
  }

  // ───────────────────────── ADD EXPENSE ─────────────────────────

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

  // ───────────────────────── BALANCE CALCULATION ─────────────────────────
  // balance > 0 → user should receive
  // balance < 0 → user owes

  Map<String, double> calculateBalances(List<String> members) {
    final Map<String, double> balances = {
      for (final m in members) m: 0.0,
    };

    if (members.isEmpty || expenses.isEmpty) return balances;

    for (final expense in expenses) {
      final splitAmount = expense.amount / members.length;

      // Everyone owes their equal share
      for (final memberId in members) {
        balances[memberId] = balances[memberId]! - splitAmount;
      }

      // Payer gets credited full amount
      balances[expense.paidBy] = balances[expense.paidBy]! + expense.amount;
    }

    return balances;
  }

  // ───────────────────────── SETTLE UP LOGIC ─────────────────────────
  // Returns clear instructions like:
  // Pay ₹300 to userX
  // Receive ₹150 from userY

  List<Map<String, dynamic>> getSettlementSuggestions({
    required String currentUserId,
    required List<String> members,
  }) {
    final balances = calculateBalances(members);
    final List<Map<String, dynamic>> settlements = [];

    if (!balances.containsKey(currentUserId)) return settlements;

    final currentBalance = balances[currentUserId]!;

    // Already settled
    if (currentBalance == 0) return settlements;

    if (currentBalance < 0) {
      // YOU OWE OTHERS
      double remaining = currentBalance.abs();

      for (final entry in balances.entries) {
        if (entry.key == currentUserId) continue;

        if (entry.value > 0 && remaining > 0) {
          final amount = entry.value >= remaining ? remaining : entry.value;

          settlements.add({
            'to': entry.key,
            'amount': amount,
          });

          remaining -= amount;
        }
      }
    } else {
      // OTHERS OWE YOU
      double remaining = currentBalance;

      for (final entry in balances.entries) {
        if (entry.key == currentUserId) continue;

        if (entry.value < 0 && remaining > 0) {
          final amount =
              entry.value.abs() >= remaining ? remaining : entry.value.abs();

          settlements.add({
            'from': entry.key,
            'amount': amount,
          });

          remaining -= amount;
        }
      }
    }

    return settlements;
  }
}
