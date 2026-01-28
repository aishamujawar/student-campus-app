import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// =====================================================
/// CALENDAR SERVICE
/// =====================================================
/// Firestore structure:
///
/// users/{uid}/calendar/categories/{categoryId}
/// users/{uid}/calendar/days/{yyyy-MM-dd}
///
class CalendarService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser!.uid;

  CollectionReference<Map<String, dynamic>> get _categoryRef =>
      _firestore
          .collection('users')
          .doc(_uid)
          .collection('calendar')
          .doc('meta')
          .collection('categories');

  CollectionReference<Map<String, dynamic>> get _dayRef =>
      _firestore
          .collection('users')
          .doc(_uid)
          .collection('calendar')
          .doc('meta')
          .collection('days');

  // =====================================================
  // CATEGORY CRUD
  // =====================================================

  Future<void> saveCategory(CalendarCategoryModel category) async {
    await _categoryRef.doc(category.id).set({
      'name': category.name,
      'color': category.color.value,
      'isSystem': category.isSystem,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteCategory(String categoryId) async {
    await _categoryRef.doc(categoryId).delete();

    // remove category from all days
    final daysSnap = await _dayRef
        .where('categoryId', isEqualTo: categoryId)
        .get();

    for (final doc in daysSnap.docs) {
      await doc.reference.delete();
    }
  }

  Future<List<CalendarCategoryModel>> loadCategories() async {
    final snap = await _categoryRef.get();

    return snap.docs.map((d) {
      final data = d.data();
      return CalendarCategoryModel(
        id: d.id,
        name: data['name'],
        color: Color(data['color']),
        isSystem: data['isSystem'] ?? false,
      );
    }).toList();
  }

  // =====================================================
  // DAY COLORING
  // =====================================================

  Future<void> setDayCategory({
    required DateTime date,
    required CalendarCategoryModel category,
  }) async {
    final key = _dateKey(date);

    await _dayRef.doc(key).set({
      'date': key,
      'categoryId': category.id,
      'categoryName': category.name,
      'color': category.color.value,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> clearDay(DateTime date) async {
    final key = _dateKey(date);
    await _dayRef.doc(key).delete();
  }

  Future<Map<String, CalendarDayModel>> loadColoredDays() async {
    final snap = await _dayRef.get();

    final Map<String, CalendarDayModel> result = {};

    for (final doc in snap.docs) {
      final data = doc.data();
      result[doc.id] = CalendarDayModel(
        dateKey: doc.id,
        categoryId: data['categoryId'],
        categoryName: data['categoryName'],
        color: Color(data['color']),
      );
    }

    return result;
  }

  // =====================================================
  // HELPERS
  // =====================================================

  String _dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

/// =====================================================
/// MODELS
/// =====================================================

class CalendarCategoryModel {
  final String id;
  final String name;
  final Color color;
  final bool isSystem;

  CalendarCategoryModel({
    required this.id,
    required this.name,
    required this.color,
    this.isSystem = false,
  });
}

class CalendarDayModel {
  final String dateKey;
  final String categoryId;
  final String categoryName;
  final Color color;

  CalendarDayModel({
    required this.dateKey,
    required this.categoryId,
    required this.categoryName,
    required this.color,
  });
}