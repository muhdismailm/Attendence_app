import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'parent_home_screen.dart';
import 'parent_attendance_screen.dart';
import 'parent_profile_screen.dart';

class ParentNavigationShell extends StatefulWidget {
  const ParentNavigationShell({super.key});

  @override
  State<ParentNavigationShell> createState() => _ParentNavigationShellState();
}

class _ParentNavigationShellState extends State<ParentNavigationShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      ParentHomeScreen(
        onNavigateToAttendance: () {
          setState(() {
            _currentIndex = 1;
          });
        },
      ),
      const ParentAttendanceScreen(),
      const ParentProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          selectedItemColor: AppColors.primaryBlue,
          unselectedItemColor: AppColors.textSecondary,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month_outlined),
              activeIcon: Icon(Icons.calendar_month_rounded),
              label: 'Attendance',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.more_horiz_rounded),
              activeIcon: Icon(Icons.more_horiz_rounded),
              label: 'More',
            ),
          ],
        ),
      ),
    );
  }
}
