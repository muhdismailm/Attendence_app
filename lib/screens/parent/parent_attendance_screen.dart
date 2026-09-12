import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/student_model.dart';
import '../../state/attendance_provider.dart';
import '../../state/auth_provider.dart';
import '../../state/student_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_styles.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/stats_summary_card.dart';

class ParentAttendanceScreen extends StatefulWidget {
  const ParentAttendanceScreen({super.key});

  @override
  State<ParentAttendanceScreen> createState() => _ParentAttendanceScreenState();
}

class _ParentAttendanceScreenState extends State<ParentAttendanceScreen> {
  DateTime _selectedMonth = DateTime.now();

  void _changeMonth(int offset) {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + offset,
        1,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final studentProv = context.watch<StudentProvider>();
    final attProv = context.watch<AttendanceProvider>();

    final user = auth.currentUser;
    // Find linked student for this parent
    final Student? student = (user?.studentId != null)
        ? studentProv.getStudentById(user!.studentId!)
        : (user?.studentRollNo != null)
            ? studentProv.getStudentByRollNo(user!.studentRollNo!)
            : (studentProv.allStudents.isNotEmpty ? studentProv.allStudents.first : null);

    if (student == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Attendance', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          backgroundColor: AppColors.headerGradientStart,
          foregroundColor: Colors.white,
        ),
        body: const EmptyStateView(
          icon: Icons.person_off_rounded,
          title: 'No Linked Student',
          message: 'No student is currently linked to your parent account.',
        ),
      );
    }

    final monthTitle = DateFormat('MMMM yyyy').format(_selectedMonth);
    final stats = attProv.getStudentStats(
      student.id,
      year: _selectedMonth.year,
      month: _selectedMonth.month,
    );

    final double percentage = stats['percentage'] as double;
    final int presentCount = stats['presentCount'] as int;
    final int absentCount = stats['absentCount'] as int;
    final int totalClasses = stats['totalClasses'] as int;
    final List<dynamic> records = stats['records'] as List<dynamic>;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Attendance History', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.headerGradientStart,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Month Selector Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 16),
            decoration: AppStyles.headerGradientDecoration,
            child: Column(
              children: [
                Text(
                  student.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '${student.teamDisplayName} • ${student.timingDisplayName} (Roll No. ${student.rollNumber})',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
                const SizedBox(height: 12),
                // Month Switcher
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 24),
                        onPressed: () => _changeMonth(-1),
                      ),
                      Text(
                        monthTitle,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 24),
                        onPressed: () => _changeMonth(1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Monthly Stats Summary
                  StatsSummaryCard(
                    title: 'Monthly Summary',
                    subtitle: 'Attendance for $monthTitle',
                    percentage: percentage,
                    presentCount: presentCount,
                    absentCount: absentCount,
                    totalCount: totalClasses,
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'Daily Attendance Log',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 10),

                  if (records.isEmpty)
                    const EmptyStateView(
                      icon: Icons.calendar_today_rounded,
                      title: 'No Records Found',
                      message: 'No attendance records found for this month.',
                    )
                  else
                    ...records.map((rec) {
                      final parsed = DateTime.tryParse(rec.date);
                      final displayDate = parsed != null
                          ? DateFormat('EEEE, MMMM d, yyyy').format(parsed)
                          : rec.date;
                      final isPresent = rec.isPresent;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: AppStyles.cardDecoration(
                          border: Border.all(
                            color: isPresent
                                ? AppColors.presentBorder.withOpacity(0.4)
                                : AppColors.absentBorder.withOpacity(0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isPresent ? AppColors.presentLightBg : AppColors.absentLightBg,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    isPresent ? Icons.check_circle_rounded : Icons.cancel_rounded,
                                    color: isPresent ? AppColors.presentGreen : AppColors.absentRed,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      displayDate,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textDark,
                                      ),
                                    ),
                                    Text(
                                      'Recorded in session',
                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isPresent ? AppColors.presentLightBg : AppColors.absentLightBg,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                isPresent ? '✓ Present' : '✕ Absent',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isPresent ? AppColors.presentGreen : AppColors.absentRed,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
