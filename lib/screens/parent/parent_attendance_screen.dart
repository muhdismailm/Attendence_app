import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/attendance_model.dart';
import '../../models/student_model.dart';
import '../../state/attendance_provider.dart';
import '../../state/auth_provider.dart';
import '../../state/student_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_styles.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/stats_summary_card.dart';

class ParentAttendanceScreen extends StatefulWidget {
  const ParentAttendanceScreen({super.key});

  @override
  State<ParentAttendanceScreen> createState() => _ParentAttendanceScreenState();
}

class _ParentAttendanceScreenState extends State<ParentAttendanceScreen> {
  DateTime _selectedMonth = DateTime.now();
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
  }

  void _changeMonth(int offset, {DateTime? newSelectedDay}) {
    setState(() {
      final newMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + offset,
        1,
      );
      _selectedMonth = newMonth;
      if (newSelectedDay != null) {
        _selectedDay = newSelectedDay;
      } else {
        final now = DateTime.now();
        if (newMonth.year == now.year && newMonth.month == now.month) {
          _selectedDay = now;
        } else {
          _selectedDay = newMonth;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final studentProv = context.watch<StudentProvider>();
    final attProv = context.watch<AttendanceProvider>();

    final user = auth.currentUser;
    // Find linked student for this parent
    final Student? student = (user?.studentId != null)
        ? studentProv.getStudentById(user!.studentId!)
        : (user?.studentRollNo != null)
            ? studentProv.getStudentByRollNo(user!.studentRollNo!)
            : (studentProv.allStudents.isNotEmpty ? studentProv.allStudents.first : null);

    if (student == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Attendance', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          backgroundColor: AppColors.headerGradientStart,
          foregroundColor: Colors.white,
        ),
        body: const EmptyStateView(
          icon: Icons.person_off_rounded,
          title: 'No Linked Student',
          message: 'No student is currently linked to your parent account.',
        ),
      );
    }

    final monthTitle = DateFormat('MMMM yyyy').format(_selectedMonth);
    final stats = attProv.getStudentStats(
      student.id,
      year: _selectedMonth.year,
      month: _selectedMonth.month,
    );

    final double percentage = stats['percentage'] as double;
    final int presentCount = stats['presentCount'] as int;
    final int absentCount = stats['absentCount'] as int;
    final int totalClasses = stats['totalClasses'] as int;

    // Fetch all records for this student to index into morning/evening calendar dots
    final List<AttendanceRecord> allRecords = attProv.getStudentAttendanceHistory(student.id);

    // Map records by date string 'yyyy-MM-dd' and timing ('morning' / 'evening')
    final Map<String, Map<String, AttendanceRecord>> recordsByDate = {};
    for (final rec in allRecords) {
      final dateKey = rec.date.trim();
      recordsByDate.putIfAbsent(dateKey, () => {});
      final timing = (rec.timing ?? 'morning').trim().toLowerCase();
      if (timing == 'both') {
        recordsByDate[dateKey]!['morning'] = rec;
        recordsByDate[dateKey]!['evening'] = rec;
      } else {
        recordsByDate[dateKey]![timing] = rec;
      }
    }

    // Selected day attendance records
    final selectedDateKey = DateFormat('yyyy-MM-dd').format(_selectedDay);
    final selectedDayRecords = recordsByDate[selectedDateKey];
    final AttendanceRecord? selectedMorning = selectedDayRecords?['morning'];
    final AttendanceRecord? selectedEvening = selectedDayRecords?['evening'];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Attendance History', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.headerGradientStart,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Student Banner Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 16),
            decoration: AppStyles.headerGradientDecoration,
            child: Column(
              children: [
                Text(
                  student.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${student.teamDisplayName} • ${student.timingDisplayName} (Roll No. ${student.rollNumber})',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.88),
                  ),
                ),
              ],
            ),
          ),

          // Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- 1. CALENDAR CARD (as in reference pic) ---
                  _buildCalendarCard(context, recordsByDate),

                  const SizedBox(height: 16),

                  // --- 2. ATTENDANCE DOT LEGEND ---
                  _buildLegendCard(),

                  const SizedBox(height: 16),

                  // --- 3. SELECTED DAY BREAKDOWN CARD ---
                  _buildSelectedDayCard(selectedMorning, selectedEvening),

                  const SizedBox(height: 16),

                  // --- 4. MONTHLY STATS SUMMARY CARD ---
                  StatsSummaryCard(
                    title: 'Monthly Summary',
                    subtitle: 'Attendance for $monthTitle',
                    percentage: percentage,
                    presentCount: presentCount,
                    absentCount: absentCount,
                    totalCount: totalClasses,
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Calendar card designed to match the reference picture
  Widget _buildCalendarCard(
    BuildContext context,
    Map<String, Map<String, AttendanceRecord>> recordsByDate,
  ) {
    final firstDayOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final daysInMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;
    final daysInPrevMonth = DateTime(_selectedMonth.year, _selectedMonth.month, 0).day;

    // Sunday = 0, Monday = 1, ... Saturday = 6
    final int firstWeekdayOffset = firstDayOfMonth.weekday % 7;
    final int totalCells = (firstWeekdayOffset + daysInMonth > 35) ? 42 : 35;
    final monthHeaderTitle = DateFormat('MMMM, yyyy').format(_selectedMonth);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppColors.borderLight.withOpacity(0.8)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      child: Column(
        children: [
          // Month Switcher Header: < Month, Year >
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded, color: AppColors.textDark, size: 28),
                onPressed: () => _changeMonth(-1),
                splashRadius: 22,
              ),
              Text(
                monthHeaderTitle,
                style: const TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                  letterSpacing: 0.2,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded, color: AppColors.textDark, size: 28),
                onPressed: () => _changeMonth(1),
                splashRadius: 22,
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Days of Week labels (Sun, Mon, Tue, Wed, Thu, Fri, Sat)
          Row(
            children: const [
              Expanded(child: Center(child: Text('Sun', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary)))),
              Expanded(child: Center(child: Text('Mon', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary)))),
              Expanded(child: Center(child: Text('Tue', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary)))),
              Expanded(child: Center(child: Text('Wed', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary)))),
              Expanded(child: Center(child: Text('Thu', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary)))),
              Expanded(child: Center(child: Text('Fri', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary)))),
              Expanded(child: Center(child: Text('Sat', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary)))),
            ],
          ),

          const SizedBox(height: 8),
          const Divider(height: 1, color: AppColors.borderLight),
          const SizedBox(height: 8),

          // Grid of Days
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: totalCells,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.0,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemBuilder: (context, i) {
              final bool isPrevMonth = i < firstWeekdayOffset;
              final bool isNextMonth = i >= firstWeekdayOffset + daysInMonth;
              final bool isCurrentMonth = !isPrevMonth && !isNextMonth;

              DateTime cellDate;
              int displayDay;

              if (isPrevMonth) {
                displayDay = daysInPrevMonth - firstWeekdayOffset + i + 1;
                cellDate = DateTime(_selectedMonth.year, _selectedMonth.month - 1, displayDay);
              } else if (isNextMonth) {
                displayDay = i - (firstWeekdayOffset + daysInMonth) + 1;
                cellDate = DateTime(_selectedMonth.year, _selectedMonth.month + 1, displayDay);
              } else {
                displayDay = i - firstWeekdayOffset + 1;
                cellDate = DateTime(_selectedMonth.year, _selectedMonth.month, displayDay);
              }

              final cellDateKey = DateFormat('yyyy-MM-dd').format(cellDate);
              final dayMap = recordsByDate[cellDateKey];
              final AttendanceRecord? morningRec = dayMap?['morning'];
              final AttendanceRecord? eveningRec = dayMap?['evening'];

              final bool isSelected = _selectedDay.year == cellDate.year &&
                  _selectedDay.month == cellDate.month &&
                  _selectedDay.day == cellDate.day;

              final now = DateTime.now();
              final bool isToday = now.year == cellDate.year &&
                  now.month == cellDate.month &&
                  now.day == cellDate.day;

              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedDay = cellDate;
                    if (isPrevMonth) {
                      _selectedMonth = DateTime(cellDate.year, cellDate.month, 1);
                    } else if (isNextMonth) {
                      _selectedMonth = DateTime(cellDate.year, cellDate.month, 1);
                    }
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFE11D48) // Rose highlight container like reference pic
                        : (isToday ? AppColors.primaryLight.withOpacity(0.5) : Colors.transparent),
                    borderRadius: BorderRadius.circular(12),
                    border: isToday && !isSelected
                        ? Border.all(color: const Color(0xFFE11D48).withOpacity(0.5), width: 1.2)
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$displayDay',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: isSelected ? FontWeight.w700 : (isToday ? FontWeight.w700 : FontWeight.w500),
                          color: isSelected
                              ? Colors.white
                              : (!isCurrentMonth
                                  ? Colors.grey.shade400
                                  : AppColors.textDark),
                        ),
                      ),
                      const SizedBox(height: 3),
                      // Two dots for Morning and Evening
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Left Dot: Morning
                          Container(
                            width: 5.5,
                            height: 5.5,
                            decoration: BoxDecoration(
                              color: morningRec != null
                                  ? (morningRec.isPresent ? AppColors.presentGreen : AppColors.absentRed)
                                  : Colors.transparent,
                              shape: BoxShape.circle,
                              border: isSelected && morningRec != null
                                  ? Border.all(color: Colors.white, width: 0.8)
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 3.5),
                          // Right Dot: Evening
                          Container(
                            width: 5.5,
                            height: 5.5,
                            decoration: BoxDecoration(
                              color: eveningRec != null
                                  ? (eveningRec.isPresent ? AppColors.presentGreen : AppColors.absentRed)
                                  : Colors.transparent,
                              shape: BoxShape.circle,
                              border: isSelected && eveningRec != null
                                  ? Border.all(color: Colors.white, width: 0.8)
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Legend explaining two dots and green/red status
  Widget _buildLegendCard() {
    return Container(
      decoration: AppStyles.cardDecoration(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.info_outline_rounded, size: 16, color: AppColors.textSecondary),
              SizedBox(width: 6),
              Text(
                'Calendar Attendance Legend',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 9,
                      height: 9,
                      decoration: const BoxDecoration(
                        color: AppColors.presentGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Expanded(
                      child: Text(
                        'Left Dot: Morning',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 9,
                      height: 9,
                      decoration: const BoxDecoration(
                        color: AppColors.presentGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Expanded(
                      child: Text(
                        'Right Dot: Evening',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: AppColors.borderLight),
          const SizedBox(height: 8),
          Row(
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.presentGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Green = Present',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: AppColors.presentGreen),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.absentRed,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Red = Absent',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: AppColors.absentRed),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Selected day morning & evening session details
  Widget _buildSelectedDayCard(
    AttendanceRecord? morningRec,
    AttendanceRecord? eveningRec,
  ) {
    final formattedSelectedDate = DateFormat('EEEE, MMMM d, yyyy').format(_selectedDay);

    return Container(
      decoration: AppStyles.cardDecoration(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFFE11D48).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.event_note_rounded, size: 18, color: Color(0xFFE11D48)),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Selected Day Details',
                    style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    formattedSelectedDate,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.borderLight),
          const SizedBox(height: 12),

          // Morning Session Tile
          _buildSessionTile(
            title: 'Morning Session',
            icon: Icons.wb_sunny_rounded,
            iconColor: const Color(0xFFF59E0B),
            iconBg: const Color(0xFFFEF3C7),
            record: morningRec,
          ),

          const SizedBox(height: 10),

          // Evening Session Tile
          _buildSessionTile(
            title: 'Evening Session',
            icon: Icons.nights_stay_rounded,
            iconColor: const Color(0xFF6366F1),
            iconBg: const Color(0xFFEEF2FF),
            record: eveningRec,
          ),
        ],
      ),
    );
  }

  Widget _buildSessionTile({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required AttendanceRecord? record,
  }) {
    final bool isPresent = record?.isPresent ?? false;
    final bool isMarked = record != null;

    final Color badgeBg = !isMarked
        ? Colors.grey.shade100
        : (isPresent ? AppColors.presentLightBg : AppColors.absentLightBg);

    final Color badgeTextColor = !isMarked
        ? Colors.grey.shade600
        : (isPresent ? AppColors.presentGreen : AppColors.absentRed);

    final String badgeText = !isMarked
        ? 'Not Marked'
        : (isPresent ? '✓ Present' : '✕ Absent');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isMarked
              ? (isPresent ? AppColors.presentBorder.withOpacity(0.4) : AppColors.absentBorder.withOpacity(0.4))
              : AppColors.borderLight,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              badgeText,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: badgeTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
