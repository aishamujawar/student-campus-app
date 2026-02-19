import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/personal_expense_model.dart';

class PersonalExpenseController extends GetxController {
  // ================= UI STATE =================
  final RxBool isLoading = false.obs;
  final Rx<DateTime> selectedHeatmapMonth = DateTime.now().obs;

  // ================= DATA =================
  final RxList<PersonalExpense> expenses = <PersonalExpense>[].obs;
  final RxList<PersonalExpense> filteredExpenses = <PersonalExpense>[].obs;

  // ================= METRICS =================
  final RxDouble totalAmount = 0.0.obs;
  final RxDouble thisMonthAmount = 0.0.obs;

  final RxMap<String, double> categoryTotals = <String, double>{}.obs;
  final RxMap<String, double> monthlyTotals = <String, double>{}.obs;
  final RxMap<DateTime, double> dailyTotals = <DateTime, double>{}.obs; // Real calendar heatmap data
  final RxMap<int, double> weekdayTotals = <int, double>{}.obs; // Keep for secondary analysis

  // ================= FILTERS =================
  String? _selectedCategory;
  DateTime? _selectedMonth;

  // ================= UNDO DELETE =================
  PersonalExpense? _lastDeletedExpense;
  int? _lastDeletedIndex;

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

  // ================= HEATMAP NAVIGATION =================
  void nextHeatmapMonth() {
    selectedHeatmapMonth.value = DateTime(
      selectedHeatmapMonth.value.year,
      selectedHeatmapMonth.value.month + 1,
    );
  }

  void previousHeatmapMonth() {
    selectedHeatmapMonth.value = DateTime(
      selectedHeatmapMonth.value.year,
      selectedHeatmapMonth.value.month - 1,
    );
  }

