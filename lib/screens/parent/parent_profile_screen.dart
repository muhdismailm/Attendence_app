import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/student_model.dart';
import '../../state/auth_provider.dart';
import '../../state/student_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_styles.dart';
import '../../widgets/custom_button.dart';

class ParentProfileScreen extends StatelessWidget {
  const ParentProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final studentProv = context.watch<StudentProvider>();
    final user = auth.currentUser;

    final Student? student = (user?.studentId != null)
        ? studentProv.getStudentById(user!.studentId!)
        : (user?.studentRollNo != null)
            ? studentProv.getStudentByRollNo(user!.studentRollNo!)
            : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Parent Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
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
                      Icons.family_restroom_rounded,
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
                          user?.name ?? 'Parent',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '@${user?.username ?? "parent"}  •  Parent Account',
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
                  // Linked Child Card
                  if (student != null)
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: AppStyles.cardDecoration(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Linked Child Information',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark),
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow('Student Name', student.name),
                          const Divider(height: 16, color: AppColors.borderLight),
                          _buildInfoRow('Roll Number', student.rollNumber),
                          const Divider(height: 16, color: AppColors.borderLight),
                          _buildInfoRow('Class Group', '${student.teamDisplayName} • ${student.timingDisplayName}'),
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Account Details
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
                        _buildInfoRow('Username', user?.username ?? ''),
                        const Divider(height: 16, color: AppColors.borderLight),
                        _buildInfoRow('Phone', user?.phone ?? 'Not provided'),
                        const Divider(height: 16, color: AppColors.borderLight),
                        _buildInfoRow('4-Digit PIN', '•••• (Active)'),
                        const Divider(height: 16, color: AppColors.borderLight),
                        _buildInfoRow('Role', 'Parent (Read-Only)'),
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
