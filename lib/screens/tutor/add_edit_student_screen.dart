import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/student_model.dart';
import '../../state/student_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_styles.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class AddEditStudentScreen extends StatefulWidget {
  final Student? student; // If null, mode is Add; otherwise Edit

  const AddEditStudentScreen({super.key, this.student});

  @override
  State<AddEditStudentScreen> createState() => _AddEditStudentScreenState();
}

class _AddEditStudentScreenState extends State<AddEditStudentScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _rollController;
  late TextEditingController _parentNameController;
  late TextEditingController _parentPhoneController;
  late TextEditingController _parentEmailController;

  late String _selectedTeam;
  late bool _isActive;

  bool get isEdit => widget.student != null;

  @override
  void initState() {
    super.initState();
    final s = widget.student;
    _nameController = TextEditingController(text: s?.name ?? '');
    _rollController = TextEditingController(text: s?.rollNumber ?? '');
    _parentNameController = TextEditingController(text: s?.parentName ?? '');
    _parentPhoneController = TextEditingController(text: s?.parentPhone ?? '');
    _parentEmailController = TextEditingController(text: s?.parentEmail ?? '');

    _selectedTeam = s?.team ?? 'team1';
    _isActive = s?.active ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _rollController.dispose();
    _parentNameController.dispose();
    _parentPhoneController.dispose();
    _parentEmailController.dispose();
    super.dispose();
  }

  void _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final studentProv = context.read<StudentProvider>();

    if (isEdit) {
      final updated = widget.student!.copyWith(
        name: _nameController.text.trim(),
        rollNumber: _rollController.text.trim(),
        team: _selectedTeam,
        timing: 'both',
        parentName: _parentNameController.text.trim(),
        parentPhone: _parentPhoneController.text.trim(),
        parentEmail: _parentEmailController.text.trim(),
        active: _isActive,
      );
      await studentProv.updateStudent(updated);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Student updated successfully'),
          backgroundColor: AppColors.primaryBlue,
        ),
      );
    } else {
      final newStudent = Student(
        id: 'stud_${DateTime.now().millisecondsSinceEpoch}',
        name: _nameController.text.trim(),
        rollNumber: _rollController.text.trim(),
        team: _selectedTeam,
        timing: 'both',
        parentName: _parentNameController.text.trim(),
        parentPhone: _parentPhoneController.text.trim(),
        parentEmail: _parentEmailController.text.trim(),
        active: true,
      );
      await studentProv.addStudent(newStudent);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Student added successfully'),
          backgroundColor: AppColors.presentGreen,
        ),
      );
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final studentProv = context.watch<StudentProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          isEdit ? 'Edit Student' : 'Add New Student',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppColors.headerGradientStart,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Academic Info Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: AppStyles.cardDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Student Details',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _nameController,
                      label: 'Student Full Name',
                      hint: 'e.g. Ismail',
                      prefixIcon: Icons.person_outline_rounded,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter student name' : null,
                    ),
                    const SizedBox(height: 14),
                    CustomTextField(
                      controller: _rollController,
                      label: 'Roll Number',
                      hint: 'e.g. 01',
                      prefixIcon: Icons.numbers_rounded,
                      keyboardType: TextInputType.number,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter roll number' : null,
                    ),
                    const SizedBox(height: 16),

                    // Team Selection (Morning & Evening sessions are automatically applied to both teams)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Team',
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
                              child: _buildTeamOption(
                                teamKey: 'team1',
                                title: 'Team 1',
                                isSelected: _selectedTeam == 'team1',
                                onSelect: () => setState(() => _selectedTeam = 'team1'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildTeamOption(
                                teamKey: 'team2',
                                title: 'Team 2',
                                isSelected: _selectedTeam == 'team2',
                                onSelect: () => setState(() => _selectedTeam = 'team2'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceMuted,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.borderLight),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.info_outline_rounded, size: 16, color: AppColors.primaryBlue),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Student will automatically attend both Morning & Evening classes',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Parent Info Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: AppStyles.cardDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Parent / Guardian Info',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _parentNameController,
                      label: 'Parent Name',
                      hint: 'e.g. Parent of Ismail',
                      prefixIcon: Icons.badge_outlined,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter parent name' : null,
                    ),
                    const SizedBox(height: 14),
                    CustomTextField(
                      controller: _parentPhoneController,
                      label: 'Parent Phone',
                      hint: 'e.g. +91 98111 00001',
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter phone' : null,
                    ),
                    const SizedBox(height: 14),
                    CustomTextField(
                      controller: _parentEmailController,
                      label: 'Parent Email / Contact Username',
                      hint: 'e.g. ismail.parent@example.com',
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ],
                ),
              ),

              if (isEdit) ...[
                const SizedBox(height: 16),
                // Status Toggle Card
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: AppStyles.cardDecoration(),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Active Student',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                          ),
                          Text(
                            _isActive
                                ? 'Student appears in daily attendance'
                                : 'Deactivated (attendance history preserved)',
                            style: TextStyle(
                              fontSize: 12,
                              color: _isActive ? AppColors.presentGreen : AppColors.absentRed,
                            ),
                          ),
                        ],
                      ),
                      Switch.adaptive(
                        value: _isActive,
                        activeTrackColor: AppColors.primaryBlue,
                        onChanged: (val) => setState(() => _isActive = val),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 28),

              // Save Button
              CustomButton(
                text: isEdit ? 'Save Changes' : 'Add Student',
                isLoading: studentProv.isLoading,
                icon: isEdit ? Icons.save_rounded : Icons.person_add_alt_1_rounded,
                onPressed: _handleSave,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeamOption({
    required String teamKey,
    required String title,
    required bool isSelected,
    required VoidCallback onSelect,
  }) {
    final isTeam1 = teamKey == 'team1';
    final activeBg = isTeam1 ? const Color(0xFFEFF6FF) : const Color(0xFFF5F3FF);
    final activeBorder = isTeam1 ? AppColors.primaryBlue : const Color(0xFF6366F1);
    final activeColor = isTeam1 ? AppColors.primaryBlue : const Color(0xFF6366F1);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? activeBg : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? activeBorder : AppColors.borderLight,
              width: isSelected ? 1.8 : 1.0,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isTeam1 ? Icons.people_rounded : Icons.diversity_3_rounded,
                size: 20,
                color: isSelected ? activeColor : AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? AppColors.textDark : AppColors.textSecondary,
                ),
              ),
              if (isSelected) ...[
                const SizedBox(width: 6),
                Icon(Icons.check_circle_rounded, size: 16, color: activeColor),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