  void setHeatmapMonth(DateTime month) {
    selectedHeatmapMonth.value = DateTime(month.year, month.month);
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

  // ================= DELETE (PURE, NO SNACKBAR) =================
  Future<void> deleteExpense(PersonalExpense expense) async {
    final user = _auth.currentUser;
    if (user == null) return;

    _lastDeletedIndex = expenses.indexWhere((e) => e.id == expense.id);
    _lastDeletedExpense = expense;

    // Remove from UI immediately
    expenses.removeWhere((e) => e.id == expense.id);
    _applyFiltersInternal();

    // Delete from Firebase in background
    try {
      await _db
          .collection('users')
          .doc(user.uid)
          .collection('personal_expenses')
          .doc(expense.id)
          .delete();
    } catch (e) {
      Get.log('❌ Delete error: $e');
      // If Firebase delete fails, restore the expense
      if (_lastDeletedExpense != null && _lastDeletedIndex != null) {
        expenses.insert(_lastDeletedIndex!, _lastDeletedExpense!);
        _applyFiltersInternal();
      }
      rethrow;
    }
  }

  // ================= UNDO DELETE =================
  Future<void> undoDelete() async {
    if (_lastDeletedExpense == null || _lastDeletedIndex == null) {
      return;
    }

    final user = _auth.currentUser;
    if (user == null) return;

    // Restore in UI
    expenses.insert(_lastDeletedIndex!, _lastDeletedExpense!);
    _applyFiltersInternal();

    // Save to Firebase
    try {
      await _db
          .collection('users')
          .doc(user.uid)
          .collection('personal_expenses')
          .doc(_lastDeletedExpense!.id)
          .set(_lastDeletedExpense!.toMap());
    } catch (e) {
      Get.log('❌ Undo save error: $e');
      // If save fails, remove from UI
      expenses.removeWhere((e) => e.id == _lastDeletedExpense!.id);
      _applyFiltersInternal();
      rethrow;
    } finally {
      // Clear undo state
      _lastDeletedExpense = null;
      _lastDeletedIndex = null;
    }
  }

  // ================= METRICS =================
  void _recalculate() {
    // Reset all values
    totalAmount.value = 0;
    thisMonthAmount.value = 0;
    
    // Create new maps instead of clearing and modifying
    final Map<String, double> newCategoryTotals = {};
    final Map<String, double> newMonthlyTotals = {};
    final Map<DateTime, double> newDailyTotals = {}; // Real calendar heatmap
    final Map<int, double> newWeekdayTotals = {}; // 1 = Mon ... 7 = Sun
    
    final now = DateTime.now();

    for (final e in filteredExpenses) {
      totalAmount.value += e.amount;

      // Calculate category totals
      newCategoryTotals[e.category] = 
          (newCategoryTotals[e.category] ?? 0) + e.amount;

      // Calculate monthly totals
      final key =
          '${e.expenseDate.year}-${e.expenseDate.month.toString().padLeft(2, '0')}';
      newMonthlyTotals[key] = (newMonthlyTotals[key] ?? 0) + e.amount;
      
      // Calculate daily totals for REAL calendar heatmap
      final dateKey = DateTime(
        e.expenseDate.year,
        e.expenseDate.month,
        e.expenseDate.day,
      );
      newDailyTotals[dateKey] = (newDailyTotals[dateKey] ?? 0) + e.amount;
      
      // Calculate weekday totals (secondary analysis)
      final weekday = e.expenseDate.weekday; // 1-7
      newWeekdayTotals[weekday] = (newWeekdayTotals[weekday] ?? 0) + e.amount;
      
      // Calculate this month amount
      if (e.expenseDate.year == now.year && e.expenseDate.month == now.month) {
        thisMonthAmount.value += e.amount;
      }
    }

    // Assign new maps to RxMap - this triggers reactivity
    categoryTotals.assignAll(newCategoryTotals);
    monthlyTotals.assignAll(newMonthlyTotals);
    dailyTotals.assignAll(newDailyTotals);
    weekdayTotals.assignAll(newWeekdayTotals);
  }

  // ================= HEATMAP METHODS =================
  // Get daily totals for a specific month (for heatmap)
  Map<DateTime, double> getDailyTotalsForMonth(DateTime month) {
    final Map<DateTime, double> result = {};
    final int year = month.year;
    final int monthNum = month.month;
    
    for (final entry in dailyTotals.entries) {
      if (entry.key.year == year && entry.key.month == monthNum) {
        result[entry.key] = entry.value;
      }
    }
    
    return result;
  }

  // Get maximum spending for a month (for intensity scaling)
  double getMaxSpendingForMonth(DateTime month) {
    double max = 0;
    final int year = month.year;
    final int monthNum = month.month;
    
    for (final entry in dailyTotals.entries) {
      if (entry.key.year == year && entry.key.month == monthNum) {
        if (entry.value > max) {
          max = entry.value;
        }
      }
    }
    
    return max;
  }

  // Get all days in a month (1-31) with their spending
  List<Map<String, dynamic>> getCalendarHeatmapData(DateTime month) {
    final List<Map<String, dynamic>> result = [];
    final int year = month.year;
    final int monthNum = month.month;
    final int daysInMonth = DateTime(year, monthNum + 1, 0).day;
    
    final monthlyData = getDailyTotalsForMonth(month);
    final maxSpending = getMaxSpendingForMonth(month);
    
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(year, monthNum, day);
      final amount = monthlyData[date] ?? 0;
      final intensity = maxSpending > 0 ? amount / maxSpending : 0;
      
      result.add({
        'date': date,
        'day': day,
        'amount': amount,
        'intensity': intensity,
        'weekday': date.weekday, // 1=Mon ... 7=Sun
      });
    }
    
    return result;
  }

  // Get month name for display
  String getHeatmapMonthName() {
    final monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${monthNames[selectedHeatmapMonth.value.month - 1]} ${selectedHeatmapMonth.value.year}';
  }

  // ================= GETTERS =================
  // Get category names sorted by amount (descending)
  List<String> getSortedCategories() {
    final list = categoryTotals.entries
        .where((entry) => entry.value > 0)
        .toList();
    
    list.sort((a, b) => b.value.compareTo(a.value));
    
    return list.map((entry) => entry.key).toList();
  }

  // Get category amounts sorted (descending)
  List<double> getSortedCategoryAmounts() {
    final list = categoryTotals.entries
        .where((entry) => entry.value > 0)
        .toList();
    
    list.sort((a, b) => b.value.compareTo(a.value));
    
    return list.map((entry) => entry.value).toList();
  }

  // Get months with expenses (formatted) sorted descending (newest first)
  List<String> getSortedMonths() {
    final list = monthlyTotals.keys.toList();
    list.sort((a, b) => b.compareTo(a)); // Descending sort
    return list;
  }

  // Get monthly amounts sorted (descending)
  List<double> getSortedMonthlyAmounts() {
    return getSortedMonths().map((month) => monthlyTotals[month] ?? 0).toList();
  }

  // Get percentage for a category
  double getCategoryPercentage(String category) {
    if (totalAmount.value == 0) return 0;
    final amount = categoryTotals[category] ?? 0;
    return (amount / totalAmount.value) * 100;
  }

