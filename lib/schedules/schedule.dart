/// UI-only records, separate from verified degree requirements and planning.
class ScheduleClass {
  ScheduleClass({required this.name, this.time = ''});
  final String name;
  final String time;
}

class SemesterSchedule {
  SemesterSchedule({required this.name, required this.classes});
  final String name;
  final List<ScheduleClass> classes;
}
