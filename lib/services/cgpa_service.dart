import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CgpaService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser!.uid;

  // ================= CGPA COLLECTION =================

  CollectionReference<Map<String, dynamic>> get _cgpaRef =>
      _firestore
          .collection('users')
          .doc(_uid)
          .collection('cgpa')
          .doc('meta')
          .collection('semesters');

  // ================= FETCH SUBJECTS FROM TIMETABLE =================

  Future<List<String>> fetchSubjectsFromTimetable() async {
    final snap = await _firestore
        .collection('users')
        .doc(_uid)
        .collection('timetable')
        .where('type', isEqualTo: 'cell')
        .get();

    final subjects = snap.docs
        .map((d) => d.data()['subjectName'] as String?)
        .whereType<String>()
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList();

    subjects.sort();
    return subjects;
  }

  // ================= SAVE SEMESTER (UPDATED FOR CREDITS) =================

  Future<void> archiveSemester({
    required int semester,
    required Map<String, Map<String, dynamic>> subjects, // grade + credits
    required double sgpa,
  }) async {
    await _cgpaRef.doc(semester.toString()).set({
      'semester': semester,
      'subjects': subjects,
      'sgpa': sgpa,
      'archivedAt': FieldValue.serverTimestamp(),
    });
  }

  // ================= LOAD SEMESTERS (UPDATED FOR CREDITS) =================

  Future<List<Map<String, dynamic>>> loadArchivedSemesters() async {
    try {
      final snap = await _cgpaRef.orderBy('semester').get();

      return snap.docs.map((doc) {
        final d = doc.data();
        
        // Return the data as-is, the UI will handle both formats
        return {
          'semester': d['semester'],
          'subjects': d['subjects'] ?? {},
          'sgpa': (d['sgpa'] as num).toDouble(),
          'id': doc.id,
        };
      }).toList();
    } catch (e) {
      print('Error loading semesters: $e');
      return [];
    }
  }

  // ================= CGPA CALC =================

  Future<double> calculateCgpa() async {
    final semesters = await loadArchivedSemesters();
    if (semesters.isEmpty) return 0.0;

    final total = semesters.fold<double>(
      0.0,
      (sum, s) => sum + (s['sgpa'] as double),
    );

    return total / semesters.length;
  }

  // ================= INDIVIDUAL DELETE METHODS =================

  Future<void> deleteTimetable() async {
    final userRef = _firestore.collection('users').doc(_uid);
    final timetableSnap = await userRef.collection('timetable').get();
    
    for (final doc in timetableSnap.docs) {
      await doc.reference.delete();
    }
    
    print('✅ Timetable cleared (${timetableSnap.docs.length} items)');
  }

  Future<void> deleteAssignments() async {
    final userRef = _firestore.collection('users').doc(_uid);
    final assignmentsSnap = await userRef.collection('assignments').get();
    
    for (final doc in assignmentsSnap.docs) {
      await doc.reference.delete();
    }
    
    print('✅ Assignments cleared (${assignmentsSnap.docs.length} items)');
  }

  Future<void> deleteAttendance() async {
    final userRef = _firestore.collection('users').doc(_uid);
    final attendanceRef = userRef.collection('attendance');

    int totalDays = 0;
    int totalRecords = 0;

    // Get all attendance day documents (structure is now guaranteed to exist)
    final daysSnapshot = await attendanceRef.get();

    for (final dayDoc in daysSnapshot.docs) {
      totalDays++;

      // Delete records subcollection
      final recordsSnap = await dayDoc.reference.collection('records').get();
      totalRecords += recordsSnap.docs.length;

      for (final record in recordsSnap.docs) {
        await record.reference.delete();
      }

      // Delete the date document itself
      await dayDoc.reference.delete();
    }

    print('✅ Attendance cleared ($totalDays days, $totalRecords records)');
  }

  Future<void> deleteCalendar() async {
    final userRef = _firestore.collection('users').doc(_uid);
    final metaRef = userRef.collection('calendar').doc('meta');

    int totalDays = 0;
    int totalCategories = 0;

    // Delete days subcollection (always exists under meta)
    final daysSnap = await metaRef.collection('days').get();
    totalDays = daysSnap.docs.length;
    
    for (final doc in daysSnap.docs) {
      await doc.reference.delete();
    }

    // Delete categories subcollection (always exists under meta)
    final catSnap = await metaRef.collection('categories').get();
    totalCategories = catSnap.docs.length;
    
    for (final doc in catSnap.docs) {
      await doc.reference.delete();
    }

    // Reset the meta document (keep it for structure)
    await metaRef.set({
      'initialized': true,
      'clearedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    print('✅ Calendar cleared ($totalCategories categories, $totalDays days)');
  }

  Future<void> finalizeSemester() async {
    // This is a placeholder for any finalization steps
    // Could include updating analytics, sending notifications, etc.
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate work
    print('✅ Semester finalized');
  }

  // ================= LEGACY METHOD (for backward compatibility) =================

  Future<void> clearPostSemesterData() async {
    try {
      // Note: This is the OLD monolithic method
      // Use individual methods instead for step-by-step progress
      await deleteTimetable();
      await deleteAssignments();
      await deleteAttendance();
      await deleteCalendar();
      await finalizeSemester();
      
      print('✅ Post-semester data fully cleared');
    } catch (e) {
      print('Error clearing post-semester data: $e');
      rethrow;
    }
  }
}