  // Get top N categories by amount (default: top 3)
  List<MapEntry<String, double>> getTopCategories({int limit = 3}) {
    final list = categoryTotals.entries
        .where((entry) => entry.value > 0)
        .toList();

    list.sort((a, b) => b.value.compareTo(a.value));

    return list.take(limit).toList();
  }

  // Get categories with their percentages
  Map<String, double> getCategoryPercentages() {
    final Map<String, double> percentages = {};
    
    if (totalAmount.value > 0) {
      for (final entry in categoryTotals.entries) {
        if (entry.value > 0) {
          percentages[entry.key] = (entry.value / totalAmount.value) * 100;
        }
      }
    }
    
    return percentages;
  }

  // Get formatted month names (e.g., "Jan 2024")
  List<String> getFormattedMonthNames() {
    return getSortedMonths().map((monthKey) {
      // monthKey format: "2024-01"
      final parts = monthKey.split('-');
      if (parts.length == 2) {
        final year = parts[0];
        final month = int.tryParse(parts[1]) ?? 1;
        final monthNames = [
          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
        ];
        return '${monthNames[month - 1]} $year';
      }
      return monthKey;
    }).toList();
  }

  // Get data for pie chart - returns list of (category, amount, percentage)
  List<Map<String, dynamic>> getPieChartData() {
    final List<Map<String, dynamic>> data = [];
    
    if (totalAmount.value > 0) {
      final entries = categoryTotals.entries
          .where((entry) => entry.value > 0)
          .toList();
      
      entries.sort((a, b) => b.value.compareTo(a.value));
      
      for (final entry in entries) {
        data.add({
          'category': entry.key,
          'amount': entry.value,
          'percentage': (entry.value / totalAmount.value) * 100,
        });
      }
    }
    
    return data;
  }

  // Get total for specific category
  double getCategoryTotal(String category) {
    return categoryTotals[category] ?? 0;
  }

  // Get total for specific month
  double getMonthlyTotal(String monthKey) {
    return monthlyTotals[monthKey] ?? 0;
  }

  // Get weekday names for display
  String getWeekdayName(int weekday) {
    const weekdays = [
      'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
    ];
    return weekdays[weekday - 1];
  }

  // Get weekday totals sorted by weekday (Mon-Sun)
  List<MapEntry<int, double>> getSortedWeekdayTotals() {
    return weekdayTotals.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
  }

  // Get weekday totals as list for heatmap
  List<double> getWeekdayAmounts() {
    final amounts = List<double>.filled(7, 0.0);
    
    for (final entry in weekdayTotals.entries) {
      if (entry.key >= 1 && entry.key <= 7) {
        amounts[entry.key - 1] = entry.value;
      }
    }
    
    return amounts;
  }

  // Check if there's any data to show
  bool get hasData => filteredExpenses.isNotEmpty;
  
  // Check if there are categories with data
  bool get hasCategoryData => categoryTotals.values.any((value) => value > 0);
  
  // Check if there are monthly data
  bool get hasMonthlyData => monthlyTotals.isNotEmpty;
  
  // Check if there are weekday data for heatmap
  bool get hasWeekdayData => weekdayTotals.values.any((value) => value > 0);
  
  // Check if there are daily data for calendar heatmap
  bool get hasDailyData => dailyTotals.isNotEmpty;

  // =====================================================
  // CHATBOT SUMMARY (READ-ONLY)
  // =====================================================

  Map<String, dynamic> getExpenseSummaryForChatbot() {
    // Use filteredExpenses for current context, or all expenses if no filters
    final List<PersonalExpense> expenseList = 
        filteredExpenses.isNotEmpty ? filteredExpenses : expenses;
    
    if (expenseList.isEmpty) {
      return {
        'total': 0.0,
        'thisMonth': 0.0,
        'topCategory': null,
        'categories': {},
      };
    }

    final now = DateTime.now();
    double total = 0;
    double thisMonth = 0;
    final Map<String, double> categories = {};

    for (final e in expenseList) {
      total += e.amount;

      if (e.expenseDate.year == now.year &&
          e.expenseDate.month == now.month) {
        thisMonth += e.amount;
      }

      categories[e.category] =
          (categories[e.category] ?? 0) + e.amount;
    }

    String? topCategory;
    double maxAmount = 0;

    categories.forEach((cat, amt) {
      if (amt > maxAmount) {
        maxAmount = amt;
        topCategory = cat;
      }
    });

    return {
      'total': total,
      'thisMonth': thisMonth,
      'topCategory': topCategory,
      'categories': categories,
    };
  }
}