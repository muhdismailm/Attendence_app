import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_styles.dart';

class StatsSummaryCard extends StatelessWidget {
  final String title;
  final double? percentage;
  final int presentCount;
  final int absentCount;
  final int? totalCount;
  final String? subtitle;

  const StatsSummaryCard({
    super.key,
    required this.title,
    this.percentage,
    required this.presentCount,
    required this.absentCount,
    this.totalCount,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppStyles.cardDecoration(),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              if (percentage != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: percentage! >= 75.0 ? AppColors.presentLightBg : AppColors.absentLightBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${percentage!.toStringAsFixed(0)}% Overall',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: percentage! >= 75.0 ? AppColors.presentGreen : AppColors.absentRed,
                    ),
                  ),
                ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              // Present Stat Box
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                  decoration: BoxDecoration(
                    color: AppColors.presentLightBg.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.presentBorder.withOpacity(0.5)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.presentGreen,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.check, color: Colors.white, size: 16),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$presentCount',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.presentGreen,
                            ),
                          ),
                          const Text(
                            'Present',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Absent Stat Box
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                  decoration: BoxDecoration(
                    color: AppColors.absentLightBg.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.absentBorder.withOpacity(0.5)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.absentRed,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.close, color: Colors.white, size: 16),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$absentCount',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.absentRed,
                            ),
                          ),
                          const Text(
                            'Absent',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (totalCount != null) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$totalCount',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark,
                          ),
                        ),
                        const Text(
                          'Total Classes',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
