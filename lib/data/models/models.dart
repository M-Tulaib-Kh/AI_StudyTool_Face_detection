// ============================================================
// StudyLock — All Dart Models (matching Supabase schema exactly)
// ============================================================

// ─── UserRole enum ───────────────────────────────────────────
enum UserRole { student, lecturer, admin }

extension UserRoleX on UserRole {
  String get value => name;
  static UserRole from(String s) =>
      UserRole.values.firstWhere((e) => e.name == s, orElse: () => UserRole.student);
}

// ─── Profile ─────────────────────────────────────────────────
class UserProfile {
  final String id;
  final String email;
  final String fullName;
  final String? avatarUrl;
  final String? department;
  final String? registrationNo;
  final String? designation;
  final UserRole role;
  final DateTime createdAt;

  const UserProfile({
    required this.id,
    required this.email,
    required this.fullName,
    this.avatarUrl,
    this.department,
    this.registrationNo,
    this.designation,
    required this.role,
    required this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json, UserRole role) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
      department: json['department'] as String?,
      registrationNo: json['registration_no'] as String?,
      designation: json['designation'] as String?,
      role: role,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'full_name': fullName,
    'avatar_url': avatarUrl,
    'department': department,
    'registration_no': registrationNo,
    'designation': designation,
    'updated_at': DateTime.now().toIso8601String(),
  };

  UserProfile copyWith({
    String? fullName,
    String? avatarUrl,
    String? department,
    String? registrationNo,
    String? designation,
    UserRole? role,
  }) => UserProfile(
    id: id, email: email, createdAt: createdAt,
    fullName: fullName ?? this.fullName,
    avatarUrl: avatarUrl ?? this.avatarUrl,
    department: department ?? this.department,
    registrationNo: registrationNo ?? this.registrationNo,
    designation: designation ?? this.designation,
    role: role ?? this.role,
  );
}

// ─── Course ──────────────────────────────────────────────────
class Course {
  final String id;
  final String title;
  final String description;
  final String subject;
  final String? lecturerId;
  final String lecturerName;
  final DateTime createdAt;

  const Course({
    required this.id,
    required this.title,
    required this.description,
    required this.subject,
    this.lecturerId,
    required this.lecturerName,
    required this.createdAt,
  });

  factory Course.fromJson(Map<String, dynamic> j) => Course(
    id: j['id'] as String,
    title: j['title'] as String,
    description: j['description'] as String? ?? '',
    subject: j['subject'] as String? ?? '',
    lecturerId: j['lecturer_id'] as String?,
    lecturerName: j['lecturer_name'] as String? ?? '',
    createdAt: DateTime.parse(j['created_at'] as String),
  );

  Map<String, dynamic> toInsertJson() => {
    'title': title,
    'description': description,
    'subject': subject,
    'lecturer_id': lecturerId,
    'lecturer_name': lecturerName,
  };
}

// ─── Lecture ─────────────────────────────────────────────────
class Lecture {
  final String id;
  final String? courseId;
  final String title;
  final String subject;
  final String description;
  final String fileUrl;
  final String fileName;
  final String uploadedBy;
  final int views;
  final DateTime createdAt;

  const Lecture({
    required this.id,
    this.courseId,
    required this.title,
    required this.subject,
    required this.description,
    required this.fileUrl,
    required this.fileName,
    required this.uploadedBy,
    required this.views,
    required this.createdAt,
  });

  factory Lecture.fromJson(Map<String, dynamic> j) => Lecture(
    id: j['id'] as String,
    courseId: j['course_id'] as String?,
    title: j['title'] as String,
    subject: j['subject'] as String? ?? '',
    description: j['description'] as String? ?? '',
    fileUrl: j['file_url'] as String? ?? '',
    fileName: j['file_name'] as String? ?? '',
    uploadedBy: j['uploaded_by'] as String,
    views: j['views'] as int? ?? 0,
    createdAt: DateTime.parse(j['created_at'] as String),
  );

  Map<String, dynamic> toInsertJson() => {
    'course_id': courseId,
    'title': title,
    'subject': subject,
    'description': description,
    'file_url': fileUrl,
    'file_name': fileName,
    'uploaded_by': uploadedBy,
  };
}

// ─── Assignment ──────────────────────────────────────────────
class Assignment {
  final String id;
  final String? courseId;
  final String title;
  final String subject;
  final String description;
  final String instructions;
  final String fileUrl;
  final String fileName;
  final DateTime deadline;
  final int totalMarks;
  final String createdBy;
  final bool aiGenerated;
  final DateTime createdAt;

