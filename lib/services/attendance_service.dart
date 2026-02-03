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
    final dateKey = DateFormat('yyyy-MM-dd').format(selectedDate);

    // Load timetable rows
    final rowsSnap = await _firestore
        .collection('users')
        .doc(_uid)
        .collection('timetable')
        .where('type', isEqualTo: 'row')
        .get();

    if (rowsSnap.docs.isEmpty) {
      return AttendanceDayResult.timetableMissing();
    }

    // Load timetable cells for this weekday
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

    // Build TodayClass list
    final List<TodayClass> classes = [];
    final Set<String> seenClassIds = {};

    for (final cell in cellsSnap.docs) {
      final row = rowsSnap.docs.firstWhere(
        (r) => r['rowIndex'] == cell['rowIndex'],
      );

      final classId =
          '${cell['subjectId']}_${cell['rowIndex']}_${cell['dayIndex']}';

      // Avoid duplicates
      if (seenClassIds.contains(classId)) continue;
      seenClassIds.add(classId);

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

    // Sort by start time
    classes.sort((a, b) => a.startTime.compareTo(b.startTime));

    // Load attendance for this day
    final Map<String, String> attendance = {};
    try {
      final attendanceSnap = await _firestore
          .collection('users')
          .doc(_uid)
          .collection('attendance')
          .doc(dateKey)
          .collection('records')
          .get();

      for (final doc in attendanceSnap.docs) {
        attendance[doc.id] = doc['status'];
      }
    } catch (e) {
      // No attendance data for this day is normal
    }

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

    // Initialize monthly tracking
    final Map<String, Map<String, int>> months = {
      for (int i = 1; i <= 12; i++)
        DateFormat('MMM').format(DateTime(year, i)): {
          'held': 0,
          'attended': 0,
        }
    };

    int totalHeld = 0;
    int totalAttended = 0;

    // Load all attendance days
    final daysSnapshot = await _firestore
        .collection('users')
        .doc(_uid)
        .collection('attendance')
        .get();

    // Process each day
    for (final dayDoc in daysSnapshot.docs) {
      final recordsSnapshot = await dayDoc.reference.collection('records').get();

      for (final recordDoc in recordsSnapshot.docs) {
        final data = recordDoc.data();
        
        // Filter by subject
        if (data['subjectId'] != subjectId) continue;
        
        // Skip cancelled classes
        if (data['status'] == 'cancelled') continue;

        totalHeld++;

        // Parse date for monthly grouping
        final parts = dayDoc.id.split('-');
        if (parts.length != 3) continue;

        try {
          final date = DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]),
          );
          
          final month = DateFormat('MMM').format(date);
          
          // Update monthly counts
          months[month]!['held'] = (months[month]!['held'] ?? 0) + 1;

          if (data['status'] == 'present') {
            totalAttended++;
            months[month]!['attended'] = (months[month]!['attended'] ?? 0) + 1;
          }
        } catch (e) {
          // Skip invalid dates
          continue;
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
  // MARK ATTENDANCE (FIXED - ensures parent doc exists)
  // =====================================================

  Future<void> markAttendance({
    required DateTime date,
    required String classId,
    required String status,
    required String subjectId,
    bool toggleOff = false,
  }) async {
    final dateKey = DateFormat('yyyy-MM-dd').format(date);
    final attendanceRef = _firestore
        .collection('users')
        .doc(_uid)
        .collection('attendance')
        .doc(dateKey);

    if (toggleOff) {
      // Just delete the record
      await attendanceRef
          .collection('records')
          .doc(classId)
          .delete();
      
      // Optional: Check if day is now empty and delete parent
      final recordsSnap = await attendanceRef.collection('records').get();
      if (recordsSnap.docs.isEmpty) {
        await attendanceRef.delete();
      }
      
      return;
    }

    // ✅ CRITICAL: Ensure parent document exists
    await attendanceRef.set({
      'date': dateKey,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Save the attendance record
    await attendanceRef
        .collection('records')
        .doc(classId)
        .set({
          'status': status,
          'subjectId': subjectId,
          'markedAt': FieldValue.serverTimestamp(),
        });
  }

  // =====================================================
  // DELETE ALL ATTENDANCE (CLEAN VERSION)
  // =====================================================

  Future<void> deleteAllAttendance() async {
    final attendanceRef = _firestore
        .collection('users')
        .doc(_uid)
        .collection('attendance');

    final daysSnapshot = await attendanceRef.get();

    int totalDaysDeleted = 0;
    int totalRecordsDeleted = 0;

    for (final dayDoc in daysSnapshot.docs) {
      // Delete all records in the day
      final recordsSnapshot = await dayDoc.reference.collection('records').get();
      totalRecordsDeleted += recordsSnapshot.docs.length;
      
      for (final recordDoc in recordsSnapshot.docs) {
        await recordDoc.reference.delete();
      }

      // Delete the day document
      await dayDoc.reference.delete();
      totalDaysDeleted++;
    }

    print('✅ Deleted $totalDaysDeleted days with $totalRecordsDeleted records');
  }
}

// =====================================================
// DATA MODELS
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
    List<TodayClass> classes,
    Map<String, String> attendance,
  ) =>
      AttendanceDayResult._(
        timetableMissing: false,
        noClasses: false,
        classes: classes,
        attendance: attendance,
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