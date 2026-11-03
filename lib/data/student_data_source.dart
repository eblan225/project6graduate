import '../models/academic_models.dart';

/// Boundary for student data. Replace the demo implementation with an
/// approved Workday import or integration without coupling screens to it.
abstract interface class StudentDataSource {
  StudentProfile get student;
  Future<void> addCourse(CourseRecord course);
}
