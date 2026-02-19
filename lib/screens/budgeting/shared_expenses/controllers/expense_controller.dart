import 'dart:async';

import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/expense_model.dart';

class ExpenseController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final RxList<ExpenseModel> expenses = <ExpenseModel>[].obs;
  String? _currentGroupId;

  StreamSubscription<QuerySnapshot>? _expenseListener;

  // ───────────────────────── FETCH EXPENSES ─────────────────────────

  void fetchExpenses(String groupId) {
    // If we're already listening to this group, do nothing
    if (_currentGroupId == groupId && _expenseListener != null) {
      return;
    }

    // Cancel any existing listener
    _expenseListener?.cancel();
    
    // Clear existing expenses
    expenses.clear();
    
    // Set current group ID
    _currentGroupId = groupId;

    // Start new listener
    _expenseListener = _db
        .collection('groups')
        .doc(groupId)
        .collection('expenses')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
            expenses.value =
                snapshot.docs.map((e) => ExpenseModel.fromDoc(e)).toList();
          },
          onError: (error) {
            // Handle permission errors silently when group is deleted
            if (error.toString().contains('permission-denied')) {
              // Group was likely deleted, just clear expenses
              expenses.clear();
            } else {
              // Re-throw other errors
              throw error;
            }
          },
        );
  }

  // ───────────────────────── ADD EXPENSE ─────────────────────────

  Future<void> addExpense({
    required String groupId,
    required String title,
    required double amount,
    DateTime? createdAt,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _db.collection('groups').doc(groupId).collection('expenses').add({
      'title': title,
      'amount': amount,
      'paidBy': user.uid,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt)
          : FieldValue.serverTimestamp(),
    });
  }

  // ───────────────────────── BALANCE CALCULATION ─────────────────────────

  Map<String, double> calculateBalances({
    required List<String> members,
    required DateTime? lastSettledAt,
  }) {
    final Map<String, double> balances = {
      for (final m in members) m: 0.0,
    };

    if (expenses.isEmpty || members.isEmpty) return balances;

    final List<ExpenseModel> filteredExpenses = lastSettledAt == null
        ? expenses.toList()
        : expenses.where((e) {
            if (e.createdAt == null) return false;
            return e.createdAt!.isAfter(lastSettledAt);
          }).toList();

    for (final expense in filteredExpenses) {
      final double split = expense.amount / members.length;

      for (final member in members) {
        balances[member] = balances[member]! - split;
      }

      if (balances.containsKey(expense.paidBy)) {
        balances[expense.paidBy] = balances[expense.paidBy]! + expense.amount;
      }
    }

    return balances;
  }

  // ───────────────────────── SETTLE GROUP ─────────────────────────

  Future<void> settleGroup(String groupId) async {
    await _db.collection('groups').doc(groupId).update({
      'lastSettledAt': FieldValue.serverTimestamp(),
    });
  }

  // ───────────────────────── CLEANUP ─────────────────────────

  void clearExpenses() {
    expenses.clear();
  }

  void cancelListener() {
    _expenseListener?.cancel();
    _expenseListener = null;
    _currentGroupId = null;
    expenses.clear();
  }

  @override
  void onClose() {
    cancelListener();
    super.onClose();
  }
}