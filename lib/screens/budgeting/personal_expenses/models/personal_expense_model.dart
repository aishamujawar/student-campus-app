import 'package:cloud_firestore/cloud_firestore.dart';

class PersonalExpense {
  final String id;
  final String title;
  final double amount;
  final String category;
  final DateTime expenseDate;

  PersonalExpense({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.expenseDate,
  });

  /// ✅ SAFE FROM FIRESTORE
  factory PersonalExpense.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    final Timestamp? ts = data['expenseDate'] as Timestamp?;

    return PersonalExpense(
      id: doc.id,
      title: (data['title'] ?? '').toString(),
      amount: (data['amount'] ?? 0).toDouble(),
      category: (data['category'] ?? 'Other').toString(),
      expenseDate: ts?.toDate() ?? DateTime.now(),
    );
  }

  /// ✅ USED FOR ADD / UPDATE
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'amount': amount,
      'category': category,
      'expenseDate': Timestamp.fromDate(expenseDate),
    };
  }

  /// ✅ HELPFUL FOR EDITING LOCALLY
  PersonalExpense copyWith({
    String? title,
    double? amount,
    String? category,
    DateTime? expenseDate,
  }) {
    return PersonalExpense(
      id: id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      expenseDate: expenseDate ?? this.expenseDate,
    );
  }
}
