import '../models/academic_models.dart';
import 'student_data_source.dart';

/// Clearly synthetic records for building and demonstrating the app shell.
/// These are not LSU curriculum or degree-audit data.
class DemoStudentDataSource implements StudentDataSource {
  final List<CourseRecord> _courses = [
    const CourseRecord(code: 'ENGL 1001', title: 'English Composition', credits: 3, status: CourseStatus.completed, term: 'Fall 2024'),
    const CourseRecord(code: 'MATH 1550', title: 'Calculus I', credits: 5, status: CourseStatus.completed, term: 'Fall 2024'),
    const CourseRecord(code: 'CMST 1061', title: 'Communication Studies', credits: 3, status: CourseStatus.completed, term: 'Spring 2025'),
    const CourseRecord(code: 'CSC 1350', title: 'Introduction to Computer Science', credits: 3, status: CourseStatus.completed, term: 'Spring 2025'),
    const CourseRecord(code: 'MATH 1552', title: 'Calculus II', credits: 4, status: CourseStatus.completed, term: 'Fall 2025'),
    const CourseRecord(code: 'GEN 1000', title: 'General Education Elective', credits: 3, status: CourseStatus.inProgress, term: 'Fall 2026'),
  ];

  @override
  StudentProfile get student => StudentProfile(
        name: 'Alex Morgan',
        major: 'Computer Science',
        college: 'College of Engineering',
        targetGraduation: 'Spring 2028',
        requiredCredits: 120,
        courses: List.unmodifiable(_courses),
      );

  @override
  Future<void> addCourse(CourseRecord course) async {
    _courses.add(course);
  }
}