  const Assignment({
    required this.id,
    this.courseId,
    required this.title,
    required this.subject,
    required this.description,
    required this.instructions,
    required this.fileUrl,
    required this.fileName,
    required this.deadline,
    required this.totalMarks,
    required this.createdBy,
    required this.aiGenerated,
    required this.createdAt,
  });

  factory Assignment.fromJson(Map<String, dynamic> j) => Assignment(
    id: j['id'] as String,
    courseId: j['course_id'] as String?,
    title: j['title'] as String,
    subject: j['subject'] as String? ?? '',
    description: j['description'] as String? ?? '',
    instructions: j['instructions'] as String? ?? '',
    fileUrl: j['file_url'] as String? ?? '',
    fileName: j['file_name'] as String? ?? '',
    deadline: DateTime.parse(j['deadline'] as String),
    totalMarks: j['total_marks'] as int? ?? 100,
    createdBy: j['created_by'] as String,
    aiGenerated: j['ai_generated'] as bool? ?? false,
    createdAt: DateTime.parse(j['created_at'] as String),
  );

  int get daysUntilDeadline =>
      deadline.difference(DateTime.now()).inDays;
  bool get isOverdue => deadline.isBefore(DateTime.now());
}

// ─── Submission ──────────────────────────────────────────────
enum SubmissionStatus { submitted, late, graded }

extension SubmissionStatusX on SubmissionStatus {
  static SubmissionStatus from(String s) =>
      SubmissionStatus.values.firstWhere((e) => e.name == s,
          orElse: () => SubmissionStatus.submitted);
}

class Submission {
  final String id;
  final String assignmentId;
  final String studentId;
  final String studentName;
  final String fileUrl;
  final String fileName;
  final DateTime submittedAt;
  final SubmissionStatus status;
  final int? marksObtained;
  final String? feedback;
  final String? gradedBy;

  const Submission({
    required this.id,
    required this.assignmentId,
    required this.studentId,
    required this.studentName,
    required this.fileUrl,
    required this.fileName,
    required this.submittedAt,
    required this.status,
    this.marksObtained,
    this.feedback,
    this.gradedBy,
  });

  factory Submission.fromJson(Map<String, dynamic> j) => Submission(
    id: j['id'] as String,
    assignmentId: j['assignment_id'] as String,
    studentId: j['student_id'] as String,
    studentName: j['student_name'] as String? ?? '',
    fileUrl: j['file_url'] as String? ?? '',
    fileName: j['file_name'] as String? ?? '',
    submittedAt: DateTime.parse(j['submitted_at'] as String),
    status: SubmissionStatusX.from(j['status'] as String? ?? 'submitted'),
    marksObtained: j['marks_obtained'] as int?,
    feedback: j['feedback'] as String?,
    gradedBy: j['graded_by'] as String?,
  );
}

// ─── QuizQuestion ─────────────────────────────────────────────
class QuizQuestion {
  final String id;
  final String questionText;
  final String optionA;
  final String optionB;
  final String optionC;
  final String optionD;
  final String correctAnswer; // 'A'|'B'|'C'|'D'
  final int marks;

  const QuizQuestion({
    required this.id,
    required this.questionText,
    required this.optionA,
    required this.optionB,
    required this.optionC,
    required this.optionD,
    required this.correctAnswer,
    required this.marks,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> j) => QuizQuestion(
    id: j['id'] as String? ?? '',
    questionText: j['questionText'] as String? ?? '',
    optionA: j['optionA'] as String? ?? '',
    optionB: j['optionB'] as String? ?? '',
    optionC: j['optionC'] as String? ?? '',
    optionD: j['optionD'] as String? ?? '',
    correctAnswer: j['correctAnswer'] as String? ?? 'A',
    marks: (j['marks'] as num?)?.toInt() ?? 1,
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'questionText': questionText,
    'optionA': optionA, 'optionB': optionB,
    'optionC': optionC, 'optionD': optionD,
    'correctAnswer': correctAnswer, 'marks': marks,
  };

  String optionText(String opt) {
    return switch (opt) {
      'A' => optionA, 'B' => optionB,
      'C' => optionC, 'D' => optionD,
      _ => '',
    };
  }
}

// ─── Quiz ─────────────────────────────────────────────────────
class Quiz {
  final String id;
  final String? courseId;
  final String title;
  final String subject;
  final String description;
  final List<QuizQuestion> questions;
  final int durationMinutes;
  final int totalMarks;
  final DateTime? deadline;
  final String createdBy;
  final bool aiGenerated;
  final DateTime createdAt;

  const Quiz({
    required this.id,
    this.courseId,
    required this.title,
    required this.subject,
    required this.description,
    required this.questions,
    required this.durationMinutes,
    required this.totalMarks,
    this.deadline,
    required this.createdBy,
    required this.aiGenerated,
    required this.createdAt,
  });

