import 'package:flutter/material.dart';
import '../models/student_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_styles.dart';

class AttendanceTile extends StatelessWidget {
  final Student student;
  final String status; // 'present' or 'absent'
  final ValueChanged<String> onStatusChanged;

  const AttendanceTile({
    super.key,
    required this.student,
    required this.status,
    required this.onStatusChanged,
  });

  bool get isPresent => status.toLowerCase() == 'present';
  bool get isAbsent => status.toLowerCase() == 'absent';

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: AppStyles.cardDecoration(
        border: Border.all(
          color: isPresent
              ? AppColors.presentBorder.withOpacity(0.6)
              : AppColors.absentBorder.withOpacity(0.6),
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () {
            // Single tap toggles status between present and absent
            onStatusChanged(isPresent ? 'absent' : 'present');
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // Roll Number Badge
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isPresent
                        ? AppColors.presentLightBg
                        : AppColors.absentLightBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    student.rollNumber.padLeft(2, '0'),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isPresent
                          ? AppColors.presentGreen
                          : AppColors.absentRed,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Student Details (Full Name)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        student.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                          height: 1.25,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Roll No. ${student.rollNumber}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Ticking Box (Checkbox Style)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeInOut,
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: isPresent ? AppColors.presentGreen : AppColors.absentLightBg.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(
                      color: isPresent ? AppColors.presentGreen : AppColors.absentRed.withOpacity(0.7),
                      width: 2.0,
                    ),
                    boxShadow: isPresent
                        ? [
                            BoxShadow(
                              color: AppColors.presentGreen.withOpacity(0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 150),
                      transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                      child: isPresent
                          ? const Icon(
                              Icons.check_rounded,
                              key: ValueKey('ticked'),
                              size: 22,
                              color: Colors.white,
                            )
                          : Icon(
                              Icons.close_rounded,
                              key: const ValueKey('unticked'),
                              size: 18,
                              color: AppColors.absentRed.withOpacity(0.8),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
