import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/student_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_styles.dart';
import 'mark_attendance_screen.dart';

class TeamClassesScreen extends StatelessWidget {
  final String team; // 'team1' or 'team2'

  const TeamClassesScreen({
    super.key,
    required this.team,
  });

  bool get isTeam1 => team.toLowerCase() == 'team1';
  String get teamDisplayName => isTeam1 ? 'Team 1' : 'Team 2';

  @override
  Widget build(BuildContext context) {
    final studentProv = context.watch<StudentProvider>();
    final totalStudents = studentProv.getTeamTotalStudentCount(team);
    final morningCount = totalStudents;
    final eveningCount = totalStudents;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          teamDisplayName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        backgroundColor: AppColors.headerGradientStart,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header gradient banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
              decoration: AppStyles.headerGradientDecoration,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          '$totalStudents Enrolled Students',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                        ),
                        child: const Text(
                          '2 Class Sessions',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Select a class session below to mark daily attendance or review student records.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w400,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Class Sessions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Both morning and evening classes for this team',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Morning Class Card
                  _buildClassCard(
                    context: context,
                    sessionTitle: 'Morning Class',
                    timingBadge: 'Morning Session',
                    timeRange: '8:00 AM – 12:00 PM',
                    studentCount: morningCount,
                    icon: Icons.wb_sunny_rounded,
                    badgeBg: AppColors.morningBadgeBg,
                    badgeTextColor: AppColors.morningBadgeText,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MarkAttendanceScreen(team: team, timing: 'morning'),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // Evening Class Card
                  _buildClassCard(
                    context: context,
                    sessionTitle: 'Evening Class',
                    timingBadge: 'Evening Session',
                    timeRange: '2:00 PM – 6:00 PM',
                    studentCount: eveningCount,
                    icon: Icons.nights_stay_rounded,
                    badgeBg: AppColors.eveningBadgeBg,
                    badgeTextColor: AppColors.eveningBadgeText,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MarkAttendanceScreen(team: team, timing: 'evening'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassCard({
    required BuildContext context,
    required String sessionTitle,
    required String timingBadge,
    required String timeRange,
    required int studentCount,
    required IconData icon,
    required Color badgeBg,
    required Color badgeTextColor,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: AppStyles.cardDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppStyles.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, size: 15, color: badgeTextColor),
                          const SizedBox(width: 6),
                          Text(
                            timingBadge,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: badgeTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      timeRange,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  sessionTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.people_alt_rounded,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$studentCount registered students',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: AppColors.borderLight),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Take Attendance',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryBlue,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
