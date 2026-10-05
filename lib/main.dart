import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/database_service.dart';
import 'services/firebase_service.dart';
import 'state/auth_provider.dart';
import 'state/student_provider.dart';
import 'state/attendance_provider.dart';
import 'theme/app_theme.dart';
import 'theme/app_colors.dart';
import 'screens/auth/login_screen.dart';
import 'screens/tutor/tutor_navigation_shell.dart';
import 'screens/parent/parent_navigation_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with platform-specific options
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization note: $e');
  }

  final authService = AuthService();
  final dbService = DatabaseService();
  final firebaseService = FirebaseService();

  await authService.initialize();
  await dbService.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(authService)),
        ChangeNotifierProxyProvider<AuthProvider, StudentProvider>(
          create: (_) => StudentProvider(dbService, firebaseService),
          update: (_, authProvider, studentProvider) {
            return studentProvider!..updateAuthProvider(authProvider);
          },
        ),
        ChangeNotifierProxyProvider<StudentProvider, AttendanceProvider>(
          create: (_) => AttendanceProvider(dbService),
          update: (_, studentProvider, attendanceProvider) {
            final attProv = attendanceProvider!..updateStudentProvider(studentProvider);
            studentProvider.updateAttendanceProvider(attProv);
            return attProv;
          },
        ),
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

    if (auth.isLoading && !auth.isAuthenticated) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryBlue),
        ),
      );
    }

    if (!auth.isAuthenticated) {
      return const LoginScreen();
    }

    if (auth.isTutor) {
      return const TutorNavigationShell();
    }

    return const ParentNavigationShell();
  }
}
