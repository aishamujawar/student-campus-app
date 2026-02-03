import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CalendarService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser!.uid;

  // =====================================================
  // INITIALIZE (Ensures meta document exists)
  // =====================================================

  Future<void> _ensureInitialized() async {
    final metaRef = _firestore
        .collection('users')
        .doc(_uid)
        .collection('calendar')
        .doc('meta');

    await metaRef.set({
      'initialized': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // =====================================================
  // CATEGORY MANAGEMENT
  // =====================================================

  CollectionReference<Map<String, dynamic>> get _categoryRef {
    return _firestore
        .collection('users')
        .doc(_uid)
        .collection('calendar')
        .doc('meta')
        .collection('categories');
  }

  CollectionReference<Map<String, dynamic>> get _dayRef {
    return _firestore
        .collection('users')
        .doc(_uid)
        .collection('calendar')
        .doc('meta')
        .collection('days');
  }

  Future<void> saveCategory(CalendarCategoryModel category) async {
    await _ensureInitialized();
    
    await _categoryRef.doc(category.id).set({
      'name': category.name,
      'color': category.color.value,
      'isSystem': category.isSystem,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteCategory(String categoryId) async {
    // Delete the category
    await _categoryRef.doc(categoryId).delete();

    // Remove this category from all days
    final daysWithCategory = await _dayRef
        .where('categoryId', isEqualTo: categoryId)
        .get();

    final batch = _firestore.batch();
    for (final doc in daysWithCategory.docs) {
      batch.delete(doc.reference);
    }
    
    if (daysWithCategory.docs.isNotEmpty) {
      await batch.commit();
    }
  }

  Future<List<CalendarCategoryModel>> loadCategories() async {
    await _ensureInitialized();
    
    final snapshot = await _categoryRef
        .orderBy('createdAt')
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return CalendarCategoryModel(
        id: doc.id,
        name: data['name'] ?? 'Unnamed',
        color: Color(data['color'] ?? Colors.grey.value),
        isSystem: data['isSystem'] ?? false,
      );
    }).toList();
  }

  // =====================================================
  // DAY COLORING OPERATIONS
  // =====================================================

  Future<void> setDayCategory({
    required DateTime date,
    required CalendarCategoryModel category,
  }) async {
    await _ensureInitialized();
    
    final dateKey = _formatDateKey(date);

    await _dayRef.doc(dateKey).set({
      'date': dateKey,
      'categoryId': category.id,
      'categoryName': category.name,
      'color': category.color.value,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> clearDay(DateTime date) async {
    await _ensureInitialized();
    
    final dateKey = _formatDateKey(date);
    await _dayRef.doc(dateKey).delete();
  }

  Future<Map<String, CalendarDayModel>> loadColoredDays() async {
    await _ensureInitialized();
    
    final snapshot = await _dayRef.get();
    final Map<String, CalendarDayModel> result = {};

    for (final doc in snapshot.docs) {
      final data = doc.data();
      result[doc.id] = CalendarDayModel(
        dateKey: doc.id,
        categoryId: data['categoryId'] ?? '',
        categoryName: data['categoryName'] ?? 'Unknown',
        color: Color(data['color'] ?? Colors.grey.value),
      );
    }

    return result;
  }

  Future<CalendarDayModel?> getDay(DateTime date) async {
    await _ensureInitialized();
    
    final dateKey = _formatDateKey(date);
    final doc = await _dayRef.doc(dateKey).get();

    if (!doc.exists) return null;

    final data = doc.data()!;
    return CalendarDayModel(
      dateKey: dateKey,
      categoryId: data['categoryId'] ?? '',
      categoryName: data['categoryName'] ?? 'Unknown',
      color: Color(data['color'] ?? Colors.grey.value),
    );
  }

  // =====================================================
  // DELETE ALL CALENDAR DATA (CLEAN VERSION)
  // =====================================================

  Future<void> deleteAllCalendarData() async {
    final calendarRef = _firestore
        .collection('users')
        .doc(_uid)
        .collection('calendar')
        .doc('meta');

    // Delete days collection
    final daysSnapshot = await calendarRef.collection('days').get();
    for (final doc in daysSnapshot.docs) {
      await doc.reference.delete();
    }

    // Delete categories collection
    final categoriesSnapshot = await calendarRef.collection('categories').get();
    for (final doc in categoriesSnapshot.docs) {
      await doc.reference.delete();
    }

    // Reset meta document (keep it exists but empty)
    await calendarRef.set({
      'initialized': true,
      'clearedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    print('✅ Calendar data cleared');
  }

  // =====================================================
  // UTILITY METHODS
  // =====================================================

  String _formatDateKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
           '${date.month.toString().padLeft(2, '0')}-'
           '${date.day.toString().padLeft(2, '0')}';
  }
}

// =====================================================
// DATA MODELS
// =====================================================

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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CalendarCategoryModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
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