  factory Quiz.fromJson(Map<String, dynamic> j) {
    final rawQ = j['questions'];
    final List<QuizQuestion> qs = rawQ is List
        ? rawQ.map((q) => QuizQuestion.fromJson(q as Map<String, dynamic>)).toList()
        : [];
    return Quiz(
      id: j['id'] as String,
      courseId: j['course_id'] as String?,
      title: j['title'] as String,
      subject: j['subject'] as String? ?? '',
      description: j['description'] as String? ?? '',
      questions: qs,
      durationMinutes: j['duration_minutes'] as int? ?? 15,
      totalMarks: j['total_marks'] as int? ?? 10,
      deadline: j['deadline'] != null ? DateTime.parse(j['deadline'] as String) : null,
      createdBy: j['created_by'] as String,
      aiGenerated: j['ai_generated'] as bool? ?? false,
      createdAt: DateTime.parse(j['created_at'] as String),
    );
  }
}

// ─── QuizAttempt ──────────────────────────────────────────────
class QuizAttempt {
  final String id;
  final String quizId;
  final String studentId;
  final String studentName;
  final Map<String, String> answers; // questionId -> optionLetter
  final int score;
  final int totalMarks;
  final String status;
  final String? aiFeedback;
  final bool aiEvaluated;
  final DateTime createdAt;

  const QuizAttempt({
    required this.id,
    required this.quizId,
    required this.studentId,
    required this.studentName,
    required this.answers,
    required this.score,
    required this.totalMarks,
    required this.status,
    this.aiFeedback,
    required this.aiEvaluated,
    required this.createdAt,
  });

  factory QuizAttempt.fromJson(Map<String, dynamic> j) {
    final raw = j['answers'];
    final Map<String, String> ans = raw is Map
        ? raw.map((k, v) => MapEntry(k.toString(), v.toString()))
        : {};
    return QuizAttempt(
      id: j['id'] as String,
      quizId: j['quiz_id'] as String,
      studentId: j['student_id'] as String,
      studentName: j['student_name'] as String? ?? '',
      answers: ans,
      score: j['score'] as int? ?? 0,
      totalMarks: j['total_marks'] as int? ?? 10,
      status: j['status'] as String? ?? 'submitted',
      aiFeedback: j['ai_feedback'] as String?,
      aiEvaluated: j['ai_evaluated'] as bool? ?? false,
      createdAt: DateTime.parse(j['created_at'] as String),
    );
  }
}

// ─── StudySession ─────────────────────────────────────────────
enum SessionStatus { active, completed, failed }

class StudySession {
  final String id;
  final String userId;
  final int plannedDurationSeconds;
  final int elapsedSeconds;
  final SessionStatus status;
  final int violations;
  final bool cameraEnabled;
  final bool validSession;
  final List<String> blockedApps;
  final DateTime startedAt;
  final DateTime? endedAt;

  const StudySession({
    required this.id,
    required this.userId,
    required this.plannedDurationSeconds,
    required this.elapsedSeconds,
    required this.status,
    required this.violations,
    required this.cameraEnabled,
    required this.validSession,
    required this.blockedApps,
    required this.startedAt,
    this.endedAt,
  });

  factory StudySession.fromJson(Map<String, dynamic> j) {
    final apps = j['blocked_apps'];
    return StudySession(
      id: j['id'] as String,
      userId: j['user_id'] as String,
      plannedDurationSeconds: j['planned_duration_seconds'] as int,
      elapsedSeconds: j['elapsed_seconds'] as int? ?? 0,
      status: SessionStatus.values.firstWhere(
        (s) => s.name == j['status'],
        orElse: () => SessionStatus.completed,
      ),
      violations: j['violations'] as int? ?? 0,
      cameraEnabled: j['camera_enabled'] as bool? ?? false,
      validSession: j['valid_session'] as bool? ?? false,
      blockedApps: apps is List ? apps.cast<String>() : [],
      startedAt: DateTime.parse(j['started_at'] as String),
      endedAt: j['ended_at'] != null ? DateTime.parse(j['ended_at'] as String) : null,
    );
  }

  double get efficiency => violations == 0 ? 1.0 : (1.0 - (violations / 3)).clamp(0, 1);
}

// ─── Badge ────────────────────────────────────────────────────
class Badge {
  final String id;
  final String name;
  final String description;
  final String icon;
  final bool unlocked;
  final DateTime? unlockedAt;

  const Badge({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.unlocked,
    this.unlockedAt,
  });

