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
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: AppStyles.cardDecoration(
        border: Border.all(
          color: isPresent
              ? AppColors.presentBorder.withOpacity(0.5)
              : isAbsent
                  ? AppColors.absentBorder.withOpacity(0.5)
                  : AppColors.borderLight,
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          // Roll Number Badge
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isPresent
                  ? AppColors.presentLightBg
                  : isAbsent
                      ? AppColors.absentLightBg
                      : AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              student.rollNumber.padLeft(2, '0'),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isPresent
                    ? AppColors.presentGreen
                    : isAbsent
                        ? AppColors.absentRed
                        : AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Student Details
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
                  ),
                  maxLines: 1,
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
          const SizedBox(width: 8),
          // Large Touch-friendly Toggle Buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Present Button
              _buildStatusButton(
                label: 'Present',
                isSelected: isPresent,
                activeBg: AppColors.presentGreen,
                activeText: Colors.white,
                inactiveBg: AppColors.presentLightBg.withOpacity(0.4),
                inactiveText: AppColors.presentGreen,
                onTap: () => onStatusChanged('present'),
              ),
              const SizedBox(width: 6),
              // Absent Button
              _buildStatusButton(
                label: 'Absent',
                isSelected: isAbsent,
                activeBg: AppColors.absentRed,
                activeText: Colors.white,
                inactiveBg: AppColors.absentLightBg.withOpacity(0.4),
                inactiveText: AppColors.absentRed,
                onTap: () => onStatusChanged('absent'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusButton({
    required String label,
    required bool isSelected,
    required Color activeBg,
    required Color activeText,
    required Color inactiveBg,
    required Color inactiveText,
    required VoidCallback onTap,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeInOut,
      child: Material(
        color: isSelected ? activeBg : inactiveBg,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? activeBg : Colors.transparent,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSelected) ...[
                  Icon(
                    label == 'Present' ? Icons.check_circle_rounded : Icons.cancel_rounded,
                    size: 14,
                    color: activeText,
                  ),
                  const SizedBox(width: 4),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: isSelected ? activeText : inactiveText,
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
