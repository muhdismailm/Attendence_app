import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/auth_provider.dart';
import '../../state/student_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_styles.dart';
import '../../widgets/custom_button.dart';

class TutorProfileScreen extends StatelessWidget {
  const TutorProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final studentProv = context.watch<StudentProvider>();
    final user = auth.currentUser;

    final totalStudents = studentProv.allStudents.length;
    final activeStudents = studentProv.activeStudents.length;

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
                          color: Colors.black.withOpacity(0.12),
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
                            color: Colors.white.withOpacity(0.85),
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
                            _buildStatItem('Class Groups', '4', Icons.view_quilt_rounded, AppColors.eveningBadgeText),
                          ],
                        ),
                      ],
                    ),
                  ),

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
                        _buildInfoRow('4-Digit PIN', '•••• (Active)'),
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
