import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/student_model.dart';
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
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Delete Student'),
                        content: Text('Are you sure you want to delete ${student.name}? This action cannot be undone.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Delete', style: TextStyle(color: AppColors.absentRed)),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      studentProv.deleteStudent(student.id);
                    }
                  },
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
