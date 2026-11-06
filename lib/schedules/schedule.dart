/// UI-only records, separate from verified degree requirements and planning.
class ScheduleClass {
  ScheduleClass({required this.name, this.time = ''});
  final String name;
  final String time;

  Map<String, Object?> toJson() => {'name': name, 'time': time};

  factory ScheduleClass.fromJson(Map<String, Object?> json) {
    final name = json['name'];
    final time = json['time'];
    if (name is! String || name.trim().isEmpty || time is! String) {
      throw const FormatException('Invalid saved class entry.');
    }
    return ScheduleClass(name: name, time: time);
  }
}

class SemesterSchedule {
  SemesterSchedule({required this.name, required this.classes});
  final String name;
  final List<ScheduleClass> classes;

  Map<String, Object?> toJson() => {
    'name': name,
    'classes': classes.map((course) => course.toJson()).toList(),
  };

  factory SemesterSchedule.fromJson(Map<String, Object?> json) {
    final name = json['name'];
    final classes = json['classes'];
    if (name is! String || name.trim().isEmpty || classes is! List) {
      throw const FormatException('Invalid saved semester schedule.');
    }
    return SemesterSchedule(
      name: name,
      classes: classes.map((value) {
        if (value is! Map) {
          throw const FormatException('Invalid saved class entry.');
        }
        return ScheduleClass.fromJson(Map<String, Object?>.from(value));
      }).toList(),
    );
  }
}
