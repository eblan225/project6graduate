enum CourseStatus { completed, inProgress, planned }

class CourseRecord {
  const CourseRecord({
    required this.code,
    required this.title,
    required this.credits,
    required this.status,
    this.term,
  });

  final String code;
  final String title;
  final int credits;
  final CourseStatus status;
  final String? term;
}

class StudentProfile {
  const StudentProfile({
    required this.name,
    required this.major,
    required this.college,
    required this.targetGraduation,
    required this.requiredCredits,
    required this.courses,
  });

  final String name;
  final String major;
  final String college;
  final String targetGraduation;
  final int requiredCredits;
  final List<CourseRecord> courses;

  int get completedCredits => courses
      .where((course) => course.status == CourseStatus.completed)
      .fold(0, (sum, course) => sum + course.credits);

  int get inProgressCredits => courses
      .where((course) => course.status == CourseStatus.inProgress)
      .fold(0, (sum, course) => sum + course.credits);

  int get earnedOrInProgressCredits => completedCredits + inProgressCredits;

  int get remainingCredits => (requiredCredits - earnedOrInProgressCredits)
      .clamp(0, requiredCredits)
      .toInt();

  double get completionFraction => requiredCredits == 0
      ? 0
      : (earnedOrInProgressCredits / requiredCredits).clamp(0, 1).toDouble();

  int get minimumCreditsPerTerm {
    const remainingTerms = 3;
    if (remainingCredits == 0) return 0;
    return (remainingCredits / remainingTerms).ceil();
  }
}
