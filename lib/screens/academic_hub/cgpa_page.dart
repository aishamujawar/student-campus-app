import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/cgpa_service.dart';

// ============ TOP-LEVEL CLASSES ============
class GradeOption {
  final String grade;
  final int points;
  final String label;

  const GradeOption(this.grade, this.points, this.label);
}

class SubjectData {
  final String name;
  final String grade;
  final int credits;

  SubjectData({
    required this.name,
    required this.grade,
    required this.credits,
  });
}

class SemesterCardData {
  final int semester;
  final Map<String, SubjectData> subjects;
  final double sgpa;

  SemesterCardData({
    required this.semester,
    required this.subjects,
    required this.sgpa,
  });

  factory SemesterCardData.fromMap(Map<String, dynamic> map) {
    final rawSubjects = map['subjects'] as Map<String, dynamic>;
    final subjects = Map<String, SubjectData>.fromEntries(
      rawSubjects.entries.map((entry) {
        final key = entry.key;
        final value = entry.value;
        
        // Handle both old and new formats
        if (value is String) {
          // Old format: just grade
          return MapEntry(key, SubjectData(
            name: key,
            grade: value,
            credits: 4, // Default credits for old data
          ));
        } else {
          // New format: Map with grade and credits
          final data = value as Map<String, dynamic>;
          return MapEntry(key, SubjectData(
            name: key,
            grade: data['grade'] as String? ?? 'F',
            credits: (data['credits'] as int?) ?? 4,
          ));
        }
      }),
    );
    
    return SemesterCardData(
      semester: map['semester'] as int,
      subjects: subjects,
      sgpa: (map['sgpa'] as num).toDouble(),
    );
  }
}

// ============ COLOR PALETTE ============
class ProfessionalPalette {
  // Original colors
  static const Color cgPrimary = Color(0xFF3AA8F7);
  static const Color cgTeal = Color(0xFF55D7C7);
  static const Color cgCyan = Color(0xFF4CBBD1);
  static const Color cgIndigo = Color(0xFF7B7CFF);
  static const Color cgLavender = Color(0xFFB0A8FF);
  static const Color cgBg = Color(0xFFF4F7FB);
  static const Color cgBgAlt = Color(0xFFE8F2FC);
  static const Color cgBorder = Color(0xFFE0E6F0);
  static const Color cgTextMuted = Color(0xFF7A8A9C);
  static const Color cgTextStrong = Color(0xFF16222C);
  
  // Performance colors (original)
  static const Color excellent = Colors.green;
  static const Color good = Colors.orange;
  static const Color risk = Colors.red;
  
  // Chart colors (as requested)
  static List<Color> get chartPalette => [
    const Color(0xFF2877E0), // strong blue
    const Color(0xFF4B6BFF), // deep indigo
    const Color(0xFF3AA8F7), // bright sky blue
    const Color(0xFF55D7C7), // teal green
    const Color(0xFF7B7CFF), // bluish violet
    const Color(0xFF61C2FF), // lighter blue
    const Color(0xFF6FE0F4), // lighter cyan
    const Color(0xFF7BE6D9), // light aqua
    const Color(0xFFB0A8FF), // soft lavender
    const Color(0xFFDDF9F3), // very light mint
  ];
}

// ============ MAIN WIDGET ============
class CgpaPage extends StatefulWidget {
  const CgpaPage({super.key});

  @override
  State<CgpaPage> createState() => _CgpaPageState();
}

class _CgpaPageState extends State<CgpaPage> {
  // ============ SERVICES & STATE ============
  final CgpaService _cgpaService = CgpaService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  int _maxSemesters = 6;
  int _selectedMode = 0;
  int? _activeSemesterNumber;
  
  // Persist semester choice - using shared preferences simulation
  late int _persistedSemesterChoice;
  
  // Draft state
  Map<String, Map<String, dynamic>> _draftSubjects = {};
  double? _draftSgpa;
  
  // Final archived data (loaded from Firestore)
  List<SemesterCardData> _archivedSemesters = [];
  
  // Loading states
  bool _isLoading = true;
  bool _isArchiving = false;
  String _archiveStatus = '';

  // Grade mapping for SGPA calculation
  static const Map<String, double> gradePointMap = {
    'OS': 10.0, 'AA': 10.0, 'AB': 9.0, 'BB': 8.0,
    'BC': 7.0, 'CC': 6.0, 'CD': 5.0, 'DD': 4.0,
    'EE': 2.0, 'F': 0.0, 'Ab': 0.0,
  };

  // Grade options for dropdown
  static const List<GradeOption> gradeOptions = [
    GradeOption('OS', 10, 'Outstanding'),
    GradeOption('AA', 10, 'Exceptional'),
    GradeOption('AB', 9, 'Excellent'),
    GradeOption('BB', 8, 'Very Good'),
    GradeOption('BC', 7, 'Good'),
    GradeOption('CC', 6, 'Fair'),
    GradeOption('CD', 5, 'Average'),
    GradeOption('DD', 4, 'Pass'),
    GradeOption('EE', 2, 'Marginal Fail'),
    GradeOption('F', 0, 'Fail'),
    GradeOption('Ab', 0, 'Absent'),
  ];

