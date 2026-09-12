import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_styles.dart';

class CommonHeader extends StatelessWidget {
  final String greeting;
  final String title;
  final String? subtitle;
  final String? badgeText;
  final Color? badgeColor;
  final bool showDate;
  final Widget? trailing;
  final VoidCallback? onBack;
  final double bottomPadding;

  const CommonHeader({
    super.key,
    required this.greeting,
    required this.title,
    this.subtitle,
    this.badgeText,
    this.badgeColor,
    this.showDate = true,
    this.trailing,
    this.onBack,
    this.bottomPadding = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    final todayFormatted = DateFormat('EEEE, MMM d, yyyy').format(DateTime.now());

    return Container(
      width: double.infinity,
      decoration: AppStyles.headerGradientDecoration,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 20,
        right: 20,
        bottom: bottomPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (onBack != null)
                IconButton(
                  onPressed: onBack,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                )
              else
                Row(
                  children: [
                    Text(
                      greeting,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (badgeText != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: (badgeColor ?? Colors.white).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.4),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          badgeText!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
          if (showDate) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today_rounded, size: 13, color: Colors.white.withOpacity(0.8)),
                const SizedBox(width: 6),
                Text(
                  todayFormatted,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
