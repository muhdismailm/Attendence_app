import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/attendance_provider.dart';
import '../../state/auth_provider.dart';
import '../../state/student_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_header.dart';
import '../../widgets/team_card.dart';
import '../../widgets/stats_summary_card.dart';
import 'team_classes_screen.dart';

class TutorHomeScreen extends StatelessWidget {
  const TutorHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final studentProv = context.watch<StudentProvider>();
    final attProv = context.watch<AttendanceProvider>();

    final user = auth.currentUser;
    final todayStats = attProv.getTodaySummary();
    final int presentCount = todayStats['present'] ?? 0;
    final int absentCount = todayStats['absent'] ?? 0;

    final teams = studentProv.teams;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Blue Header
            CommonHeader(
              greeting: 'Good Morning 👋',
              title: user?.name ?? 'Tutor',
              badgeText: 'TUTOR',
              badgeColor: Colors.white,
              showDate: true,
              trailing: IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                tooltip: 'Refresh',
                onPressed: () => (context as Element).markNeedsBuild(),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Today's Attendance Small Summary Card
                  StatsSummaryCard(
                    title: "Today's Attendance",
                    subtitle: 'Aggregated live count for today',
                    presentCount: presentCount,
                    absentCount: absentCount,
                  ),

                  const SizedBox(height: 24),

                  // Section Title matching the screenshot
                  const Text(
                    'Teams',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Select a team to view classes',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (teams.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.group_off_rounded, size: 44, color: AppColors.textSecondary),
                          const SizedBox(height: 10),
                          const Text(
                            'No Teams Found',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Create teams from your Profile or Team Management console.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: teams.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final team = teams[index];
                        final count = studentProv.getTeamTotalStudentCount(team.id);

                        return TeamCard(
                          team: team.id,
                          teamDisplayName: team.name,
                          totalStudents: count,
                          index: index,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TeamClassesScreen(team: team.id),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
