// ============================================================
// StudyLock — GPA Models
// ============================================================

enum LetterGrade { aPlus, a, aMinus, bPlus, b, bMinus, cPlus, c, cMinus, dPlus, d, f }

extension LetterGradeX on LetterGrade {
  String get label => switch (this) {
    LetterGrade.aPlus => 'A+',
    LetterGrade.a => 'A',
    LetterGrade.aMinus => 'A-',
    LetterGrade.bPlus => 'B+',
    LetterGrade.b => 'B',
    LetterGrade.bMinus => 'B-',
    LetterGrade.cPlus => 'C+',
    LetterGrade.c => 'C',
    LetterGrade.cMinus => 'C-',
    LetterGrade.dPlus => 'D+',
    LetterGrade.d => 'D',
    LetterGrade.f => 'F',
  };

  double get gradePoints => switch (this) {
    LetterGrade.aPlus => 4.0,
    LetterGrade.a => 4.0,
    LetterGrade.aMinus => 3.7,
    LetterGrade.bPlus => 3.3,
    LetterGrade.b => 3.0,
    LetterGrade.bMinus => 2.7,
    LetterGrade.cPlus => 2.3,
    LetterGrade.c => 2.0,
    LetterGrade.cMinus => 1.7,
    LetterGrade.dPlus => 1.3,
    LetterGrade.d => 1.0,
    LetterGrade.f => 0.0,
  };

  static LetterGrade fromMarks(double percentage) {
    if (percentage >= 97) return LetterGrade.aPlus;
    if (percentage >= 93) return LetterGrade.a;
    if (percentage >= 90) return LetterGrade.aMinus;
    if (percentage >= 87) return LetterGrade.bPlus;
    if (percentage >= 83) return LetterGrade.b;
    if (percentage >= 80) return LetterGrade.bMinus;
    if (percentage >= 77) return LetterGrade.cPlus;
    if (percentage >= 73) return LetterGrade.c;
    if (percentage >= 70) return LetterGrade.cMinus;
    if (percentage >= 67) return LetterGrade.dPlus;
    if (percentage >= 60) return LetterGrade.d;
    return LetterGrade.f;
  }
}

class CourseGrade {
  final String courseId;
  final String courseName;
  final String subject;
  final int creditHours;
  final LetterGrade grade;
  final double marks;
  final double totalMarks;
  final int semester;

  const CourseGrade({
    required this.courseId,
    required this.courseName,
    required this.subject,
    required this.creditHours,
    required this.grade,
    required this.marks,
    required this.totalMarks,
    required this.semester,
  });

  double get percentage => totalMarks > 0 ? (marks / totalMarks * 100) : 0;
  double get gradePoints => grade.gradePoints;
  double get qualityPoints => gradePoints * creditHours;

  factory CourseGrade.fromQuizAttempts({
    required String courseId,
    required String courseName,
    required String subject,
    required int creditHours,
    required int semester,
    required double totalMarks,
    required double earnedMarks,
  }) {
    final pct = totalMarks > 0 ? earnedMarks / totalMarks * 100 : 0.0;
    return CourseGrade(
      courseId: courseId,
      courseName: courseName,
      subject: subject,
      creditHours: creditHours,
      grade: LetterGradeX.fromMarks(pct),
      marks: earnedMarks,
      totalMarks: totalMarks,
      semester: semester,
    );
  }
}

class SemesterGPA {
  final int semester;
  final List<CourseGrade> courses;

  const SemesterGPA({required this.semester, required this.courses});

  int get totalCreditHours => courses.fold(0, (sum, c) => sum + c.creditHours);
  double get totalQualityPoints => courses.fold(0.0, (sum, c) => sum + c.qualityPoints);

  double get gpa {
    if (totalCreditHours == 0) return 0.0;
    return (totalQualityPoints / totalCreditHours).clamp(0, 4.0);
  }

  String get semesterLabel {
    final mod = semester % 3;
    if (mod == 1) return 'Fall ${2022 + semester ~/ 3}';
    if (mod == 2) return 'Spring ${2022 + semester ~/ 3}';
    return 'Summer ${2022 + semester ~/ 3}';
  }
}

class GPASummary {
  final List<SemesterGPA> semesters;

  const GPASummary({required this.semesters});

  int get totalCreditHours => semesters.fold(0, (s, sem) => s + sem.totalCreditHours);
  double get totalQualityPoints => semesters.fold(0.0, (s, sem) => s + sem.totalQualityPoints);

  double get cgpa {
    if (totalCreditHours == 0) return 0.0;
    return (totalQualityPoints / totalCreditHours).clamp(0, 4.0);
  }

  SemesterGPA? get latestSemester => semesters.isEmpty ? null : semesters.last;

  String get cgpaClassification {
    if (cgpa >= 3.7) return 'Distinction';
    if (cgpa >= 3.0) return 'Merit';
    if (cgpa >= 2.0) return 'Pass';
    return 'Fail';
  }
}
