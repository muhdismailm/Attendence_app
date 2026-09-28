import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/team_model.dart';
import '../../state/auth_provider.dart';
import '../../state/student_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_styles.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/pin_confirmation_dialog.dart';
import '../../widgets/sync_status_card.dart';
import 'manage_teams_screen.dart';

class TutorProfileScreen extends StatelessWidget {
  const TutorProfileScreen({super.key});

  void _openCreateTeamModal(BuildContext context) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
            left: 20,
            right: 20,
            top: 20,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.borderLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Row(
                  children: [
                    Icon(Icons.group_add_rounded, color: AppColors.primaryBlue, size: 24),
                    SizedBox(width: 10),
                    Text(
                      'Create New Team',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'A 4-digit security PIN is required to confirm creation.',
                  style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 18),
                CustomTextField(
                  controller: nameController,
                  label: 'Team / Batch Name',
                  hint: 'e.g. Team 3, Science Batch',
                  prefixIcon: Icons.badge_outlined,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter team name' : null,
                ),
                const SizedBox(height: 14),
                CustomTextField(
                  controller: descController,
                  label: 'Description (Optional)',
                  hint: 'e.g. Morning & Evening classes',
                  prefixIcon: Icons.notes_rounded,
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          side: const BorderSide(color: AppColors.borderLight),
                        ),
                        onPressed: () => Navigator.pop(sheetContext),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;
                          final teamName = nameController.text.trim();
                          final teamDesc = descController.text.trim();

                          Navigator.pop(sheetContext);

                          final confirmed = await PinConfirmationDialog.show(
                            context: context,
                            title: 'Create "$teamName"',
                            message: 'Please enter your 4-digit login PIN to confirm creating this new team.',
                            confirmButtonText: 'Create Team',
                            confirmButtonColor: AppColors.primaryBlue,
                          );

                          if (confirmed && context.mounted) {
                            final studentProv = context.read<StudentProvider>();
                            final created = await studentProv.createTeam(
                              name: teamName,
                              description: teamDesc.isNotEmpty ? teamDesc : null,
                            );

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Team "${created.name}" created successfully!'),
                                  backgroundColor: AppColors.presentGreen,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              );
                            }
                          }
                        },
                        child: const Text('Next: Verify PIN', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleDeleteTeam(BuildContext context, Team team, int studentCount) async {
    final confirmed = await PinConfirmationDialog.show(
      context: context,
      title: 'Delete "${team.name}"?',
      message: 'CRITICAL: Deleting "${team.name}" will permanently remove all $studentCount student(s) in this team and their entire attendance history from the database.\n\nEnter your 4-digit login PIN to authorize.',
      confirmButtonText: 'Delete Permanently',
      confirmButtonColor: AppColors.absentRed,
      isDestructive: true,
    );

    if (confirmed && context.mounted) {
      final studentProv = context.read<StudentProvider>();
      await studentProv.deleteTeam(team.id);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Team "${team.name}" and all associated records deleted.'),
            backgroundColor: AppColors.absentRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final studentProv = context.watch<StudentProvider>();
    final user = auth.currentUser;

    final totalStudents = studentProv.allStudents.length;
    final activeStudents = studentProv.activeStudents.length;
    final teams = studentProv.teams;
    final classGroupsCount = teams.length * 2; // morning and evening for each team

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Tutor Profile & Settings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.headerGradientStart,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Blue Profile Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
              decoration: AppStyles.headerGradientDecoration,
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.school_rounded,
                      size: 32,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? 'Tutor',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '@${user?.username ?? "tutor"}  •  Tutor Account',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
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
                  // App Overview Card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: AppStyles.cardDecoration(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'System Statistics',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            _buildStatItem('Total Students', '$totalStudents', Icons.groups_rounded, AppColors.primaryBlue),
                            const SizedBox(width: 12),
                            _buildStatItem('Active Students', '$activeStudents', Icons.person_pin_circle_rounded, AppColors.presentGreen),
                            const SizedBox(width: 12),
                            _buildStatItem('Teams (${teams.length})', '$classGroupsCount classes', Icons.view_quilt_rounded, AppColors.eveningBadgeText),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Team & Batch Management Card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: AppStyles.cardDecoration(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.groups_rounded, color: AppColors.primaryBlue, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Team Management',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark),
                                ),
                              ],
                            ),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryBlue,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              icon: const Icon(Icons.add_rounded, size: 16),
                              label: const Text('Add Team', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                              onPressed: () => _openCreateTeamModal(context),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Create, edit or delete teams. Changes require 4-digit PIN for database security.',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 14),

                        if (teams.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(16),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceMuted,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'No teams created yet. Tap "Add Team" to start.',
                              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                            ),
                          )
                        else
                          Column(
                            children: teams.map((team) {
                              final count = studentProv.getTeamTotalStudentCount(team.id);
                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceMuted,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.borderLight),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryBlue.withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Center(
                                        child: Icon(Icons.groups_rounded, size: 20, color: AppColors.primaryBlue),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            team.name,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.textDark,
                                            ),
                                          ),
                                          Text(
                                            '$count student(s)',
                                            style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.absentRed),
                                      tooltip: 'Delete Team (PIN required)',
                                      onPressed: () => _handleDeleteTeam(context, team, count),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),

                        const SizedBox(height: 4),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              side: const BorderSide(color: AppColors.primaryBlue),
                            ),
                            icon: const Icon(Icons.settings_suggest_rounded, size: 16, color: AppColors.primaryBlue),
                            label: const Text(
                              'Full Team Management Console',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primaryBlue),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ManageTeamsScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Offline-First Sync Card & Dynamic Sync Button
                  const SyncStatusCard(),

                  const SizedBox(height: 16),

                  // Account Info Card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: AppStyles.cardDecoration(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Account Details',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark),
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow('Username', user?.username ?? 'tutor'),
                        const Divider(height: 16, color: AppColors.borderLight),
                        _buildInfoRow('Role', 'Tutor (Administrator)'),
                        const Divider(height: 16, color: AppColors.borderLight),
                        _buildInfoRow('Contact Phone', user?.phone ?? '+91 98765 43210'),
                        const Divider(height: 16, color: AppColors.borderLight),
                        _buildInfoRow('4-Digit PIN', '•••• (Active for security verification)'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Logout Button
                  CustomButton(
                    text: 'Sign Out',
                    icon: Icons.logout_rounded,
                    backgroundColor: AppColors.absentRed,
                    textColor: Colors.white,
                    onPressed: () => auth.logout(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
      ],
    );
  }
}
