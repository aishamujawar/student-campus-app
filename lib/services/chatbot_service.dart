import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'package:student_campus_app/screens/budgeting/personal_expenses/controllers/personal_expense_controller.dart';
import 'calendar_service.dart';
import 'assignment_service.dart';
import 'timetable_service.dart';
import 'cgpa_service.dart';
import 'attendance_service.dart';
import 'user_service.dart';

class ChatbotService {
  final CalendarService _calendar = CalendarService();
  final AssignmentService _assignment = AssignmentService();
  final TimetableService _timetable = TimetableService();
  final CgpaService _cgpa = CgpaService();
  final AttendanceService _attendance = AttendanceService();
  
  // Get expense controller reference
  PersonalExpenseController get _expenseController => 
      Get.find<PersonalExpenseController>();

  Future<String> askBot(String message) async {
    // Get user's first name
    final firstName = await UserService.getCurrentUserFirstName();
    
    // Collect real data from app
    final assignments = await _assignment.getAssignmentCountByDate();
    
    // Weekly timetable (7 days) with correct field mapping
    final Map<String, List<dynamic>> weeklyTimetable = {};
    
    for (int i = 0; i < 7; i++) {
      // Get classes with already-merged time data from TimetableService
      final classes = await _timetable.getClassesForWeekday(i);
      
      // Map fields to match backend expectations
      final normalizedClasses = classes.map<Map<String, dynamic>>((c) {
        return {
          'subjectName': c['subject'],
          'name': c['subject'],
          'subject': c['subject'],
          'startTime': c['start'],
          'endTime': c['end'],
        };
      }).toList();
      
      weeklyTimetable['day_$i'] = normalizedClasses;
    }
    
    final semesters = await _cgpa.loadArchivedSemesters();
    final coloredDays = await _calendar.loadColoredDays();
    final attendanceSummary = await _attendance.getAttendanceSummary();
    
    // Add expense summary
    final expenseSummary = _expenseController.getExpenseSummaryForChatbot();

    // Today's index for quick reference
    final todayIndex = DateTime.now().weekday - 1; // Monday=0, Sunday=6
    
    // Send structured calendar marks with category names
    final context = {
      "message": message,
      "user": {
        "firstName": firstName,
      },
      "assignments": assignments,
      "timetable": weeklyTimetable,
      "todayIndex": todayIndex,
      "cgpa": semesters,
      "calendarMarks": coloredDays.entries.map((e) => {
        "date": e.key,
        "categoryName": e.value.categoryName,
      }).toList(),
      "attendance": attendanceSummary,
      "expenses": expenseSummary,
    };

    try {
      final response = await http.post(
        Uri.parse("http://localhost:3000/chat"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(context),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["reply"];
      } else {
        return "Unable to connect to assistant (Status: ${response.statusCode})";
      }
    } catch (e) {
      return "Unable to reach the assistant server. Please check if backend is running on http://localhost:3000";
    }
  }
}