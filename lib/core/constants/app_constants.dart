import 'package:flutter/material.dart';

class AppConstants {
  static const appName = 'StudyLock';
  static const maxViolations = 3;
  static const violationCooldownSeconds = 8;
  static const faceYawThreshold = 45.0;
  static const eyeOpenThreshold = 0.3;
  static const detectionIntervalSeconds = 6;
  static const xpPerMinute = 2;
  static const xpPerLevel = 500;

  static const blockedApps = [
    'Instagram', 'TikTok', 'YouTube', 'Facebook',
    'Snapchat', 'Twitter/X', 'Discord', 'WhatsApp',
    'Reddit', 'Netflix', 'Spotify', 'Telegram',
    'Pinterest', 'LinkedIn',
  ];
}

class AppRoutes {
  static const loading = '/loading';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const studentHome = '/student';
  static const studentAcademic = '/student/academic';
  static const studentSession = '/student/session';
  static const studentRewards = '/student/rewards';
  static const studentProfile = '/student/profile';
  static const lectureDetail = '/lecture/:id';
  static const assignmentDetail = '/assignment/:id';
  static const quizAttempt = '/quiz/:id';
  static const quizResult = '/quiz-result/:attemptId';
  static const sessionActive = '/session-active';
  static const sessionResult = '/session-result';
  static const lecturerHome = '/lecturer';
  static const lecturerManage = '/lecturer/manage';
  static const lecturerProfile = '/lecturer/profile';
  static const createContent = '/create-content';
  static const gradeSubmission = '/grade-submission/:id';
  static const adminHome = '/admin';
  static const adminUsers = '/admin/users';
  static const adminCourses = '/admin/courses';
  static const settings = '/settings';
  // Phase 2+
  static const attendance = '/attendance';
  static const attendanceReport = '/attendance-report';
  static const gpa = '/gpa';
  static const analytics = '/analytics';
  static const ranking = '/ranking';
  static const timetable = '/timetable';
  static const aiTutor = '/ai-tutor';
  static const parentPortal = '/parent-portal';
  static const lecturerPerformance = '/lecturer-performance';
}

class AppGradients {
  static const primary = LinearGradient(
    colors: [Color(0xFF5B8FF9), Color(0xFF7B6FEF)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const success = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const danger = LinearGradient(
    colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
}
