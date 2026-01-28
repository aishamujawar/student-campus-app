import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TimetableService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Future<void> saveTimetable(List<Map<String, dynamic>> slots) async {
    final uid = _auth.currentUser!.uid;

    final ref = _firestore
        .collection('users')
        .doc(uid)
        .collection('timetable');

    // delete old timetable
    final old = await ref.get();
    for (final doc in old.docs) {
      await doc.reference.delete();
    }

    // save new timetable
    for (final slot in slots) {
      await ref.add(slot);
    }
  }

  Future<List<Map<String, dynamic>>> loadTimetable() async {
    final uid = _auth.currentUser!.uid;

    final snap = await _firestore
        .collection('users')
        .doc(uid)
        .collection('timetable')
        .get();

    return snap.docs.map((d) => d.data()).toList();
  }

  Future<List<String>> fetchSubjects() async {
    final uid = _auth.currentUser!.uid;

    final snap = await _firestore
        .collection('users')
        .doc(uid)
        .collection('timetable')
        .where('type', isEqualTo: 'cell')  // Filter to only get cells with subjects
        .get();

    final subjects = snap.docs
        .map((d) => d.data()['subjectName'] as String?)  // Get subjectName field
        .whereType<String>()  // Filter out nulls and keep only strings
        .map((s) => s.trim())  // Trim whitespace
        .where((s) => s.isNotEmpty)  // Filter out empty strings
        .toSet()  // Remove duplicates
        .toList();  // Convert to list

    subjects.sort();
    return subjects;
  }
  
  // ✅ FIXED: CORRECT data model for your Firestore structure
  Future<List<Map<String, String>>> getClassesForWeekday(int dayIndex) async {
    final uid = _auth.currentUser!.uid;
    final ref = _firestore.collection('users').doc(uid).collection('timetable');

    // 1️⃣ Load time rows
    final rowSnap = await ref.where('type', isEqualTo: 'row').get();

    // 2️⃣ Load subject cells for this weekday
    final cellSnap = await ref
        .where('type', isEqualTo: 'cell')
        .where('dayIndex', isEqualTo: dayIndex)
        .get();

    // Map rowIndex -> time
    final Map<int, Map<String, String>> rows = {};
    for (final doc in rowSnap.docs) {
      final d = doc.data();
      final rowIndex = d['rowIndex'] as int?;
      if (rowIndex == null) continue;
      
      rows[rowIndex] = {
        'start': (d['startTime'] ?? '').toString(),
        'end': (d['endTime'] ?? '').toString(),
      };
    }

    final List<Map<String, String>> classes = [];

    for (final doc in cellSnap.docs) {
      final d = doc.data();
      final rowIndex = d['rowIndex'] as int?;
      if (rowIndex == null) continue;
      
      final row = rows[rowIndex];
      if (row == null) continue;

      final subjectName = d['subjectName'] as String?;
      if (subjectName == null || subjectName.trim().isEmpty) continue;

      classes.add({
        'subject': subjectName,
        'start': row['start']!,
        'end': row['end']!,
      });
    }

    // 🔁 ADDED: Sort by start time
    classes.sort((a, b) => a['start']!.compareTo(b['start']!));

    // 🔁 ADDED: Remove accidental duplicates
    final seen = <String>{};
    final unique = <Map<String, String>>[];

    for (final c in classes) {
      final key = '${c['subject']}-${c['start']}';
      if (seen.add(key)) {
        unique.add(c);
      }
    }

    return unique;
  }
}