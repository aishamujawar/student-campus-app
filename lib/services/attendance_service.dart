import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class AttendanceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser!.uid;

  // =====================================================
  // LOAD DAY CLASSES + ATTENDANCE
  // =====================================================

  Future<AttendanceDayResult> loadDay(DateTime selectedDate) async {
    final weekdayIndex = selectedDate.weekday - 1;

    final rowsSnap = await _firestore
        .collection('users')
        .doc(_uid)
        .collection('timetable')
        .where('type', isEqualTo: 'row')
        .get();

    if (rowsSnap.docs.isEmpty) {
      return AttendanceDayResult.timetableMissing();
    }

    final cellsSnap = await _firestore
        .collection('users')
        .doc(_uid)
        .collection('timetable')
        .where('type', isEqualTo: 'cell')
        .where('dayIndex', isEqualTo: weekdayIndex)
        .get();

    if (cellsSnap.docs.isEmpty) {
      return AttendanceDayResult.noClasses();
    }

    final List<TodayClass> classes = [];

    for (final cell in cellsSnap.docs) {
      final row = rowsSnap.docs.firstWhere(
        (r) => r['rowIndex'] == cell['rowIndex'],
      );

      final classId =
          '${cell['subjectId']}_${cell['rowIndex']}_${cell['dayIndex']}';

      if (classes.any((c) => c.classId == classId)) continue;

      classes.add(
        TodayClass(
          classId: classId,
          subjectId: cell['subjectId'].toString(),
          subjectName: cell['subjectName'],
          startTime: row['startTime'],
          endTime: row['endTime'],
        ),
      );
    }

    classes.sort((a, b) => a.startTime.compareTo(b.startTime));

    final dateKey = DateFormat('yyyy-MM-dd').format(selectedDate);
    final Map<String, String> attendance = {};

    try {
      final snap = await _firestore
          .collection('users')
          .doc(_uid)
          .collection('attendance')
          .doc(dateKey)
          .collection('records')
          .get();

      for (final d in snap.docs) {
        attendance[d.id] = d['status'];
      }
    } catch (_) {}

    return AttendanceDayResult.success(classes, attendance);
  }

  // =====================================================
  // LOAD SUBJECTS
  // =====================================================

  Future<Map<String, String>> loadSubjects() async {
    final snap = await _firestore
        .collection('users')
        .doc(_uid)
        .collection('timetable')
        .where('type', isEqualTo: 'cell')
        .get();

    final Map<String, String> subjects = {};

    for (final cell in snap.docs) {
      final id = cell['subjectId']?.toString() ?? '';
      final name = cell['subjectName']?.toString() ?? '';
      if (id.isNotEmpty && name.isNotEmpty) {
        subjects[id] = name;
      }
    }

    return subjects;
  }

  // =====================================================
  // LOAD SUBJECT STATS
  // =====================================================

  Future<SubjectStatsResult> loadSubjectStats(String subjectId) async {
    final now = DateTime.now();
    final year = now.year;

    final Map<String, Map<String, int>> months = {
      for (int i = 1; i <= 12; i++)
        DateFormat('MMM').format(DateTime(year, i)): {
          'held': 0,
          'attended': 0,
        }
    };

    int totalHeld = 0;
    int totalAttended = 0;

    final days = await _firestore
        .collection('users')
        .doc(_uid)
        .collection('attendance')
        .get();

    for (final day in days.docs) {
      final records = await day.reference.collection('records').get();

      for (final r in records.docs) {
        final data = r.data();
        if (data['subjectId'] != subjectId) continue;
        if (data['status'] == 'cancelled') continue;

        totalHeld++;

        final parts = day.id.split('-');
        final date = parts.length == 3
            ? DateTime(
                int.parse(parts[0]),
                int.parse(parts[1]),
                int.parse(parts[2]),
              )
            : DateTime.now();

        final month = DateFormat('MMM').format(date);
        months[month]!['held'] =
            (months[month]!['held'] ?? 0) + 1;

        if (data['status'] == 'present') {
          totalAttended++;
          months[month]!['attended'] =
              (months[month]!['attended'] ?? 0) + 1;
        }
      }
    }

    return SubjectStatsResult(
      totalHeld: totalHeld,
      totalAttended: totalAttended,
      months: months,
    );
  }

  // =====================================================
  // MARK ATTENDANCE
  // =====================================================

  Future<void> markAttendance({
    required DateTime date,
    required String classId,
    required String status,
    required String subjectId,
    bool toggleOff = false,
  }) async {
    final dateKey = DateFormat('yyyy-MM-dd').format(date);

    if (toggleOff) {
      await _firestore
          .collection('users')
          .doc(_uid)
          .collection('attendance')
          .doc(dateKey)
          .collection('records')
          .doc(classId)
          .delete();
      return;
    }

    await _firestore
        .collection('users')
        .doc(_uid)
        .collection('attendance')
        .doc(dateKey)
        .set({
          'date': dateKey,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

    await _firestore
        .collection('users')
        .doc(_uid)
        .collection('attendance')
        .doc(dateKey)
        .collection('records')
        .doc(classId)
        .set({
          'status': status,
          'subjectId': subjectId,
          'markedAt': FieldValue.serverTimestamp(),
        });
  }

  // =====================================================
  // MIGRATION
  // =====================================================

  Future<String> migrateOldRecords() async {
    String log = 'Starting migration...\n';

    final days = await _firestore
        .collection('users')
        .doc(_uid)
        .collection('attendance')
        .get();

    for (final day in days.docs) {
      await day.reference.set({
        'date': day.id,
        'migrated': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final records = await day.reference.collection('records').get();

      for (final r in records.docs) {
        if (r.data()['subjectId'] != null) continue;

        final parts = r.id.split('_');
        if (parts.length < 3) continue;

        final subjectId =
            parts.sublist(0, parts.length - 2).join('_');

        await r.reference.update({
          'subjectId': subjectId,
          'migratedAt': FieldValue.serverTimestamp(),
        });
      }
    }

    log += 'Migration complete.\n';
    return log;
  }
}

// =====================================================
// MODELS
// =====================================================

class TodayClass {
  final String classId;
  final String subjectId;
  final String subjectName;
  final String startTime;
  final String endTime;

  TodayClass({
    required this.classId,
    required this.subjectId,
    required this.subjectName,
    required this.startTime,
    required this.endTime,
  });
}

class AttendanceDayResult {
  final bool timetableMissing;
  final bool noClasses;
  final List<TodayClass> classes;
  final Map<String, String> attendance;

  AttendanceDayResult._({
    required this.timetableMissing,
    required this.noClasses,
    required this.classes,
    required this.attendance,
  });

  factory AttendanceDayResult.success(
    List<TodayClass> c,
    Map<String, String> a,
  ) =>
      AttendanceDayResult._(
        timetableMissing: false,
        noClasses: false,
        classes: c,
        attendance: a,
      );

  factory AttendanceDayResult.noClasses() =>
      AttendanceDayResult._(
        timetableMissing: false,
        noClasses: true,
        classes: const [],
        attendance: const {},
      );

  factory AttendanceDayResult.timetableMissing() =>
      AttendanceDayResult._(
        timetableMissing: true,
        noClasses: false,
        classes: const [],
        attendance: const {},
      );
}

class SubjectStatsResult {
  final int totalHeld;
  final int totalAttended;
  final Map<String, Map<String, int>> months;

  SubjectStatsResult({
    required this.totalHeld,
    required this.totalAttended,
    required this.months,
  });
}