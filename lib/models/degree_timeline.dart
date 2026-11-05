/// Fall/Spring timeline only; no course requirements are inferred from elapsed time.
class DegreeTimeline {
  const DegreeTimeline({
    required this.programYears,
    required this.startYear,
    required this.startsInFall,
    required this.currentSemester,
  });
  final int programYears;
  final int startYear;
  final bool startsInFall;
  final int currentSemester;
  int get totalSemesters => programYears * 2;
  int get semestersAfterCurrent => totalSemesters - currentSemester;
  String semesterLabel(int semester) {
    final offset = (startsInFall ? 1 : 0) + semester - 1;
    final season = offset.isOdd ? 'Fall' : 'Spring';
    return '$season ${startYear + offset ~/ 2}';
  }

  List<String> get semesterNames =>
      List.generate(totalSemesters, (i) => semesterLabel(i + 1));
}