  factory Badge.fromJson(Map<String, dynamic> j) => Badge(
    id: j['id'] as String,
    name: j['name'] as String,
    description: j['description'] as String,
    icon: j['icon'] as String,
    unlocked: j['unlocked'] as bool? ?? false,
    unlockedAt: j['unlockedAt'] != null ? DateTime.tryParse(j['unlockedAt'] as String) : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'description': description,
    'icon': icon, 'unlocked': unlocked,
    if (unlockedAt != null) 'unlockedAt': unlockedAt!.toIso8601String(),
  };

  Badge copyWith({bool? unlocked, DateTime? unlockedAt}) => Badge(
    id: id, name: name, description: description, icon: icon,
    unlocked: unlocked ?? this.unlocked,
    unlockedAt: unlockedAt ?? this.unlockedAt,
  );
}

// ─── Challenge ────────────────────────────────────────────────
class Challenge {
  final String id;
  final String title;
  final String description;
  final int target;
  final int current;
  final String unit;
  final int reward;
  final bool completed;

  const Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.target,
    required this.current,
    required this.unit,
    required this.reward,
    required this.completed,
  });

  factory Challenge.fromJson(Map<String, dynamic> j) => Challenge(
    id: j['id'] as String,
    title: j['title'] as String,
    description: j['description'] as String,
    target: (j['target'] as num).toInt(),
    current: (j['current'] as num).toInt(),
    unit: j['unit'] as String,
    reward: (j['reward'] as num).toInt(),
    completed: j['completed'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'title': title, 'description': description,
    'target': target, 'current': current,
    'unit': unit, 'reward': reward, 'completed': completed,
  };

  double get progress => (current / target).clamp(0, 1);

  Challenge copyWith({int? current, bool? completed}) => Challenge(
    id: id, title: title, description: description,
    target: target, unit: unit, reward: reward,
    current: current ?? this.current,
    completed: completed ?? this.completed,
  );
}

// ─── GameState ───────────────────────────────────────────────
class GameState {
  final String userId;
  final int points;
  final int streak;
  final int longestStreak;
  final DateTime? lastSessionDate;
  final List<Badge> badges;
  final List<Challenge> challenges;

  const GameState({
    required this.userId,
    required this.points,
    required this.streak,
    required this.longestStreak,
    this.lastSessionDate,
    required this.badges,
    required this.challenges,
  });

  int get level => (points ~/ 500) + 1;
  int get nextLevelPoints => level * 500;
  double get levelProgress => (points % 500) / 500;

  factory GameState.fromJson(Map<String, dynamic> j) {
    final rawB = j['badges'] as List? ?? [];
    final rawC = j['challenges'] as List? ?? [];
    return GameState(
      userId: j['user_id'] as String,
      points: j['points'] as int? ?? 0,
      streak: j['streak'] as int? ?? 0,
      longestStreak: j['longest_streak'] as int? ?? 0,
      lastSessionDate: j['last_session_date'] != null
          ? DateTime.tryParse(j['last_session_date'] as String)
          : null,
      badges: rawB.map((b) => Badge.fromJson(b as Map<String, dynamic>)).toList(),
      challenges: rawC.map((c) => Challenge.fromJson(c as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toUpdateJson() => {
    'points': points,
    'streak': streak,
    'longest_streak': longestStreak,
    'last_session_date': lastSessionDate?.toIso8601String().split('T')[0],
    'badges': badges.map((b) => b.toJson()).toList(),
    'challenges': challenges.map((c) => c.toJson()).toList(),
    'updated_at': DateTime.now().toIso8601String(),
  };
}

// ─── AppNotification ─────────────────────────────────────────
class AppNotification {
  final String id;
  final String userId;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
    id: j['id'] as String,
    userId: j['user_id'] as String,
    title: j['title'] as String,
    message: j['message'] as String,
    type: j['type'] as String? ?? 'info',
    isRead: j['is_read'] as bool? ?? false,
    createdAt: DateTime.parse(j['created_at'] as String),
  );
}

// ─── LoginEvent ───────────────────────────────────────────────
class LoginEvent {
  final int id;
  final String userId;
  final String role;
  final String email;
  final String name;
  final String? deviceInfo;
  final DateTime loggedInAt;

  const LoginEvent({
    required this.id,
    required this.userId,
    required this.role,
    required this.email,
    required this.name,
    this.deviceInfo,
    required this.loggedInAt,
  });

  factory LoginEvent.fromJson(Map<String, dynamic> j) => LoginEvent(
    id: j['id'] as int,
    userId: j['user_id'] as String,
    role: j['role'] as String,
    email: j['email'] as String,
    name: j['name'] as String,
    deviceInfo: j['device_info'] as String?,
    loggedInAt: DateTime.parse(j['logged_in_at'] as String),
  );
}
