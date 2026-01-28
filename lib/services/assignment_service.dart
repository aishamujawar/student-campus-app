import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/assignment_model.dart';

class AssignmentService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> _ref() {
    final uid = _auth.currentUser!.uid;
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('assignments');
  }

  Future<void> addAssignment(Assignment a) async {
    await _ref().add({
      'subject': a.subject,
      'title': a.title,
      'description': a.description,
      'dueDate': Timestamp.fromDate(a.dueDate),
      'status': a.status.name,
      'progress': a.progress,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<Assignment>> fetchAssignments() async {
    final snap = await _ref().get();

    return snap.docs.map((doc) {
      final d = doc.data();

      return Assignment(
        id: doc.id,
        subject: d['subject'] ?? '',
        title: d['title'] ?? '',
        description: d['description'] ?? '',
        dueDate: (d['dueDate'] as Timestamp).toDate(),
        status: AssignmentStatus.values
            .firstWhere((e) => e.name == d['status']),
        progress: d['progress'] ?? 0,
      );
    }).toList();
  }

  Future<void> updateAssignment(Assignment a) async {
    await _ref().doc(a.id).update({
      'status': a.status.name,
      'progress': a.progress,
    });
  }

  Future<void> deleteAssignment(String id) async {
    await _ref().doc(id).delete();
  }
  
  // ✅ FIXED: Exclude submitted assignments from count
  Future<Map<String, int>> getAssignmentCountByDate() async {
    final snap = await _ref().get();
    final Map<String, int> result = {};

    for (final doc in snap.docs) {
      final d = doc.data();

      // ❗ IGNORE submitted assignments
      if (d['status'] == 'submitted') continue;

      final raw = (d['dueDate'] as Timestamp).toDate();
      final due = DateTime(raw.year, raw.month, raw.day); // Strip time
      
      final key =
          '${due.year.toString().padLeft(4, '0')}-'
          '${due.month.toString().padLeft(2, '0')}-'
          '${due.day.toString().padLeft(2, '0')}';

      result[key] = (result[key] ?? 0) + 1;
    }

    return result;
  }

  Future<List<Assignment>> getAssignmentsForDate(DateTime date) async {
    final snap = await _ref().get();

    return snap.docs.map((doc) {
      final d = doc.data();
      final raw = (d['dueDate'] as Timestamp).toDate();
      final due = DateTime(raw.year, raw.month, raw.day); // Strip time
      
      final localDate = DateTime(date.year, date.month, date.day); // Also strip time from input

      if (due == localDate) {
        return Assignment(
          id: doc.id,
          subject: d['subject'] ?? '',
          title: d['title'] ?? '',
          description: d['description'] ?? '',
          dueDate: raw, // Keep original for display if needed
          status: AssignmentStatus.values
              .firstWhere((e) => e.name == d['status']),
          progress: d['progress'] ?? 0,
        );
      }
      return null;
    }).whereType<Assignment>().toList();
  }
}