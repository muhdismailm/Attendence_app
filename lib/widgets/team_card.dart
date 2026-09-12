import 'package:flutter/material.dart';

class TeamCard extends StatelessWidget {
  final String team; // 'team1' or 'team2'
  final int totalStudents;
  final VoidCallback onTap;

  const TeamCard({
    super.key,
    required this.team,
    required this.totalStudents,
    required this.onTap,
  });

  bool get isTeam1 => team.toLowerCase() == 'team1';
  String get teamDisplayName => isTeam1 ? 'Team 1' : 'Team 2';

  @override
  Widget build(BuildContext context) {
    // Exact colors matching the design screenshot
    final cardBgColor = isTeam1
        ? const Color(0xFFEFF6FF) // Soft pastel blue
        : const Color(0xFFF5F3FF); // Soft pastel purple/lavender

    final cardBorderColor = isTeam1
        ? const Color(0xFFDBEAFE)
        : const Color(0xFFEDE9FE);

    final avatarBgColor = isTeam1
        ? const Color(0xFFDBEAFE) // Light blue circle
        : const Color(0xFFEDE9FE); // Light purple circle

    final iconColor = isTeam1
        ? const Color(0xFF0066FF) // Bold blue
        : const Color(0xFF5B21B6); // Bold deep purple

    const buttonColor = Color(0xFF0066FF); // Bright blue circle button

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          decoration: BoxDecoration(
            color: cardBgColor,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: cardBorderColor, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 20.0),
            child: Row(
              children: [
                // Left circular icon avatar
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    color: avatarBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.people_rounded,
                      size: 32,
                      color: iconColor,
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Middle Text Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        teamDisplayName,
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(
                            Icons.people_rounded,
                            size: 16,
                            color: Color(0xFF64748B),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$totalStudents Students',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'View Morning and Evening classes',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Right circular arrow button
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: buttonColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x330066FF),
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 22,
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
