import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/auth_provider.dart';
import '../../state/student_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_styles.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/pin_input_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _pinController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  String _selectedRole = 'parent'; // 'parent' or 'tutor'
  String? _selectedStudentId;
  bool _obscurePin = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _pinController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (_pinController.text.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PIN must be exactly 4 digits'),
          backgroundColor: AppColors.absentRed,
        ),
      );
      return;
    }

    if (_selectedRole == 'parent' && _selectedStudentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your child to link your parent account'),
          backgroundColor: AppColors.absentRed,
        ),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final studentProv = context.read<StudentProvider>();
    final linkedStudent = _selectedStudentId != null ? studentProv.getStudentById(_selectedStudentId!) : null;

    final success = await auth.register(
      username: _usernameController.text,
      pin: _pinController.text,
      name: _nameController.text,
      role: _selectedRole,
      studentId: _selectedStudentId,
      studentRollNo: linkedStudent?.rollNumber,
      phone: _phoneController.text,
    );

    if (!mounted) return;

    if (success) {
      Navigator.pop(context); // Return to home/nav shell
    } else if (auth.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage!),
          backgroundColor: AppColors.absentRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final studentProv = context.watch<StudentProvider>();
    final availableStudents = studentProv.allStudents;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Create Account', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.headerGradientStart,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
              decoration: AppStyles.headerGradientDecoration,
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Join Attendance App',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Register with a unique username and 4-digit PIN',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: AppStyles.cardDecoration(boxShadow: AppStyles.elevatedCardShadow),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Role Selector Pills
                      const Text(
                        'Account Type',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildRoleSelector(
                              title: 'Parent',
                              subtitle: 'View Child Stats',
                              icon: Icons.family_restroom_rounded,
                              isSelected: _selectedRole == 'parent',
                              onTap: () => setState(() => _selectedRole = 'parent'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildRoleSelector(
                              title: 'Tutor',
                              subtitle: 'Manage & Mark',
                              icon: Icons.school_rounded,
                              isSelected: _selectedRole == 'tutor',
                              onTap: () => setState(() => _selectedRole = 'tutor'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Full Name
                      CustomTextField(
                        controller: _nameController,
                        label: 'Full Name',
                        hint: 'e.g. Parent of Ismail',
                        prefixIcon: Icons.badge_outlined,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter name' : null,
                      ),
                      const SizedBox(height: 16),

                      // Username
                      CustomTextField(
                        controller: _usernameController,
                        label: 'Username',
                        hint: 'e.g. parent_ismail',
                        prefixIcon: Icons.alternate_email_rounded,
                        validator: (v) => (v == null || v.trim().length < 3) ? 'Min 3 characters' : null,
                      ),
                      const SizedBox(height: 16),

                      // 4-Digit PIN
                      PinInputField(
                        controller: _pinController,
                        label: 'Choose 4-Digit PIN',
                        obscurePin: _obscurePin,
                        onToggleObscure: () {
                          setState(() {
                            _obscurePin = !_obscurePin;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Phone
                      CustomTextField(
                        controller: _phoneController,
                        label: 'Phone Number',
                        hint: 'e.g. +91 98111 00001',
                        prefixIcon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                      ),

                      // If Parent: Link Child Dropdown
                      if (_selectedRole == 'parent') ...[
                        const SizedBox(height: 16),
                        const Text(
                          'Link to Your Child',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedStudentId,
                          hint: const Text('Select your child from student list', style: TextStyle(fontSize: 14)),
                          items: availableStudents.map((student) {
                            return DropdownMenuItem<String>(
                              value: student.id,
                              child: Text(
                                '${student.name} (${student.teamDisplayName} • ${student.timingDisplayName} - Roll ${student.rollNumber})',
                                style: const TextStyle(fontSize: 13),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedStudentId = val;
                            });
                          },
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: AppStyles.cardBorderRadius,
                              borderSide: const BorderSide(color: AppColors.borderLight, width: 1.2),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: AppStyles.cardBorderRadius,
                              borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.8),
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Submit Button
                      CustomButton(
                        text: 'Register Account',
                        isLoading: auth.isLoading,
                        icon: Icons.check_circle_outline_rounded,
                        onPressed: _handleRegister,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleSelector({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primaryBlue : AppColors.borderLight,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primaryBlue : AppColors.textSecondary,
              size: 26,
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isSelected ? AppColors.primaryDark : AppColors.textDark,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? AppColors.primaryBlue : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
