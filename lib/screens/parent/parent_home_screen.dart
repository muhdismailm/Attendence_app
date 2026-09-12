import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/student_model.dart';
import '../../state/attendance_provider.dart';
import '../../state/auth_provider.dart';
import '../../state/student_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_styles.dart';
import '../../widgets/common_header.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/stats_summary_card.dart';

class ParentHomeScreen extends StatelessWidget {
  final VoidCallback onNavigateToAttendance;

  const ParentHomeScreen({
    super.key,
    required this.onNavigateToAttendance,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final studentProv = context.watch<StudentProvider>();
    final attProv = context.watch<AttendanceProvider>();

    final user = auth.currentUser;
    // Find child for parent
    final Student? student = (user?.studentId != null)
        ? studentProv.getStudentById(user!.studentId!)
        : (user?.studentRollNo != null)
            ? studentProv.getStudentByRollNo(user!.studentRollNo!)
            : (studentProv.allStudents.isNotEmpty ? studentProv.allStudents.first : null);

    if (student == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            CommonHeader(
              greeting: 'Hello 👋',
              title: user?.name ?? 'Parent',
              badgeText: 'PARENT',
              showDate: true,
            ),
            const Expanded(
              child: EmptyStateView(
                icon: Icons.family_restroom_rounded,
                title: 'No Linked Student',
                message: 'Your account is not linked to any student profile yet.',
              ),
            ),
          ],
        ),
      );
    }

    final now = DateTime.now();
    final stats = attProv.getStudentStats(student.id, year: now.year, month: now.month);
    final double percentage = stats['percentage'] as double;
    final int presentCount = stats['presentCount'] as int;
    final int absentCount = stats['absentCount'] as int;
    final int totalClasses = stats['totalClasses'] as int;

    // Check today's status
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    final history = attProv.getStudentAttendanceHistory(student.id);
    final todayRecord = history.where((r) => r.date == todayStr).toList();
    final String todayStatusText = todayRecord.isNotEmpty
        ? (todayRecord.first.isPresent ? 'Present Today' : 'Absent Today')
        : 'Not Marked Yet';
    final Color todayStatusColor = todayRecord.isNotEmpty
        ? (todayRecord.first.isPresent ? AppColors.presentGreen : AppColors.absentRed)
        : AppColors.textSecondary;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            CommonHeader(
              greeting: 'Hello 👋',
              title: user?.name ?? 'Parent',
              subtitle: 'Welcome to your child portal',
              badgeText: 'PARENT',
              showDate: true,
            ),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Main Child Profile Card
                  Container(
                    decoration: AppStyles.cardDecoration(boxShadow: AppStyles.elevatedCardShadow),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(
                                student.rollNumber.padLeft(2, '0'),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primaryBlue,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    student.name,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${student.teamDisplayName} • ${student.timingDisplayName}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),
                        const Divider(height: 1, color: AppColors.borderLight),
                        const SizedBox(height: 16),

                        // Today's Quick Status
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Today's Status",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: todayStatusColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    todayRecord.isNotEmpty && todayRecord.first.isPresent
                                        ? Icons.check_circle_rounded
                                        : Icons.info_outline_rounded,
                                    size: 14,
                                    color: todayStatusColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    todayStatusText,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: todayStatusColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // View Attendance CTA
                        CustomButton(
                          text: 'View Full Attendance',
                          icon: Icons.calendar_month_rounded,
                          onPressed: onNavigateToAttendance,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Monthly Summary Widget
                  StatsSummaryCard(
                    title: 'Current Month Overview',
                    subtitle: 'Attendance percentage and breakdown',
                    percentage: percentage,
                    presentCount: presentCount,
                    absentCount: absentCount,
                    totalCount: totalClasses,
                  ),

                  const SizedBox(height: 20),

                  // Important Note Card for Parents
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withOpacity(0.5),
                      borderRadius: AppStyles.cardBorderRadius,
                      border: Border.all(color: AppColors.primaryBlue.withOpacity(0.15)),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.verified_user_outlined, color: AppColors.primaryBlue, size: 20),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Parent Portal Security',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'You are securely viewing only your child’s records. Attendance can only be marked by the tutor.',
                                style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
