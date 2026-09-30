import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
}