  // Credit options for dropdown (most common credit values)
  static const List<int> creditOptions = [1, 2, 3, 4, 5, 6];

  @override
  void initState() {
    super.initState();
    _loadSemesterChoice().then((value) {
      setState(() {
        _persistedSemesterChoice = value;
        _maxSemesters = value;
      });
      _initializeData();
    });
  }

  Future<void> _saveSemesterChoice(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('cgpa_semester_limit', value);
  }

  Future<int> _loadSemesterChoice() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('cgpa_semester_limit') ?? 6; // Default to 6
  }

  Future<void> _initializeData() async {
    setState(() => _isLoading = true);
    
    try {
      // Load persisted semester choice - in a real app, you'd use SharedPreferences
      // For now, we'll keep it in memory and it will persist during the session
      
      // Load archived semesters from Firestore
      final semestersData = await _cgpaService.loadArchivedSemesters();
      _archivedSemesters = semestersData
          .map((data) => SemesterCardData.fromMap(data))
          .toList();
      
      // Set active semester number
      if (_archivedSemesters.length < _maxSemesters) {
        _activeSemesterNumber = _archivedSemesters.length + 1;
      } else {
        _activeSemesterNumber = null;
      }
    } catch (e) {
      print('Error initializing data: $e');
      // Fallback to empty state
      _archivedSemesters = [];
      _activeSemesterNumber = 1;
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ============ HELPER FUNCTIONS ============
  int get _currentSemesterNumber => _archivedSemesters.length + 1;
  
  bool _isSemesterArchived(int semesterNumber) {
    return _archivedSemesters.any((s) => s.semester == semesterNumber);
  }
  
  SemesterCardData? _getArchivedSemester(int semesterNumber) {
    for (final sem in _archivedSemesters) {
      if (sem.semester == semesterNumber) {
        return sem;
      }
    }
    return null;
  }

  // Calculate SGPA using credits: (summation (credits × grade points)) / total credits
  double _calculateSgpa(Map<String, Map<String, dynamic>> subjects) {
    double totalGradePoints = 0;
    int totalCredits = 0;
    
    for (final subject in subjects.values) {
      final grade = subject['grade'] as String?;
      final credits = subject['credits'] as int?;
      
      if (grade != null && 
          credits != null && 
          gradePointMap.containsKey(grade)) {
        
        final gradePoints = gradePointMap[grade]!;
        totalGradePoints += gradePoints * credits;
        totalCredits += credits;
      }
    }
    
    return totalCredits > 0 ? totalGradePoints / totalCredits : 0.0;
  }

  // Performance color for scores (original colors)
  Color _performanceColor(double value) {
    if (value >= 8.5) return ProfessionalPalette.excellent;
    if (value >= 7.0) return ProfessionalPalette.good;
    return ProfessionalPalette.risk;
  }

  Color _momentumColor(double delta) {
    if (delta >= 0.3) return ProfessionalPalette.excellent;
    if (delta <= -0.3) return ProfessionalPalette.risk;
    return ProfessionalPalette.good;
  }

  String _momentumText(double delta) {
    if (delta >= 0.3) return 'Improving ↑';
    if (delta <= -0.3) return 'Declining ↓';
    return 'Stable →';
  }

  // Grade background color (original)
  Color _gradeBg(String grade) {
    switch (grade) {
      case 'OS':
      case 'AA':
        return ProfessionalPalette.cgPrimary.withOpacity(0.18);
      case 'AB':
        return ProfessionalPalette.cgPrimary.withOpacity(0.14);
      case 'BB':
        return ProfessionalPalette.cgPrimary.withOpacity(0.10);
      case 'BC':
        return ProfessionalPalette.cgPrimary.withOpacity(0.08);
      case 'CC':
      case 'CD':
        return ProfessionalPalette.cgPrimary.withOpacity(0.06);
      default:
        return ProfessionalPalette.cgBorder;
    }
  }

  // ============ GRADE DISTRIBUTION CHART ============
  Widget _buildGradeDistributionChart() {
    // Collect all grades from archived semesters
    final allGrades = <String>[];
    for (final sem in _archivedSemesters) {
      allGrades.addAll(sem.subjects.values.map((s) => s.grade));
    }
    
    if (allGrades.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: ProfessionalPalette.cgBg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            'No grade data available',
            style: TextStyle(
              color: ProfessionalPalette.cgTextMuted,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }
    
    // Count grade occurrences
    final gradeCount = <String, int>{};
    for (var grade in allGrades) {
      gradeCount[grade] = (gradeCount[grade] ?? 0) + 1;
    }
    
    // Sort grades by occurrence (descending)
    final sortedEntries = gradeCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    // Calculate total for percentages
    final total = allGrades.length;
    
    // Split sortedEntries into two columns for the legend
    final middleIndex = (sortedEntries.length / 2).ceil();
    final firstColumn = sortedEntries.sublist(0, middleIndex);
    final secondColumn = sortedEntries.sublist(middleIndex);
    
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ProfessionalPalette.cgBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Grade Distribution',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: ProfessionalPalette.cgTextStrong,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Across all semesters',
            style: TextStyle(
              fontSize: 11,
              color: ProfessionalPalette.cgTextMuted,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Pie Chart - left side
              Expanded(
                child: SizedBox(
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 50,
                      sections: sortedEntries.asMap().entries.map((entry) {
                        final index = entry.key;
                        final e = entry.value;
                        
                        return PieChartSectionData(
                          value: e.value.toDouble(),
                          title: e.key, // Only show grade letter, no percentage
                          radius: 65,
                          color: ProfessionalPalette.chartPalette[index % ProfessionalPalette.chartPalette.length],
                          titleStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              // Legend with percentages - now on the right in two columns
              Expanded(
                child: Container(
                  height: 200, // Match the pie chart height
                  child: SingleChildScrollView(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // First column
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: firstColumn.asMap().entries.map((entry) {
                              final index = entry.key;
                              final e = entry.value;
                              final percent = (e.value / total) * 100;
                              final originalIndex = sortedEntries.indexOf(e);
                              
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: ProfessionalPalette.chartPalette[originalIndex % ProfessionalPalette.chartPalette.length],
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            e.key,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(
                                            '${percent.toStringAsFixed(0)}% (${e.value})',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: ProfessionalPalette.cgTextMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        // Spacing between columns
                        const SizedBox(width: 16),
                        // Second column
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: secondColumn.asMap().entries.map((entry) {
                              final index = entry.key;
                              final e = entry.value;
                              final percent = (e.value / total) * 100;
                              final originalIndex = sortedEntries.indexOf(e);
                              
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: ProfessionalPalette.chartPalette[originalIndex % ProfessionalPalette.chartPalette.length],
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            e.key,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(
                                            '${percent.toStringAsFixed(0)}% (${e.value})',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: ProfessionalPalette.cgTextMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 25), 
        ],
      ),
    );
  }

  // ============ SGPA TREND LINE CHART ============
  Widget _buildSgpaTrendChart() {
    if (_archivedSemesters.length < 2) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: ProfessionalPalette.cgBg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            'Need at least 2 semesters for trend analysis',
            style: TextStyle(
              color: ProfessionalPalette.cgTextMuted,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }
    
    final sgpValues = _archivedSemesters.map((s) => s.sgpa).toList();
    final semNumbers = _archivedSemesters.map((s) => s.semester.toDouble()).toList();
    
    // Find min and max for scaling
    final minSgpa = sgpValues.reduce((a, b) => a < b ? a : b);
    final maxSgpa = sgpValues.reduce((a, b) => a > b ? a : b);
    
    // Calculate clean Y-axis range
    final yMin = (minSgpa.floor() - 1).clamp(0, 10);
    final yMax = (maxSgpa.ceil() + 1).clamp(0, 10);
    
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ProfessionalPalette.cgBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SGPA Trend Over Semesters',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: ProfessionalPalette.cgTextStrong,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Visual progression across completed semesters',
            style: TextStyle(
              fontSize: 11,
              color: ProfessionalPalette.cgTextMuted,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: ProfessionalPalette.cgBorder,
                      strokeWidth: 1,
                      dashArray: [5, 5],
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        // Fix: Only show titles for actual semester values
                        if (value.toInt() <= semNumbers.length && 
                            value.toInt() >= 1 &&
                            semNumbers.contains(value)) {
                          return Text(
                            'Sem ${value.toInt()}',
                            style: TextStyle(
                              fontSize: 10,
                              color: ProfessionalPalette.cgTextMuted,
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      reservedSize: 36,
                      getTitlesWidget: (value, meta) {
                        if (value % 1 != 0) return const SizedBox();
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w300,
                            color: ProfessionalPalette.cgTextMuted,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(
                    color: ProfessionalPalette.cgBorder,
                    width: 1,
                  ),
                ),
                minX: semNumbers.first - 0.5,
                maxX: semNumbers.last + 0.5,
                minY: yMin.toDouble(),
                maxY: yMax.toDouble(),
                lineBarsData: [
                  LineChartBarData(
                    spots: semNumbers.asMap().entries.map((entry) {
                      final index = entry.key;
                      final sem = entry.value;
                      return FlSpot(sem, sgpValues[index]);
                    }).toList(),
                    isCurved: true,
                    color: ProfessionalPalette.cgPrimary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                        radius: 4,
                        color: ProfessionalPalette.cgPrimary,
                        strokeWidth: 1,
                        strokeColor: Colors.white,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: ProfessionalPalette.cgPrimary.withOpacity(0.1),
                    ),
                  ),
                ],
                // 👇 ADDED lineTouchData for formatted tooltips
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (LineBarSpot touchedSpot) {
                      return ProfessionalPalette.cgPrimary.withOpacity(0.9);
                    },
                    getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                      return touchedBarSpots.map((barSpot) {
                        return LineTooltipItem(
                          '${barSpot.y.toStringAsFixed(2)}',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============ MAIN BUILD ============
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingScreen();
    }

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFE7F2FF), Color(0xFFD8F7F8)],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: FractionallySizedBox(
                    widthFactor: 0.85,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 430),
                      child: _card(),
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Loading Overlay
          if (_isArchiving)
            Container(
              color: Colors.black.withOpacity(0.15),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(32, 28, 32, 28),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.98),
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 26,
                        offset: const Offset(0, 18),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                        color: ProfessionalPalette.cgPrimary,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _archiveStatus,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: ProfessionalPalette.cgTextStrong,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingScreen() => Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFE7F2FF), Color(0xFFD8F7F8)],
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(
              color: ProfessionalPalette.cgPrimary,
            ),
          ),
        ),
      );

  Widget _card() => Container(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.98),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 26,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(),
            const SizedBox(height: 16),
            _modeToggle(),
            const SizedBox(height: 16),
            _semesterLimitSelector(),
            const SizedBox(height: 20),
            if (_selectedMode == 0) _semestersMode() else _analysisMode(),
          ],
        ),
      );

  Widget _header() => Row(
        children: [
          Container(
            height: 32,
            width: 32,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: const LinearGradient(
                colors: [ProfessionalPalette.cgCyan, ProfessionalPalette.cgTeal],
              ),
            ),
            child: const Icon(Icons.school_rounded,
                size: 18, color: Colors.white),
          ),
          const SizedBox(width: 8),
          const Text(
            'CGPA Tracker',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      );

  Widget _modeToggle() => Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: ProfessionalPalette.cgBg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedMode = 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: _selectedMode == 0
                        ? Colors.white
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: _selectedMode == 0
                        ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 6,
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      'Semesters',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _selectedMode == 0
                            ? ProfessionalPalette.cgPrimary
                            : ProfessionalPalette.cgTextMuted,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedMode = 1),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: _selectedMode == 1
                        ? Colors.white
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: _selectedMode == 1
                        ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 6,
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      'Analysis',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _selectedMode == 1
                            ? ProfessionalPalette.cgPrimary
                            : ProfessionalPalette.cgTextMuted,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _semesterLimitSelector() => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: ProfessionalPalette.cgBg,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Total semesters',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () async {
                      setState(() {
                        _maxSemesters = 6;
                        _persistedSemesterChoice = 6;
                      });
                      await _saveSemesterChoice(6); // ✅ SAVES PERSISTENTLY
                      
                      if (_activeSemesterNumber != null && 
                          _activeSemesterNumber! > _maxSemesters) {
                        setState(() {
                          _activeSemesterNumber = 
                              _currentSemesterNumber <= _maxSemesters 
                                  ? _currentSemesterNumber 
                                  : null;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: _maxSemesters == 6
                            ? ProfessionalPalette.cgPrimary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '6',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _maxSemesters == 6
                              ? Colors.white
                              : ProfessionalPalette.cgTextMuted,
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      setState(() {
                        _maxSemesters = 8;
                        _persistedSemesterChoice = 8;
                      });
                      await _saveSemesterChoice(8); // ✅ SAVES PERSISTENTLY
                      
                      if (_activeSemesterNumber == null && 
                          _currentSemesterNumber <= _maxSemesters) {
                        setState(() {
                          _activeSemesterNumber = _currentSemesterNumber;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: _maxSemesters == 8
                            ? ProfessionalPalette.cgPrimary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '8',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _maxSemesters == 8
                              ? Colors.white
                              : ProfessionalPalette.cgTextMuted,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );    

  // ============ SEMESTERS MODE ============
  Widget _semestersMode() {
    final hasActiveSemester = _activeSemesterNumber != null;
    
    return Column(
      children: [
        if (!hasActiveSemester) _allCompleteMessage(),
        _semesterGrid(),
        const SizedBox(height: 20),
        if (hasActiveSemester) _finishSemesterButton(),
      ],
    );
  }

  Widget _allCompleteMessage() => Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: ProfessionalPalette.cgTeal.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ProfessionalPalette.cgTeal.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: ProfessionalPalette.cgTeal, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'All semesters completed!',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: ProfessionalPalette.cgTextStrong,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _semesterGrid() => GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _maxSemesters,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.78,
        ),
        itemBuilder: (context, index) {
          final semesterNumber = index + 1;
          
          if (_isSemesterArchived(semesterNumber)) {
            final archivedData = _getArchivedSemester(semesterNumber);
            if (archivedData != null) {
              return _archivedSemesterCard(archivedData);
            } else {
              return _lockedSemesterCard(semesterNumber);
            }
          } else if (semesterNumber == _activeSemesterNumber) {
            return _activeSemesterCard(semesterNumber);
          } else {
            return _lockedSemesterCard(semesterNumber);
          }
        },
      );

  Widget _archivedSemesterCard(SemesterCardData data) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ProfessionalPalette.cgBg,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 14,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: ProfessionalPalette.cgPrimary.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${data.semester}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Semester',
                  style: TextStyle(
                    fontSize: 12,
                    color: ProfessionalPalette.cgTextMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _performanceColor(data.sgpa).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: _performanceColor(data.sgpa).withOpacity(0.4)),
                  ),
                  child: Text(
                    data.sgpa.toStringAsFixed(2),
                    style: TextStyle(
                      color: _performanceColor(data.sgpa),
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // 🔥 FIX: Use Expanded with SingleChildScrollView
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: data.subjects.entries.toList().asMap().entries.map(
                    (entry) {
                      final index = entry.key + 1;
                      final subjectName = entry.value.key;
                      final subjectData = entry.value.value;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Text(
                              '$index.',
                              style: const TextStyle(
                                fontSize: 12,
                                color: ProfessionalPalette.cgTextMuted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    subjectName,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${subjectData.credits} credits',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: ProfessionalPalette.cgTextMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: _gradeBg(subjectData.grade),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                subjectData.grade,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF3AA8F7),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ).toList(),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _activeSemesterCard(int semesterNumber) => GestureDetector(
        onTap: _startFinishFlow,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: ProfessionalPalette.cgPrimary,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: ProfessionalPalette.cgPrimary.withOpacity(0.15),
                blurRadius: 14,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: ProfessionalPalette.cgPrimary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Semester $semesterNumber',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: ProfessionalPalette.cgPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Tap to finish',
                style: TextStyle(
                  fontSize: 11,
                  color: ProfessionalPalette.cgTextMuted,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _lockedSemesterCard(int semesterNumber) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: ProfessionalPalette.cgBorder,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey.shade200,
                ),
                child: Icon(
                  Icons.lock_rounded,
                  color: Colors.grey.shade500,
                  size: 18,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sem $semesterNumber',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Locked',
                style: TextStyle(
                  fontSize: 10,
                  color: Color(0xFF9AA6B5),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _finishSemesterButton() => SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _startFinishFlow,
          style: ElevatedButton.styleFrom(
            backgroundColor: ProfessionalPalette.cgPrimary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            elevation: 0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.done_all_rounded, size: 20),
              const SizedBox(width: 8),
              Text(
                'Finish Semester $_activeSemesterNumber',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      );

  // ============ ARCHIVE FLOW ============
  void _startFinishFlow() {
    if (_activeSemesterNumber == null || _isArchiving) {
      return;
    }
    
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Finish Semester?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'You are about to finish this semester.',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 12),
            Text('Next step:'),
            SizedBox(height: 4),
            Text('• You will enter grades and credits for all subjects'),
            SizedBox(height: 4),
            Text('• SGPA will be calculated and saved'),
            SizedBox(height: 12),
            Text(
              'Final confirmation will permanently archive this semester.',
              style: TextStyle(
                color: ProfessionalPalette.cgTextMuted,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _openGradeEntry();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ProfessionalPalette.cgPrimary,
            ),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _openGradeEntry() async {
    try {
      _draftSubjects = {};
      _draftSgpa = 0.0;
      
      final subjectsFromTimetable = await _cgpaService.fetchSubjectsFromTimetable();
      
      if (subjectsFromTimetable.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No subjects found in timetable. You can still archive the semester.'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        for (var subject in subjectsFromTimetable) {
          _draftSubjects[subject] = {
            'grade': null,
            'credits': null, 
          };
        }
      }
      
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        builder: (_) => StatefulBuilder(
          builder: (context, setLocalState) {
            
            final bool allGradesSelected = _draftSubjects.isEmpty 
                ? true
                : _draftSubjects.values.every((subject) => subject['grade'] != null);
            
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 20,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: SizedBox(
                        width: 40,
                        height: 4,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Color(0xFFE0E0E0),
                            borderRadius: BorderRadius.all(Radius.circular(2)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Enter Semester Grades',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _draftSubjects.isEmpty 
                        ? 'No subjects found in timetable'
                        : 'Select grades and credits for each subject',
                      style: const TextStyle(
                        color: ProfessionalPalette.cgTextMuted,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // 👇 THIS IS THE KEY CHANGE - Wrap with Expanded for scrolling
                    Expanded(
                      child: ListView(
                        shrinkWrap: true,
                        physics: const ClampingScrollPhysics(),
                        children: [
                          if (_draftSubjects.isNotEmpty) ...[
                            ..._draftSubjects.keys.map(
                              (subject) => _gradeRow(subject, setLocalState),
                            ),
                            const SizedBox(height: 16),
                          ],
                          _sgpaDisplay(setLocalState),
                          const SizedBox(height: 20), // Extra space before button
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: allGradesSelected
                            ? () {
                                Navigator.pop(context);
                                _confirmArchive();
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ProfessionalPalette.cgPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: const Text(
                          'Continue',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    } catch (e) {
      print('Error opening grade entry: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: ProfessionalPalette.risk,
        ),
      );
    }
  }

  Widget _gradeRow(String subject, StateSetter setLocalState) {
    final subjectData = _draftSubjects[subject]!;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ProfessionalPalette.cgBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              subject,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          // Grade and Credit dropdowns next to each other (like in original)
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: ProfessionalPalette.cgBorder),
                ),
                child: DropdownButton<String>(
                  value: subjectData['grade'] as String?,
                  hint: const Text(
                    'Grade',
                    style: TextStyle(fontSize: 12),
                  ),
                  underline: const SizedBox(),
                  items: gradeOptions.map((GradeOption g) {
                    return DropdownMenuItem<String>(
                      value: g.grade,
                      child: Text(
                        g.grade,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setLocalState(() {
                      _draftSubjects[subject] = {
                        'grade': value,
                        'credits': subjectData['credits'], // Keep existing credits value
                      };
                      _draftSgpa = _calculateSgpa(_draftSubjects);
                    });
                  },
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: ProfessionalPalette.cgBorder),
                ),
                child: DropdownButton<int>(
                  value: subjectData['credits'] as int?,
                  hint: const Text(
                    'Credits',
                    style: TextStyle(fontSize: 12),
                  ),
                  underline: const SizedBox(),
                  items: creditOptions.map((int credit) {
                    return DropdownMenuItem<int>(
                      value: credit,
                      child: Text(
                        '$credit',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setLocalState(() {
                      _draftSubjects[subject] = {
                        'grade': subjectData['grade'],
                        'credits': value,
                      };
                      _draftSgpa = _calculateSgpa(_draftSubjects);
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sgpaDisplay(StateSetter setLocalState) => GestureDetector(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'SGPA is calculated using: (summation of credits × grade points) / total credits',
              ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: ProfessionalPalette.cgBg,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'SGPA (auto calculated)',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: ProfessionalPalette.cgTextMuted,
                    ),
                  ),
                  Text(
                    _draftSgpa?.toStringAsFixed(2) ?? '0.00',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: _performanceColor(_draftSgpa ?? 0.0),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Formula: Σ(Credits × Grade Points) ÷ Total Credits',
                style: TextStyle(
                  fontSize: 11,
                  color: ProfessionalPalette.cgTextMuted,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      );

  void _confirmArchive() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Confirm Archive'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('This action will:'),
            SizedBox(height: 8),
            Text('• Archive this semester permanently'),
            Text('• Reset timetable data'),
            Text('• Clear assignments & calendar'),
            Text('• Delete all attendance records'),
            SizedBox(height: 14),
            Text(
              'This cannot be undone.',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: ProfessionalPalette.cgTextMuted,
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _archiveSemester();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ProfessionalPalette.cgPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(14)),
                ),
              ),
              child: _isArchiving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Confirm & Archive',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _archiveSemester() async {
    if (_activeSemesterNumber == null) {
      return;
    }

    setState(() {
      _isArchiving = true;
      _archiveStatus = 'Archiving semester…';
    });

    try {
      // Convert draft subjects to the new format with grade and credits
      final subjects = _draftSubjects.isEmpty
          ? <String, Map<String, dynamic>>{}
          : Map<String, Map<String, dynamic>>.from(
              _draftSubjects.map((k, v) => MapEntry(
                k,
                {
                  'grade': v['grade'] ?? 'F',
                  'credits': v['credits'] ?? 4,
                },
              )),
            );

      // Calculate final SGPA using credits
      final finalSgpa = _calculateSgpa(_draftSubjects);

      // Store the semester number that's being archived
      final archivedSemesterNumber = _activeSemesterNumber!;

      // 1. Archive to Firestore
      await _cgpaService.archiveSemester(
        semester: archivedSemesterNumber,
        subjects: subjects,
        sgpa: finalSgpa,
      );

      // 2. Clear ALL post-semester data
      await _clearDataStepByStep();

      // Refresh everything from Firestore
      await _initializeData();

      // Clear draft data
      _draftSubjects.clear();
      _draftSgpa = null;

      // Show success with correct semester number
      Navigator.pop(context);
      _showSuccessToast(archivedSemesterNumber);
    } catch (e) {
      print('Error archiving semester: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Archive failed: ${e.toString()}'),
          backgroundColor: ProfessionalPalette.risk,
        ),
      );
    } finally {
      setState(() {
        _isArchiving = false;
        _archiveStatus = '';
      });
    }
  }

  Future<void> _clearDataStepByStep() async {
    try {
      setState(() => _archiveStatus = 'Deleting timetable');
      await _cgpaService.deleteTimetable();

      setState(() => _archiveStatus = 'Deleting assignments');
      await _cgpaService.deleteAssignments();

      setState(() => _archiveStatus = 'Deleting attendance');
      await _cgpaService.deleteAttendance();

      setState(() => _archiveStatus = 'Deleting calendar');
      await Future.delayed(const Duration(milliseconds: 300));
      await _cgpaService.deleteCalendar();

      setState(() => _archiveStatus = 'Finalizing semester');
      await _cgpaService.finalizeSemester();

      print('✅ All post-semester data cleared successfully');
    } catch (e) {
      print('Error clearing post-semester data: $e');
      rethrow;
    }
  }

  void _showSuccessToast(int archivedSemesterNumber) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Semester $archivedSemesterNumber archived successfully! All data cleared for new semester.'),
        backgroundColor: ProfessionalPalette.cgPrimary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  // ============ ORIGINAL ANALYSIS MODE ============
  Widget _analysisMode() {
    if (_archivedSemesters.isEmpty) {
      return _noDataAnalysis();
    }
    
    final insights = _calculateInsights();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _performanceSummary(insights),
        const SizedBox(height: 20),
        _insightCards(insights),
        const SizedBox(height: 20),
        _buildGradeDistributionChart(),
        const SizedBox(height: 20),
        _buildSgpaTrendChart(),
        const SizedBox(height: 20),
        _semesterTrend(),
      ],
    );
  }

  Widget _noDataAnalysis() => Center(
        child: Column(
          children: [
            const SizedBox(height: 40),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: ProfessionalPalette.cgBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.bar_chart_rounded,
                color: ProfessionalPalette.cgTextMuted,
                size: 32,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No semester data yet',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: ProfessionalPalette.cgTextStrong,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Finish a semester to see analysis',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ProfessionalPalette.cgTextMuted,
              ),
            ),
          ],
        ),
      );

  Map<String, dynamic> _calculateInsights() {
    final Map<String, dynamic> insights = {};
    
    if (_archivedSemesters.isEmpty) return insights;
    
    // 1. Consistency analysis
    final sgpValues = _archivedSemesters.map((s) => s.sgpa).toList();
    final mean = sgpValues.reduce((a, b) => a + b) / sgpValues.length;
    final variance = sgpValues.map((x) => (x - mean) * (x - mean)).reduce((a, b) => a + b) / sgpValues.length;
    
    insights['consistency'] = variance < 0.5 
      ? {'level': 'high', 'text': 'Consistent performer'}
      : {'level': 'low', 'text': 'Fluctuating performance'};
    
    // 2. Strongest subjects
    final gradeMap = <String, List<String>>{};
    for (final sem in _archivedSemesters) {
      for (final entry in sem.subjects.entries) {
        gradeMap.putIfAbsent(entry.key, () => []).add(entry.value.grade);
      }
    }
    
    final strongSubjects = gradeMap.entries
      .where((e) => e.value.every((g) => ['OS', 'AA', 'AB'].contains(g)))
      .map((e) => e.key)
      .toList();
    
    insights['strengths'] = strongSubjects;
    
    // 3. Momentum (comparing current vs previous)
    if (_archivedSemesters.length >= 2) {
      final currentSemester = _archivedSemesters.last; // The most recently completed semester
      final previousSemester = _archivedSemesters[_archivedSemesters.length - 2];
      
      final momentum = currentSemester.sgpa - previousSemester.sgpa;
      
      insights['momentum'] = {
        'value': momentum,
        'text': momentum >= 0.5 
          ? 'Strong upward trend'
          : momentum <= -0.5
            ? 'Performance dipped'
            : 'Stable performance',
        'previous': previousSemester.sgpa,
        'current': currentSemester.sgpa,
        'change': momentum
      };
      
      // 4. Predicted next semester
      if (_archivedSemesters.length >= 3) {
        final lastThree = sgpValues.sublist(sgpValues.length - 3);
        final avgLastThree = lastThree.reduce((a, b) => a + b) / lastThree.length;
        final predicted = avgLastThree + (momentum * 0.5); // Weighted prediction
        
        insights['predicted'] = {
          'value': predicted.clamp(0, 10),
          'confidence': (100 - (variance * 20)).clamp(60, 95).toInt()
        };
      }
    }
    
    return insights;
  }

  Widget _performanceSummary(Map<String, dynamic> insights) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: ProfessionalPalette.cgBg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Performance Summary',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: ProfessionalPalette.cgTextStrong,
            ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _metricTile(
                  'Current CGPA',
                  _calculateCurrentCgpa().toStringAsFixed(2),
                  _performanceColor(_calculateCurrentCgpa()),
                ),
                _metricTile(
                  'Semesters',
                  '${_archivedSemesters.length}/$_maxSemesters',
                  ProfessionalPalette.cgPrimary,
                ),
                _metricTile(
                  'Best SGPA',
                  _archivedSemesters.map((s) => s.sgpa).reduce((a, b) => a > b ? a : b).toStringAsFixed(2),
                  ProfessionalPalette.excellent,
                ),
              ],
            ),
            if (_archivedSemesters.length >= 2) ...[
              const SizedBox(height: 16),
              _momentumIndicator(insights),
            ],
          ],
        ),
      );

  double _calculateCurrentCgpa() {
    if (_archivedSemesters.isEmpty) return 0.0;
    
    // Calculate CGPA as weighted average of SGPAs
    // (In a real implementation, you might want to weight by credits per semester)
    final totalSgpa = _archivedSemesters.fold<double>(
        0.0, (sum, semester) => sum + semester.sgpa);
    return totalSgpa / _archivedSemesters.length;
  }

  Widget _momentumIndicator(Map<String, dynamic> insights) {
    if (_archivedSemesters.length < 2) return const SizedBox();
    
    final momentumData = insights['momentum'];
    final delta = momentumData?['change'] ?? 0.0;
    final previous = momentumData?['previous'] ?? 0.0;
    final current = momentumData?['current'] ?? 0.0;
    
    final color = _momentumColor(delta);
    final text = _momentumText(delta);
    
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                delta >= 0.3 ? Icons.trending_up_rounded : 
                delta <= -0.3 ? Icons.trending_down_rounded : 
                Icons.trending_flat_rounded,
                color: color,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                text,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Previous SGPA: ${previous.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 11,
                color: ProfessionalPalette.cgTextMuted,
              ),
            ),
            Text(
              'Current SGPA: ${current.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _performanceColor(current),
              ),
            ),
            if (insights['predicted'] != null)
              Text(
                'Predicted: ${insights['predicted']['value'].toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 11,
                  color: ProfessionalPalette.cgTextMuted,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Change: ${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _metricTile(String title, String value, Color color) => Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.2)),
            ),
            child: Center(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color == ProfessionalPalette.cgPrimary ? ProfessionalPalette.cgPrimary : ProfessionalPalette.cgTextMuted,
              fontWeight: color == ProfessionalPalette.cgPrimary ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      );

  Widget _insightCards(Map<String, dynamic> insights) => Column(
        children: [
          _insightCard(
            'Consistency',
            insights['consistency']?['text'] ?? 'Not enough data',
            ProfessionalPalette.cgPrimary,
            Icons.timeline_rounded,
          ),
          const SizedBox(height: 12),
          _insightCard(
            'Strong Areas',
            insights['strengths']?.isNotEmpty == true 
              ? (insights['strengths'] as List).join(', ')
              : 'All subjects balanced',
            ProfessionalPalette.cgPrimary,
            Icons.star_rounded,
          ),
          if (insights['momentum'] != null) ...[
            const SizedBox(height: 12),
            _insightCard(
              'Momentum',
              insights['momentum']['text'],
              ProfessionalPalette.cgPrimary,
              Icons.trending_up_rounded,
            ),
          ],
        ],
      );

  Widget _insightCard(String title, String content, Color iconColor, IconData icon) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ProfessionalPalette.cgBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: ProfessionalPalette.cgBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: ProfessionalPalette.cgTextMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    content,
                    style: const TextStyle(
                      fontSize: 14,
                      color: ProfessionalPalette.cgTextStrong,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _semesterTrend() => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: ProfessionalPalette.cgBg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Semester Trend',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: ProfessionalPalette.cgTextStrong,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Visual progression over time',
              style: TextStyle(
                fontSize: 11,
                color: ProfessionalPalette.cgTextMuted,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 16),
            ..._buildTrendVisualization(),
          ],
        ),
      );

  List<Widget> _buildTrendVisualization() {
    return _archivedSemesters.map((sem) {
      final widthFactor = (sem.sgpa / 10.0).clamp(0.0, 1.0);
      final barColor = _performanceColor(sem.sgpa);
      final sgpaColor = _performanceColor(sem.sgpa);
      
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: ProfessionalPalette.cgPrimary.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${sem.semester}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Semester ${sem.semester}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: ProfessionalPalette.cgTextStrong,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${sem.subjects.length} subjects',
                        style: const TextStyle(
                          fontSize: 11,
                          color: ProfessionalPalette.cgTextMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: sgpaColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    sem.sgpa.toStringAsFixed(2),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: sgpaColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, constraints) {
                return Container(
                  height: 10,
                  width: constraints.maxWidth,
                  decoration: BoxDecoration(
                    color: ProfessionalPalette.cgBgAlt,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      height: 10,
                      width: constraints.maxWidth * widthFactor,
                      decoration: BoxDecoration(
                        color: barColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      );
    }).toList();
  }
}