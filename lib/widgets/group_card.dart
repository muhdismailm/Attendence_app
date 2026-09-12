import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_styles.dart';

class GroupCard extends StatelessWidget {
  final String team; // 'team1' or 'team2'
  final String timing; // 'morning' or 'evening'
  final int studentCount;
  final VoidCallback onTap;

  const GroupCard({
    super.key,
    required this.team,
    required this.timing,
    required this.studentCount,
    required this.onTap,
  });

  bool get isTeam1 => team.toLowerCase() == 'team1';
  bool get isMorning => timing.toLowerCase() == 'morning';

  @override
  Widget build(BuildContext context) {
    final teamTitle = isTeam1 ? 'TEAM 1' : 'TEAM 2';
    final timingLabel = isMorning ? 'Morning' : 'Evening';
    final timingIcon = isMorning ? Icons.wb_sunny_rounded : Icons.nights_stay_rounded;
    final timingBadgeBg = isMorning ? AppColors.morningBadgeBg : AppColors.eveningBadgeBg;
    final timingBadgeText = isMorning ? AppColors.morningBadgeText : AppColors.eveningBadgeText;

    return Container(
      decoration: AppStyles.cardDecoration(),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppStyles.cardBorderRadius,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppStyles.cardBorderRadius,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Team Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isTeam1 ? AppColors.team1BadgeBg : AppColors.team2BadgeBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        teamTitle,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isTeam1 ? AppColors.team1BadgeText : AppColors.team2BadgeText,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    // Timing Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: timingBadgeBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(timingIcon, size: 14, color: timingBadgeText),
                          const SizedBox(width: 4),
                          Text(
                            timingLabel,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: timingBadgeText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Student Count
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.groups_rounded,
                        color: AppColors.primaryBlue,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$studentCount Students',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                        const Text(
                          'Regular class roster',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(height: 1, color: AppColors.borderLight),
                const SizedBox(height: 10),
                // Action Button / Prompt
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Take Attendance',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
