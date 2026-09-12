import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'tutor_home_screen.dart';
import 'students_screen.dart';
import 'tutor_reports_screen.dart';
import 'tutor_profile_screen.dart';

class TutorNavigationShell extends StatefulWidget {
  const TutorNavigationShell({super.key});

  @override
  State<TutorNavigationShell> createState() => _TutorNavigationShellState();
}

class _TutorNavigationShellState extends State<TutorNavigationShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    TutorHomeScreen(),
    StudentsScreen(),
    TutorReportsScreen(),
    TutorProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
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
              icon: Icon(Icons.people_outline_rounded),
              activeIcon: Icon(Icons.people_rounded),
              label: 'Students',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assessment_outlined),
              activeIcon: Icon(Icons.assessment_rounded),
              label: 'Reports',
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
