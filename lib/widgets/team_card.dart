import 'package:flutter/material.dart';

class TeamCard extends StatelessWidget {
  final String team;
  final String? teamDisplayName;
  final int totalStudents;
  final VoidCallback onTap;
  final int index;

  const TeamCard({
    super.key,
    required this.team,
    this.teamDisplayName,
    required this.totalStudents,
    required this.onTap,
    this.index = 0,
  });

  String get displayName {
    if (teamDisplayName != null && teamDisplayName!.isNotEmpty) {
      return teamDisplayName!;
    }
    if (team.toLowerCase() == 'team1') return 'Team 1';
    if (team.toLowerCase() == 'team2') return 'Team 2';
    return team;
  }

  @override
  Widget build(BuildContext context) {
    // Elegant color palettes rotated by index
    final List<Map<String, Color>> palettes = [
      {
        'bg': const Color(0xFFEFF6FF),
        'border': const Color(0xFFDBEAFE),
        'avatar': const Color(0xFFDBEAFE),
        'icon': const Color(0xFF0066FF),
      },
      {
        'bg': const Color(0xFFF5F3FF),
        'border': const Color(0xFFEDE9FE),
        'avatar': const Color(0xFFEDE9FE),
        'icon': const Color(0xFF5B21B6),
      },
      {
        'bg': const Color(0xFFECFDF5),
        'border': const Color(0xFFD1FAE5),
        'avatar': const Color(0xFFD1FAE5),
        'icon': const Color(0xFF059669),
      },
      {
        'bg': const Color(0xFFFFFBEB),
        'border': const Color(0xFFFEF3C7),
        'avatar': const Color(0xFFFEF3C7),
        'icon': const Color(0xFFD97706),
      },
      {
        'bg': const Color(0xFFFFF1F2),
        'border': const Color(0xFFFFE4E6),
        'avatar': const Color(0xFFFFE4E6),
        'icon': const Color(0xFFE11D48),
      },
    ];

    final palette = palettes[index % palettes.length];
    final cardBgColor = palette['bg']!;
    final cardBorderColor = palette['border']!;
    final avatarBgColor = palette['avatar']!;
    final iconColor = palette['icon']!;

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
                        displayName,
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
