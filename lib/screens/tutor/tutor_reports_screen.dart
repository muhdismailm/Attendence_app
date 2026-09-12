import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/attendance_model.dart';
import '../../models/student_model.dart';
import '../../state/attendance_provider.dart';
import '../../state/student_provider.dart';
import '../../services/excel_report_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_styles.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/stats_summary_card.dart';

class TutorReportsScreen extends StatefulWidget {
  const TutorReportsScreen({super.key});

  @override
  State<TutorReportsScreen> createState() => _TutorReportsScreenState();
}

class _TutorReportsScreenState extends State<TutorReportsScreen> with SingleTickerProviderStateMixin {
  DateTime _selectedMonth = DateTime.now();
  String _selectedTeam = 'all'; // 'all', 'team1', 'team2'
  bool _isExporting = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _changeMonth(int offset) {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + offset,
        1,
      );
    });
  }

  Future<void> _exportExcel(List<Student> students, Map<String, AttendanceRecord> attendanceMap) async {
    setState(() => _isExporting = true);
    try {
      final teamLabel = _selectedTeam == 'all'
          ? 'All Teams'
          : (_selectedTeam == 'team1' ? 'Team 1' : 'Team 2');

      final file = await ExcelReportService.generateMonthlyAttendanceExcel(
        students: students,
        attendanceMap: attendanceMap,
        year: _selectedMonth.year,
        month: _selectedMonth.month,
        teamName: teamLabel,
      );

      if (!mounted) return;
      setState(() => _isExporting = false);

      _showExportSuccessModal(file);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isExporting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to generate Excel report: $e'),
          backgroundColor: AppColors.absentRed,
        ),
      );
    }
  }

  void _showExportSuccessModal(File file) {
    final fileName = file.path.split(Platform.pathSeparator).last;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 18),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFF107C41).withValues(alpha: 0.12), // Excel green
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.table_chart_rounded, color: Color(0xFF107C41), size: 30),
              ),
              const SizedBox(height: 14),
              const Text(
                'Excel Report Ready!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark),
              ),
              const SizedBox(height: 6),
              Text(
                fileName,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: const BorderSide(color: AppColors.primaryBlue),
                      ),
                      icon: const Icon(Icons.folder_open_rounded, color: AppColors.primaryBlue),
                      label: const Text('Open File', style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.w700)),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        final success = await ExcelReportService.openExcelFile(file);
                        if (!success && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Could not open file automatically. Saved in app folder.')),
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF107C41),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.share_rounded, size: 20),
                      label: const Text('Share / Send', style: TextStyle(fontWeight: FontWeight.w700)),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await ExcelReportService.shareExcelFile(file, subject: 'Monthly Attendance Report');
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final studentProv = context.watch<StudentProvider>();
    final attProv = context.watch<AttendanceProvider>();

    final monthTitle = DateFormat('MMMM yyyy').format(_selectedMonth);
    final daysInMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;

    // Filter students by selected team
    List<Student> students;
    if (_selectedTeam == 'all') {
      students = studentProv.allStudents;
    } else {
      students = studentProv.getStudentsForTeam(_selectedTeam);
    }

    final attendanceMap = attProv.allAttendanceMap;

    // Aggregate monthly numbers
    int overallPresents = 0;
    int overallAbsents = 0;

    for (var s in students) {
      for (var session in ['morning', 'evening']) {
        for (int d = 1; d <= daysInMonth; d++) {
          final dateStr = DateFormat('yyyy-MM-dd').format(DateTime(_selectedMonth.year, _selectedMonth.month, d));
          final key = AttendanceRecord.generateId(s.id, dateStr, session);
          final rec = attendanceMap[key];
          if (rec != null) {
            if (rec.isPresent) overallPresents++;
            if (rec.isAbsent) overallAbsents++;
          }
        }
      }
    }

    final totalMarked = overallPresents + overallAbsents;
    final double overallPercentage = totalMarked > 0 ? (overallPresents / totalMarked * 100) : 0.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Monthly Reports', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.headerGradientStart,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_isExporting)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
            )
          else
            TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: const Color(0xFF107C41), // Excel green
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.file_download_outlined, size: 18),
              label: const Text('Excel', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              onPressed: () => _exportExcel(students, attendanceMap),
            ),
          const SizedBox(width: 12),
        ],
      ),
      body: Column(
        children: [
          // Header Filter Bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            decoration: AppStyles.headerGradientDecoration,
            child: Column(
              children: [
                // Month Selector
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 28),
                      onPressed: () => _changeMonth(-1),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.calendar_month_rounded, color: Colors.white70, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          monthTitle,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 28),
                      onPressed: () => _changeMonth(1),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Team Filter Chips
                Row(
                  children: [
                    _buildTeamChip('All Teams', 'all'),
                    const SizedBox(width: 8),
                    _buildTeamChip('Team 1', 'team1'),
                    const SizedBox(width: 8),
                    _buildTeamChip('Team 2', 'team2'),
                  ],
                ),
                const SizedBox(height: 12),

                // Tab Switcher (Matrix Table vs Summary Cards)
                Container(
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: AppColors.primaryBlue,
                    unselectedLabelColor: Colors.white,
                    labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    tabs: const [
                      Tab(text: 'Matrix Sheet (1-30)'),
                      Tab(text: 'Overview & Students'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Body Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // TAB 1: Handwritten Table Format Matrix Sheet
                _buildMatrixSheetView(students, attendanceMap, daysInMonth, monthTitle),

                // TAB 2: Overview & Summary Cards
                _buildOverviewTab(students, attendanceMap, monthTitle, overallPercentage, overallPresents, overallAbsents, totalMarked),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamChip(String label, String value) {
    final isSelected = _selectedTeam == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedTeam = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppColors.primaryBlue : Colors.white,
          ),
        ),
      ),
    );
  }

  /// Interactive In-App Matrix Table matching handwritten format
  Widget _buildMatrixSheetView(
    List<Student> students,
    Map<String, AttendanceRecord> attendanceMap,
    int daysInMonth,
    String monthTitle,
  ) {
    if (students.isEmpty) {
      return const EmptyStateView(
        icon: Icons.table_chart_outlined,
        title: 'No Students',
        message: 'No student enrolled in this team selection.',
      );
    }

    final teamLabel = _selectedTeam == 'all'
        ? 'All Teams'
        : (_selectedTeam == 'team1' ? 'Team 1' : 'Team 2');

    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sheet Title Banner
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$monthTitle — $teamLabel',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textDark),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Morning & Evening sessions for Days 1 to 30/31',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF107C41),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.download_rounded, size: 16),
                  label: const Text('Export .xlsx', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  onPressed: () => _exportExcel(students, attendanceMap),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.borderLight),

          // Scrollable Grid Table
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(const Color(0xFF1E3A8A)),
                  headingTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                  dataRowMinHeight: 36,
                  dataRowMaxHeight: 40,
                  horizontalMargin: 12,
                  columnSpacing: 10,
                  border: TableBorder.all(
                    color: const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                  columns: [
                    const DataColumn(label: Text('Roll No')),
                    const DataColumn(label: Text('Student Name')),
                    const DataColumn(label: Text('Timing')),
                    for (int d = 1; d <= daysInMonth; d++)
                      DataColumn(
                        label: Center(
                          child: Text(
                            d.toString(),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    const DataColumn(label: Text('Total P')),
                    const DataColumn(label: Text('Total A')),
                    const DataColumn(label: Text('Att %')),
                  ],
                  rows: _buildTableRows(students, attendanceMap, daysInMonth),
                ),
              ),
            ),
          ),

          // Legend Bar at bottom
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              border: Border(top: BorderSide(color: AppColors.borderLight)),
            ),
            child: Row(
              children: [
                _buildLegendItem(Icons.check_circle_rounded, '✔ Present (P)', AppColors.presentGreen),
                const SizedBox(width: 16),
                _buildLegendItem(Icons.cancel_rounded, '✘ Absent (A)', AppColors.absentRed),
                const SizedBox(width: 16),
                _buildLegendItem(Icons.remove_rounded, '- Not Marked', AppColors.textMuted),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
        ),
      ],
    );
  }

  List<DataRow> _buildTableRows(
    List<Student> students,
    Map<String, AttendanceRecord> attendanceMap,
    int daysInMonth,
  ) {
    final List<DataRow> rows = [];

    for (int sIdx = 0; sIdx < students.length; sIdx++) {
      final student = students[sIdx];
      final isEvenStudent = sIdx % 2 == 0;
      final studentBg = isEvenStudent ? Colors.white : const Color(0xFFF8FAFC);

      for (final session in ['Morning', 'Evening']) {
        final isMorning = session == 'Morning';
        final sessionLower = session.toLowerCase();
        int presentCount = 0;
        int absentCount = 0;

        final dayCells = <DataCell>[];

        for (int d = 1; d <= daysInMonth; d++) {
          final dateStr = DateFormat('yyyy-MM-dd').format(DateTime(_selectedMonth.year, _selectedMonth.month, d));
          final key = AttendanceRecord.generateId(student.id, dateStr, sessionLower);
          final rec = attendanceMap[key];

          if (rec != null) {
            if (rec.isPresent) {
              presentCount++;
              dayCells.add(
                DataCell(
                  Center(
                    child: Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.presentLightBg,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('✔', style: TextStyle(color: AppColors.presentGreen, fontWeight: FontWeight.w900, fontSize: 12)),
                    ),
                  ),
                ),
              );
            } else {
              absentCount++;
              dayCells.add(
                DataCell(
                  Center(
                    child: Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.absentLightBg,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('✘', style: TextStyle(color: AppColors.absentRed, fontWeight: FontWeight.w900, fontSize: 12)),
                    ),
                  ),
                ),
              );
            }
          } else {
            dayCells.add(
              const DataCell(
                Center(
                  child: Text('-', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                ),
              ),
            );
          }
        }

        final totalClasses = presentCount + absentCount;
        final pct = totalClasses > 0 ? (presentCount / totalClasses * 100).toStringAsFixed(0) : '0';

        rows.add(
          DataRow(
            color: WidgetStateProperty.all(studentBg),
            cells: [
              // Roll No
              DataCell(
                Center(
                  child: Text(
                    student.rollNumber.padLeft(2, '0'),
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                  ),
                ),
              ),
              // Name
              DataCell(
                Text(
                  student.name,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.textDark),
                ),
              ),
              // Timing
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isMorning ? const Color(0xFFFEF3C7) : const Color(0xFFEDE9FE),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    session,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isMorning ? const Color(0xFFB45309) : const Color(0xFF6D28D9),
                    ),
                  ),
                ),
              ),
              // Day columns
              ...dayCells,
              // Summary
              DataCell(Center(child: Text(presentCount.toString(), style: const TextStyle(color: AppColors.presentGreen, fontWeight: FontWeight.w700)))),
              DataCell(Center(child: Text(absentCount.toString(), style: const TextStyle(color: AppColors.absentRed, fontWeight: FontWeight.w700)))),
              DataCell(
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: (int.tryParse(pct) ?? 0) >= 75 ? AppColors.presentLightBg : AppColors.absentLightBg,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '$pct%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: (int.tryParse(pct) ?? 0) >= 75 ? AppColors.presentGreen : AppColors.absentRed,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }
    }

    return rows;
  }

  Widget _buildOverviewTab(
    List<Student> students,
    Map<String, AttendanceRecord> attendanceMap,
    String monthTitle,
    double overallPercentage,
    int overallPresents,
    int overallAbsents,
    int totalMarked,
  ) {
    final teamLabel = _selectedTeam == 'all'
        ? 'All Teams'
        : (_selectedTeam == 'team1' ? 'Team 1' : 'Team 2');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Class Overview Card
          StatsSummaryCard(
            title: '$teamLabel • Monthly Overview',
            subtitle: 'Aggregated Morning & Evening Attendance for $monthTitle',
            percentage: overallPercentage,
            presentCount: overallPresents,
            absentCount: overallAbsents,
            totalCount: totalMarked,
          ),

          const SizedBox(height: 20),

          // Individual Student Cards
          const Text(
            'Student Breakdown',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark),
          ),
          const SizedBox(height: 10),

          ...students.map((student) {
            int morningP = 0;
            int morningA = 0;
            int eveningP = 0;
            int eveningA = 0;

            final daysInMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;
            for (int d = 1; d <= daysInMonth; d++) {
              final dateStr = DateFormat('yyyy-MM-dd').format(DateTime(_selectedMonth.year, _selectedMonth.month, d));
              final mRec = attendanceMap[AttendanceRecord.generateId(student.id, dateStr, 'morning')];
              final eRec = attendanceMap[AttendanceRecord.generateId(student.id, dateStr, 'evening')];

              if (mRec != null) {
                if (mRec.isPresent) morningP++;
                if (mRec.isAbsent) morningA++;
              }
              if (eRec != null) {
                if (eRec.isPresent) eveningP++;
                if (eRec.isAbsent) eveningA++;
              }
            }

            final totalStudentClasses = morningP + morningA + eveningP + eveningA;
            final studentPresents = morningP + eveningP;
            final studentPct = totalStudentClasses > 0 ? (studentPresents / totalStudentClasses * 100) : 0.0;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: AppStyles.cardDecoration(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          student.rollNumber.padLeft(2, '0'),
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.primaryBlue),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              student.name,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark),
                            ),
                            Text(
                              '${student.teamDisplayName} • Parent: ${student.parentName}',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: studentPct >= 75 ? AppColors.presentLightBg : AppColors.absentLightBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${studentPct.toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: studentPct >= 75 ? AppColors.presentGreen : AppColors.absentRed,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: AppColors.borderLight),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7).withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Morning Session', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFB45309))),
                              const SizedBox(height: 4),
                              Text('$morningP Present • $morningA Absent', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEDE9FE).withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Evening Session', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF6D28D9))),
                              const SizedBox(height: 4),
                              Text('$eveningP Present • $eveningA Absent', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
