import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/personal_expense_model.dart';

class PersonalExpenseController extends GetxController {
  // ================= UI STATE =================
  final RxBool isLoading = false.obs;

  // ================= DATA =================
  final RxList<PersonalExpense> expenses = <PersonalExpense>[].obs;
  final RxList<PersonalExpense> filteredExpenses = <PersonalExpense>[].obs;

  // ================= METRICS =================
  final RxDouble totalAmount = 0.0.obs;
  final RxDouble thisMonthAmount = 0.0.obs;

  final RxMap<String, double> categoryTotals = <String, double>{}.obs;
  final RxMap<String, double> monthlyTotals = <String, double>{}.obs;

  // ================= FILTERS =================
  String? _selectedCategory;
  DateTime? _selectedMonth;

  // ================= UNDO DELETE =================
  PersonalExpense? _lastDeletedExpense;
  int? _lastDeletedIndex;
  bool _undoUsed = false;

  // ================= FIREBASE =================
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void onInit() {
    super.onInit();
    if (_auth.currentUser != null) {
      fetchExpenses();
    }
  }

  // ================= FETCH =================
  Future<void> fetchExpenses() async {
    final user = _auth.currentUser;
    if (user == null) return;

    isLoading.value = true;

    try {
      final snapshot = await _db
          .collection('users')
          .doc(user.uid)
          .collection('personal_expenses')
          .orderBy('expenseDate', descending: true)
          .get();

      expenses.assignAll(
        snapshot.docs.map((d) => PersonalExpense.fromFirestore(d)),
      );

      _applyFiltersInternal();
    } catch (e) {
      Get.log('❌ Fetch error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ================= FILTER API =================
  void applyFilters({String? category, DateTime? month}) {
    _selectedCategory = category;
    _selectedMonth = month;
    _applyFiltersInternal();
  }

  void clearFilters() {
    _selectedCategory = null;
    _selectedMonth = null;
    _applyFiltersInternal();
  }

  // ================= FILTER LOGIC =================
  void _applyFiltersInternal() {
    filteredExpenses.assignAll(
      expenses.where((e) {
        final categoryMatch =
            _selectedCategory == null || e.category == _selectedCategory;

        final monthMatch = _selectedMonth == null ||
            (e.expenseDate.year == _selectedMonth!.year &&
                e.expenseDate.month == _selectedMonth!.month);

        return categoryMatch && monthMatch;
      }).toList(),
    );

    _recalculate();
  }

  // ================= ADD =================
  Future<void> addExpense({
    required String title,
    required double amount,
    required String category,
    required DateTime date,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final docRef = _db
        .collection('users')
        .doc(user.uid)
        .collection('personal_expenses')
        .doc();

    final expense = PersonalExpense(
      id: docRef.id,
      title: title,
      amount: amount,
      category: category,
      expenseDate: date,
    );

    await docRef.set(expense.toMap());

    expenses.insert(0, expense);
    _applyFiltersInternal();
  }

  // ================= UPDATE =================
  Future<void> updateExpense({
    required String id,
    required String title,
    required double amount,
    required String category,
    required DateTime date,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final index = expenses.indexWhere((e) => e.id == id);
    if (index == -1) return;

    final updatedExpense = expenses[index].copyWith(
      title: title,
      amount: amount,
      category: category,
      expenseDate: date,
    );

    await _db
        .collection('users')
        .doc(user.uid)
        .collection('personal_expenses')
        .doc(id)
        .update(updatedExpense.toMap());

    expenses[index] = updatedExpense;
    expenses.refresh();
    _applyFiltersInternal();
  }

  // ================= DELETE WITH UNDO =================
  Future<void> deleteExpenseWithUndo(PersonalExpense expense) async {
    final user = _auth.currentUser;
    if (user == null) return;

    _undoUsed = false;
    _lastDeletedExpense = expense;
    _lastDeletedIndex = expenses.indexWhere((e) => e.id == expense.id);

    // Remove immediately from UI
    expenses.removeWhere((e) => e.id == expense.id);
    _applyFiltersInternal();

    // Show snackbar AFTER dialog is closed
    Get.closeAllSnackbars();

    Get.snackbar(
      'Expense deleted',
      'This action can be undone',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 4),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: 20,
      backgroundColor: const Color(0xFF121212),
      colorText: Colors.white.withOpacity(0.9),
      boxShadows: [
        BoxShadow(
          color: Colors.black.withOpacity(0.4),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
      mainButton: TextButton(
        onPressed: () {
          _undoUsed = true;
          _undoDelete();
          Get.closeCurrentSnackbar();
        },
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: Theme.of(Get.context!).colorScheme.primary,
              width: 1.2,
            ),
          ),
          foregroundColor: Theme.of(Get.context!).colorScheme.primary,
        ),
        child: const Text(
          'UNDO',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );

    // Wait before permanent delete
    await Future.delayed(const Duration(seconds: 4));

    if (!_undoUsed) {
      await _db
          .collection('users')
          .doc(user.uid)
          .collection('personal_expenses')
          .doc(expense.id)
          .delete();
    }

    _lastDeletedExpense = null;
    _lastDeletedIndex = null;
  }

  void _undoDelete() {
    if (_lastDeletedExpense == null || _lastDeletedIndex == null) return;

    expenses.insert(_lastDeletedIndex!, _lastDeletedExpense!);
    _applyFiltersInternal();
  }

  // ================= METRICS =================
  void _recalculate() {
    totalAmount.value = 0;
    thisMonthAmount.value = 0;
    categoryTotals.clear();
    monthlyTotals.clear();

    final now = DateTime.now();

    for (final e in filteredExpenses) {
      totalAmount.value += e.amount;

      categoryTotals[e.category] = (categoryTotals[e.category] ?? 0) + e.amount;

      final key =
          '${e.expenseDate.year}-${e.expenseDate.month.toString().padLeft(2, '0')}';

      monthlyTotals[key] = (monthlyTotals[key] ?? 0) + e.amount;
    }

    for (final e in expenses) {
      if (e.expenseDate.year == now.year && e.expenseDate.month == now.month) {
        thisMonthAmount.value += e.amount;
      }
    }
  }
}
