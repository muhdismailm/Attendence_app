import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/student_model.dart';
import '../../state/attendance_provider.dart';
import '../../state/student_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_styles.dart';
import '../../widgets/empty_state_view.dart';
import 'add_edit_student_screen.dart';

class StudentsScreen extends StatelessWidget {
  const StudentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final studentProv = context.watch<StudentProvider>();
    final students = studentProv.filteredStudents;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Students Directory', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.headerGradientStart,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Top Search and Filter Bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            decoration: AppStyles.headerGradientDecoration,
            child: Column(
              children: [
                // Search Input
                TextField(
                  onChanged: (val) => studentProv.setSearchQuery(val),
                  style: const TextStyle(fontSize: 14, color: AppColors.textDark),
                  decoration: InputDecoration(
                    hintText: 'Search student name, roll no, parent...',
                    hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textSecondary),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(
                        label: 'All Teams',
                        isSelected: studentProv.selectedTeamFilter == 'all',
                        onTap: () => studentProv.setTeamFilter('all'),
                      ),
                      ...studentProv.teams.map((team) {
                        return Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: _buildFilterChip(
                            label: team.name,
                            isSelected: studentProv.selectedTeamFilter.toLowerCase() == team.id.toLowerCase(),
                            onTap: () => studentProv.setTeamFilter(team.id),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Count Bar with the single 'Back to Active Students' button
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  studentProv.showInactiveOnly
                      ? 'Showing ${students.length} Inactive'
                      : 'Showing ${students.length} Students',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
                GestureDetector(
                  onTap: () => studentProv.toggleInactiveFilter(),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (studentProv.showInactiveOnly) ...[
                        const Icon(Icons.arrow_back_rounded, size: 14, color: AppColors.primaryBlue),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        studentProv.showInactiveOnly ? 'Back to Active Students' : 'Show Inactive Only',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Student List
          Expanded(
            child: students.isEmpty
                ? EmptyStateView(
                    icon: studentProv.showInactiveOnly ? Icons.person_off_rounded : Icons.person_search_rounded,
                    title: studentProv.showInactiveOnly ? 'No Inactive Students' : 'No Students Found',
                    message: studentProv.showInactiveOnly
                        ? 'There are currently no inactive students in this directory.'
                        : 'No student matches the current filter or search criteria.',
                    actionButtonText: studentProv.showInactiveOnly ? null : 'Add New Student',
                    onActionPressed: studentProv.showInactiveOnly
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const AddEditStudentScreen()),
                            );
                          },
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                    itemCount: students.length,
                    itemBuilder: (context, index) {
                      final s = students[index];
                      return _buildStudentCard(context, s);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: studentProv.showInactiveOnly
          ? null
          : FloatingActionButton(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              elevation: 4,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddEditStudentScreen()),
                );
              },
              child: const Icon(Icons.add, size: 28),
            ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.3),
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

  Widget _buildStudentCard(BuildContext context, Student student) {
    final studentProv = context.watch<StudentProvider>();
    final teamName = studentProv.getTeamName(student.team);
    final isTeam1 = student.team.toLowerCase() == 'team1';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: AppStyles.cardDecoration(),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppStyles.cardBorderRadius,
        child: InkWell(
          borderRadius: AppStyles.cardBorderRadius,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AddEditStudentScreen(student: student)),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Row(
              children: [
                // Roll No Circle
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: student.active ? AppColors.primaryLight : AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    student.rollNumber.padLeft(2, '0'),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: student.active ? AppColors.primaryBlue : AppColors.textMuted,
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Name and details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              student.name,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: student.active ? AppColors.textDark : AppColors.textMuted,
                                decoration: student.active ? null : TextDecoration.lineThrough,
                              ),
                            ),
                          ),
                          if (!student.active)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.absentLightBg,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Inactive',
                                style: TextStyle(fontSize: 10, color: AppColors.absentRed, fontWeight: FontWeight.w700),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          // Team Pill
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isTeam1 ? AppColors.team1BadgeBg : AppColors.team2BadgeBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              teamName,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isTeam1 ? AppColors.team1BadgeText : AppColors.team2BadgeText,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        student.place != null && student.place!.isNotEmpty
                            ? 'Parent: ${student.parentName} • ${student.place} (${student.parentPhone})'
                            : 'Parent: ${student.parentName} (${student.parentPhone})',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.absentRed, size: 20),
                  tooltip: 'Delete Student',
                  onPressed: () => _handleDeleteStudent(context, student, studentProv),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleDeleteStudent(BuildContext context, Student student, StudentProvider studentProv) async {
    final action = await showDialog<String>(
      context: context,
      builder: (ctx) => _ConfirmDeleteStudentDialog(student: student),
    );

    if (!context.mounted) return;

    if (action == 'inactive') {
      await studentProv.toggleActiveStatus(student.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${student.name} marked as inactive.'),
            backgroundColor: AppColors.primaryBlue,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    if (action == 'delete') {
      final attProv = context.read<AttendanceProvider>();

      // Show non-dismissible loading dialog with progress indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => PopScope(
          canPop: false,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            content: const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Row(
                children: [
                  CircularProgressIndicator(color: AppColors.absentRed),
                  SizedBox(width: 20),
                  Expanded(
                    child: Text(
                      'Deleting student and all cloud records...\nPlease wait.',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      try {
        final report = await studentProv.deleteStudent(student.id, attProv);
        if (context.mounted) {
          Navigator.of(context, rootNavigator: true).pop(); // Dismiss progress dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(report.summaryMessage),
              backgroundColor: AppColors.presentGreen,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          Navigator.of(context, rootNavigator: true).pop(); // Dismiss progress dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete student: ${e.toString().replaceAll("Exception: ", "")}'),
              backgroundColor: AppColors.absentRed,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    }
  }
}

class _ConfirmDeleteStudentDialog extends StatefulWidget {
  final Student student;

  const _ConfirmDeleteStudentDialog({required this.student});

  @override
  State<_ConfirmDeleteStudentDialog> createState() => _ConfirmDeleteStudentDialogState();
}

class _ConfirmDeleteStudentDialogState extends State<_ConfirmDeleteStudentDialog> {
  final TextEditingController _nameController = TextEditingController();
  bool _canDelete = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() {
      final matches = _nameController.text.trim().toLowerCase() ==
          widget.student.name.trim().toLowerCase();
      if (matches != _canDelete) {
        setState(() => _canDelete = matches);
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: AppColors.absentRed, size: 28),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Delete Student',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.absentLightBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.absentRed.withValues(alpha: 0.3)),
              ),
              child: Text(
                'This will permanently delete ${widget.student.name}, all attendance history, and the parent login. This action cannot be undone.',
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.absentRed,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'To confirm, type the student\'s name below:',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: widget.student.name,
                hintStyle: const TextStyle(color: AppColors.textMuted),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.absentRed, width: 2),
                ),
              ),
            ),
            if (widget.student.active) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.pause_circle_outline_rounded, size: 18, color: AppColors.primaryBlue),
                  label: const Text('Mark inactive instead', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.primaryBlue)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primaryBlue),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop('inactive');
                  },
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
        ),
        ElevatedButton(
          onPressed: _canDelete ? () => Navigator.of(context).pop('delete') : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.absentRed,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.absentRed.withValues(alpha: 0.3),
            disabledForegroundColor: Colors.white70,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Delete Permanently', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}
