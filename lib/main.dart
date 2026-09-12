import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'services/database_service.dart';
import 'state/auth_provider.dart';
import 'state/student_provider.dart';
import 'state/attendance_provider.dart';
import 'theme/app_theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/tutor/tutor_navigation_shell.dart';
import 'screens/parent/parent_navigation_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final authService = AuthService();
  final dbService = DatabaseService();

  await authService.initialize();
  await dbService.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(authService)),
        ChangeNotifierProvider(create: (_) => StudentProvider(dbService)),
        ChangeNotifierProvider(create: (_) => AttendanceProvider(dbService)),
      ],
      child: const AttendanceApp(),
    ),
  );
}

class AttendanceApp extends StatelessWidget {
  const AttendanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Attendance Management',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (!auth.isAuthenticated) {
      return const LoginScreen();
    }

    if (auth.isTutor) {
      return const TutorNavigationShell();
    }

    return const ParentNavigationShell();
  }
}
