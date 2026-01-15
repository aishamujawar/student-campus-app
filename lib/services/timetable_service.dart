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
}