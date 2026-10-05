import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/student_model.dart';
import '../../models/user_model.dart';
import '../../state/student_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_styles.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/parent_credentials_bottom_sheet.dart';

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
  late TextEditingController _placeController;
  late TextEditingController _parentPhoneController;
  late TextEditingController _secondaryPhoneController;

  static const List<String> _countryCodes = [
    '+91',
    '+971',
    '+966',
    '+968',
    '+974',
    '+965',
    '+973',
    '+1',
    '+44',
  ];

  String _selectedCountryCode = '+91';
  String _selectedSecondaryCountryCode = '+91';
  bool _hasSecondaryPhone = false;

  late String _selectedTeam;
  late String _selectedTiming;
  late bool _isActive;

  bool get isEdit => widget.student != null;

  Student? get _currentStudent {
    if (!isEdit) return null;
    final studentProv = context.watch<StudentProvider>();
    return studentProv.getStudentById(widget.student!.id) ?? widget.student;
  }

  bool _isCreatingParentAccount = false;
  bool _isReissuingParentLogin = false;
  bool _isTogglingParentActive = false;

  @override
  void initState() {
    super.initState();
    final s = widget.student;
    _nameController = TextEditingController(text: s?.name ?? '');
    _rollController = TextEditingController(text: s?.rollNumber ?? '');
    _parentNameController = TextEditingController(text: s?.parentName ?? '');
    _placeController = TextEditingController(text: s?.place ?? '');

    // Parse primary phone
    String rawPrimary = s?.parentPhone.trim() ?? '';
    for (final code in _countryCodes) {
      if (rawPrimary.startsWith(code)) {
        _selectedCountryCode = code;
        rawPrimary = rawPrimary.substring(code.length).trim();
        break;
      }
    }
    _parentPhoneController = TextEditingController(
      text: rawPrimary.replaceAll(RegExp(r'\D'), ''),
    );

    // Parse secondary phone
    String rawSecondary = s?.secondaryPhone?.trim() ?? '';
    if (rawSecondary.isNotEmpty) {
      _hasSecondaryPhone = true;
      for (final code in _countryCodes) {
        if (rawSecondary.startsWith(code)) {
          _selectedSecondaryCountryCode = code;
          rawSecondary = rawSecondary.substring(code.length).trim();
          break;
        }
      }
      _secondaryPhoneController = TextEditingController(
        text: rawSecondary.replaceAll(RegExp(r'\D'), ''),
      );
    } else {
      _hasSecondaryPhone = false;
      _secondaryPhoneController = TextEditingController();
    }

    _selectedTeam = s?.team ?? 'team1';
    _selectedTiming = (s?.timing == 'evening') ? 'evening' : 'morning';
    _isActive = s?.active ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _rollController.dispose();
    _parentNameController.dispose();
    _placeController.dispose();
    _parentPhoneController.dispose();
    _secondaryPhoneController.dispose();
    super.dispose();
  }

  void _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final studentProv = context.read<StudentProvider>();
    final primaryDigits = _parentPhoneController.text.trim();
    final fullPrimaryPhone = '$_selectedCountryCode $primaryDigits';

    final secondaryDigits = _secondaryPhoneController.text.trim();
    final fullSecondaryPhone = _hasSecondaryPhone && secondaryDigits.isNotEmpty
        ? '$_selectedSecondaryCountryCode $secondaryDigits'
        : null;

    try {
      if (isEdit) {
        final updated = widget.student!.copyWith(
          name: _nameController.text.trim(),
          rollNumber: _rollController.text.trim(),
          team: _selectedTeam,
          timing: _selectedTiming,
          parentName: _parentNameController.text.trim(),
          place: _placeController.text.trim(),
          parentPhone: fullPrimaryPhone,
          secondaryPhone: fullSecondaryPhone,
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
        Navigator.pop(context);
      } else {
        final newStudent = Student(
          id: 'stud_${DateTime.now().millisecondsSinceEpoch}',
          name: _nameController.text.trim(),
          rollNumber: _rollController.text.trim(),
          team: _selectedTeam,
          timing: _selectedTiming,
          parentName: _parentNameController.text.trim(),
          place: _placeController.text.trim(),
          parentPhone: fullPrimaryPhone,
          secondaryPhone: fullSecondaryPhone,
          active: true,
        );

        // Step 1: Save student to Firestore
        await studentProv.addStudent(newStudent);

        // Step 2: Attempt parent account creation
        try {
          final creds = await studentProv.createParentAccount(newStudent);
          if (!mounted) return;
          await ParentCredentialsBottomSheet.show(
            context: context,
            studentName: newStudent.name,
            loginId: creds.loginId,
            pin: creds.pin,
          );
        } catch (accountError) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Student saved, but parent account creation failed: $accountError',
              ),
              backgroundColor: AppColors.absentRed,
              duration: const Duration(seconds: 4),
            ),
          );
        }

        if (!mounted) return;
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.absentRed,
        ),
      );
    }
  }

  Future<void> _handleCreateParentLogin(Student student) async {
    setState(() => _isCreatingParentAccount = true);
    final studentProv = context.read<StudentProvider>();
    try {
      final creds = await studentProv.createParentAccount(student);
      if (!mounted) return;
      await ParentCredentialsBottomSheet.show(
        context: context,
        studentName: student.name,
        loginId: creds.loginId,
        pin: creds.pin,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create parent login: $e'),
          backgroundColor: AppColors.absentRed,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isCreatingParentAccount = false);
      }
    }
  }

  Future<void> _handleIssueNewParentLogin(Student student) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.absentRed),
            SizedBox(width: 8),
            Text('Issue New Login?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ],
        ),
        content: const Text(
          'The old ID and password will stop working. A new login ID and 6-digit PIN will be issued for the parent.',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.absentRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Issue New Login', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    setState(() => _isReissuingParentLogin = true);
    final studentProv = context.read<StudentProvider>();
    try {
      final creds = await studentProv.issueNewParentLogin(student);
      if (!mounted) return;
      await ParentCredentialsBottomSheet.show(
        context: context,
        studentName: student.name,
        loginId: creds.loginId,
        pin: creds.pin,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to issue new parent login: $e'),
          backgroundColor: AppColors.absentRed,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isReissuingParentLogin = false);
      }
    }
  }

  Future<void> _handleToggleParentActive(String parentUid, bool currentActive) async {
    setState(() => _isTogglingParentActive = true);
    final studentProv = context.read<StudentProvider>();
    try {
      await studentProv.setParentActive(parentUid, !currentActive);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(!currentActive ? 'Parent account enabled' : 'Parent account disabled'),
          backgroundColor: !currentActive ? AppColors.presentGreen : AppColors.textDark,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update parent status: $e'),
          backgroundColor: AppColors.absentRed,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isTogglingParentActive = false);
      }
    }
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

                    // Team Selection
                    Consumer<StudentProvider>(
                      builder: (context, studentProv, _) {
                        final teams = studentProv.teams;

                        // Default selection if current isn't in list
                        if (teams.isNotEmpty && !teams.any((t) => t.id.toLowerCase() == _selectedTeam.toLowerCase())) {
                          _selectedTeam = teams.first.id;
                        }

                        return Column(
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

                            if (teams.isEmpty)
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.absentLightBg,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.absentRed.withValues(alpha: 0.3)),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.warning_amber_rounded, color: AppColors.absentRed, size: 20),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'No teams exist. Please create a team from Profile first.',
                                        style: TextStyle(fontSize: 12, color: AppColors.absentRed, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: teams.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final team = entry.value;
                                  final isSelected = _selectedTeam.toLowerCase() == team.id.toLowerCase();

                                  return SizedBox(
                                    width: (MediaQuery.of(context).size.width - 62) / 2,
                                    child: _buildTeamOption(
                                      teamKey: team.id,
                                      title: team.name,
                                      isSelected: isSelected,
                                      index: index,
                                      onSelect: () => setState(() => _selectedTeam = team.id),
                                    ),
                                  );
                                }).toList(),
                              ),

                            const SizedBox(height: 16),
                            const Text(
                              'Timing',
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
                                    teamKey: 'morning',
                                    title: 'Morning',
                                    isSelected: _selectedTiming == 'morning',
                                    index: 1, // different color
                                    onSelect: () => setState(() => _selectedTiming = 'morning'),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _buildTeamOption(
                                    teamKey: 'evening',
                                    title: 'Evening',
                                    isSelected: _selectedTiming == 'evening',
                                    index: 2, // different color
                                    onSelect: () => setState(() => _selectedTiming = 'evening'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
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
                      'Parent Details',
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
                      hint: 'e.g. Mohammed / Guardian Name',
                      prefixIcon: Icons.badge_outlined,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter parent name' : null,
                    ),
                    const SizedBox(height: 14),
                    CustomTextField(
                      controller: _placeController,
                      label: 'Place / City',
                      hint: 'e.g. Calicut',
                      prefixIcon: Icons.location_on_outlined,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter place / city' : null,
                    ),
                    const SizedBox(height: 14),
                    _buildPhoneField(
                      label: 'Parent Phone Number',
                      controller: _parentPhoneController,
                      countryCode: _selectedCountryCode,
                      onCountryCodeChanged: (newCode) {
                        if (newCode != null) setState(() => _selectedCountryCode = newCode);
                      },
                      isRequired: true,
                    ),
                    const SizedBox(height: 14),
                    if (_hasSecondaryPhone) ...[
                      _buildPhoneField(
                        label: 'Secondary Phone Number (Optional)',
                        controller: _secondaryPhoneController,
                        countryCode: _selectedSecondaryCountryCode,
                        onCountryCodeChanged: (newCode) {
                          if (newCode != null) setState(() => _selectedSecondaryCountryCode = newCode);
                        },
                        isRequired: false,
                        onRemove: () {
                          setState(() {
                            _hasSecondaryPhone = false;
                            _secondaryPhoneController.clear();
                          });
                        },
                      ),
                    ] else ...[
                      OutlinedButton.icon(
                        onPressed: () => setState(() => _hasSecondaryPhone = true),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryBlue,
                          side: const BorderSide(color: AppColors.borderLight, width: 1.2),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.add_call, size: 16),
                        label: const Text(
                          'Add Another Phone Number',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              if (isEdit && _currentStudent != null) ...[
                _buildParentAccountCard(_currentStudent!),
              ],

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
    int index = 0,
  }) {
    final List<Color> colors = [
      AppColors.primaryBlue,
      const Color(0xFF7C3AED),
      const Color(0xFF059669),
      const Color(0xFFD97706),
      const Color(0xFFE11D48),
    ];
    final activeColor = colors[index % colors.length];
    final activeBg = activeColor.withValues(alpha: 0.08);
    final activeBorder = activeColor;

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
                Icons.groups_rounded,
                size: 20,
                color: isSelected ? activeColor : AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected ? AppColors.textDark : AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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

  Widget _buildPhoneField({
    required String label,
    required TextEditingController controller,
    required String countryCode,
    required ValueChanged<String?> onCountryCodeChanged,
    required bool isRequired,
    VoidCallback? onRemove,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            if (onRemove != null)
              GestureDetector(
                onTap: onRemove,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.remove_circle_outline_rounded, size: 14, color: AppColors.absentRed),
                    SizedBox(width: 4),
                    Text(
                      'Remove',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.absentRed,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Country Code selector
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppStyles.cardBorderRadius,
                border: Border.all(color: AppColors.borderLight, width: 1.2),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _countryCodes.contains(countryCode) ? countryCode : _countryCodes.first,
                  icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.textSecondary, size: 20),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                  dropdownColor: Colors.white,
                  items: _countryCodes.map((code) {
                    return DropdownMenuItem<String>(
                      value: code,
                      child: Text(code, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                    );
                  }).toList(),
                  onChanged: onCountryCodeChanged,
                ),
              ),
            ),
            const SizedBox(width: 8),

            // 10-Digit Phone field
            Expanded(
              child: TextFormField(
                controller: controller,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textDark,
                ),
                decoration: InputDecoration(
                  hintText: '10-digit number',
                  hintStyle: const TextStyle(fontSize: 14, color: AppColors.textMuted),
                  counterText: '',
                  prefixIcon: const Icon(Icons.phone_outlined, size: 20, color: AppColors.textSecondary),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: AppStyles.cardBorderRadius,
                    borderSide: const BorderSide(color: AppColors.borderLight, width: 1.2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: AppStyles.cardBorderRadius,
                    borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.8),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: AppStyles.cardBorderRadius,
                    borderSide: const BorderSide(color: AppColors.absentRed, width: 1.2),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: AppStyles.cardBorderRadius,
                    borderSide: const BorderSide(color: AppColors.absentRed, width: 1.8),
                  ),
                ),
                validator: (val) {
                  final digits = (val ?? '').replaceAll(RegExp(r'\D'), '');
                  if (isRequired) {
                    if (digits.isEmpty) {
                      return 'Please enter 10-digit number';
                    }
                    if (digits.length != 10) {
                      return 'Must be exactly 10 digits';
                    }
                  } else {
                    if (digits.isNotEmpty && digits.length != 10) {
                      return 'Must be exactly 10 digits';
                    }
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildParentAccountCard(Student student) {
    final studentProv = context.watch<StudentProvider>();
    final hasParent = student.parentId != null && student.parentId!.trim().isNotEmpty;

    if (!hasParent) {
      return Container(
        margin: const EdgeInsets.only(top: 16),
        padding: const EdgeInsets.all(18),
        decoration: AppStyles.cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Parent App Login',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                _buildStatusChip(
                  label: 'Not created',
                  bgColor: AppColors.surfaceMuted,
                  textColor: AppColors.textSecondary,
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'This student does not have a linked parent login account yet.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isCreatingParentAccount
                    ? null
                    : () => _handleCreateParentLogin(student),
                icon: _isCreatingParentAccount
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.person_add_rounded, size: 18),
                label: Text(
                  _isCreatingParentAccount ? 'Creating Account...' : 'Create Parent Login',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return StreamBuilder<AppUser?>(
      stream: studentProv.streamParentAccount(student.parentId!),
      builder: (context, snapshot) {
        final parentUser = snapshot.data;
        final bool isLoading = snapshot.connectionState == ConnectionState.waiting && parentUser == null;

        if (isLoading) {
          return Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.all(18),
            decoration: AppStyles.cardDecoration(),
            child: const Center(
              child: SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryBlue),
              ),
            ),
          );
        }

        final bool isAccountActive = parentUser?.active ?? false;
        final bool mustChangePassword = parentUser?.mustChangePassword ?? false;
        final String loginId = parentUser?.username ?? '—';

        // Derived Status:
        // - Disabled: active == false
        // - Waiting for first login: active == true && mustChangePassword == true
        // - Active: active == true && mustChangePassword == false
        final String statusLabel;
        final Color statusBg;
        final Color statusText;

        if (!isAccountActive) {
          statusLabel = 'Disabled';
          statusBg = AppColors.absentLightBg;
          statusText = AppColors.absentRed;
        } else if (mustChangePassword) {
          statusLabel = 'Waiting for first login';
          statusBg = const Color(0xFFFEF3C7);
          statusText = const Color(0xFFB45309);
        } else {
          statusLabel = 'Active';
          statusBg = AppColors.presentLightBg;
          statusText = AppColors.presentGreen;
        }

        return Container(
          margin: const EdgeInsets.only(top: 16),
          padding: const EdgeInsets.all(18),
          decoration: AppStyles.cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Parent App Login',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  _buildStatusChip(
                    label: statusLabel,
                    bgColor: statusBg,
                    textColor: statusText,
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Login ID row
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.alternate_email_rounded, size: 18, color: AppColors.textSecondary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Login ID',
                            style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            loginId,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 18, color: AppColors.primaryBlue),
                      tooltip: 'Copy Login ID',
                      visualDensity: VisualDensity.compact,
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: loginId));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Login ID copied to clipboard'),
                            duration: Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Action Buttons: Issue New Login and Enable/Disable Toggle
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isReissuingParentLogin
                          ? null
                          : () => _handleIssueNewParentLogin(student),
                      icon: _isReissuingParentLogin
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh_rounded, size: 16),
                      label: Text(
                        _isReissuingParentLogin ? 'Issuing...' : 'Issue New Login',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryBlue,
                        side: const BorderSide(color: AppColors.primaryBlue),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isTogglingParentActive
                          ? null
                          : () => _handleToggleParentActive(student.parentId!, isAccountActive),
                      icon: _isTogglingParentActive
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              isAccountActive ? Icons.block_rounded : Icons.check_circle_outline_rounded,
                              size: 16,
                            ),
                      label: Text(
                        _isTogglingParentActive
                            ? 'Updating...'
                            : (isAccountActive ? 'Disable' : 'Enable'),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isAccountActive ? AppColors.absentRed : AppColors.presentGreen,
                        side: BorderSide(
                          color: isAccountActive ? AppColors.absentRed : AppColors.presentGreen,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusChip({
    required String label,
    required Color bgColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}
