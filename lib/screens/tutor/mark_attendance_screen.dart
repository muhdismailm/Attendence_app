import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/student_model.dart';
import '../../state/attendance_provider.dart';
import '../../state/auth_provider.dart';
import '../../state/student_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_styles.dart';
import '../../widgets/attendance_tile.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/empty_state_view.dart';

class MarkAttendanceScreen extends StatefulWidget {
  final String team; // 'team1' or 'team2'
  final String timing; // 'morning' or 'evening'

  const MarkAttendanceScreen({
    super.key,
    required this.team,
    required this.timing,
  });

  @override
  State<MarkAttendanceScreen> createState() => _MarkAttendanceScreenState();
}

class _MarkAttendanceScreenState extends State<MarkAttendanceScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AttendanceProvider>().initMarkingSession(
            team: widget.team,
            timing: widget.timing,
          );
    });
  }

  void _selectDate(BuildContext context) async {
    final attProv = context.read<AttendanceProvider>();
    final picked = await showDatePicker(
      context: context,
      initialDate: attProv.selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 90)),
      lastDate: DateTime.now().add(const Duration(days: 7)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryBlue,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      attProv.setDate(picked);
    }
  }

  void _handleSave(List<Student> students) async {
    final auth = context.read<AuthProvider>();
    final attProv = context.read<AttendanceProvider>();
    final tutorId = auth.currentUser?.id ?? 'tutor_01';

    final success = await attProv.saveAttendance(
      students: students,
      tutorId: tutorId,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Text(
                'Attendance saved successfully for ${attProv.selectedDateDisplay}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          backgroundColor: AppColors.presentGreen,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save attendance. Please try again.'),
          backgroundColor: AppColors.absentRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final studentProv = context.watch<StudentProvider>();
    final attProv = context.watch<AttendanceProvider>();

    final groupStudents = studentProv.getStudentsForGroup(widget.team, widget.timing);
    final teamTitle = widget.team.toLowerCase() == 'team1' ? 'Team 1' : 'Team 2';
    final timingTitle = widget.timing.toLowerCase() == 'morning' ? 'Morning' : 'Evening';
    final groupTitle = '$teamTitle • $timingTitle';

    final markingState = attProv.currentMarkingState;
    final presentCount = attProv.presentCountInSession;
    final absentCount = attProv.absentCountInSession;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          groupTitle,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18),
        ),
        backgroundColor: AppColors.headerGradientStart,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded, color: Colors.white),
            tooltip: 'Change Date',
            onPressed: () => _selectDate(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Header info bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            decoration: AppStyles.headerGradientDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () => _selectDate(context),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.edit_calendar_rounded, size: 14, color: Colors.white),
                            const SizedBox(width: 6),
                            Text(
                              attProv.selectedDateDisplay,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Text(
                      '${groupStudents.length} Students',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Live Counter Chips
                Row(
                  children: [
                    _buildPillBadge(
                      label: '$presentCount Present',
                      color: AppColors.presentLightBg,
                      textColor: AppColors.presentGreen,
                      icon: Icons.check_circle_rounded,
                    ),
                    const SizedBox(width: 8),
                    _buildPillBadge(
                      label: '$absentCount Absent',
                      color: AppColors.absentLightBg,
                      textColor: AppColors.absentRed,
                      icon: Icons.cancel_rounded,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Bulk Actions Bar
          if (groupStudents.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => attProv.markAllPresent(groupStudents),
                      icon: const Icon(Icons.done_all_rounded, size: 18, color: AppColors.presentGreen),
                      label: const Text('Mark All Present', style: TextStyle(color: AppColors.presentGreen)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.presentBorder, width: 1.5),
                        backgroundColor: AppColors.presentLightBg.withOpacity(0.4),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => attProv.markAllAbsent(groupStudents),
                      icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.absentRed),
                      label: const Text('Mark All Absent', style: TextStyle(color: AppColors.absentRed)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.absentBorder, width: 1.5),
                        backgroundColor: AppColors.absentLightBg.withOpacity(0.4),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Student List
          Expanded(
            child: groupStudents.isEmpty
                ? const EmptyStateView(
                    icon: Icons.people_outline_rounded,
                    title: 'No Students in this Class',
                    message: 'Add students to this team and timing to start taking attendance.',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                    itemCount: groupStudents.length,
                    itemBuilder: (context, index) {
                      final student = groupStudents[index];
                      final currentStatus = markingState[student.id] ?? 'present';

                      return AttendanceTile(
                        student: student,
                        status: currentStatus,
                        onStatusChanged: (newStatus) {
                          attProv.setStudentStatus(student.id, newStatus);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),

      // Sticky Bottom Save Action
      bottomSheet: groupStudents.isEmpty
          ? null
          : Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: CustomButton(
                  text: '✓ SAVE ATTENDANCE',
                  isLoading: attProv.isSaving,
                  icon: Icons.check_circle_outline_rounded,
                  onPressed: () => _handleSave(groupStudents),
                ),
              ),
            ),
    );
  }

  Widget _buildPillBadge({
    required String label,
    required Color color,
    required Color textColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
