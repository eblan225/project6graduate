String courseDisplayId(String id) =>
    RegExp(r'^PDF\d*-?SLOT\d*$', caseSensitive: false).hasMatch(id)
    ? '(Class TBD)'
    : id;

class TemplateCourse {
  const TemplateCourse(
    this.id,
    this.title,
    this.credits,
    this.semester, {
    this.minimumC = false,
    this.offered,
    this.choices = const [],
  });
  final String id, title;
  final int credits, semester;
  final bool minimumC;
  final String? offered;
  final List<String> choices;
}

class CourseLink {
  const CourseLink(this.from, this.to, {this.concurrent = false});
  final String from, to;
  final bool concurrent;
}

/// Transcribed from the user-provided 2026–27 EEC advising flowchart.
/// Elective slots are requirements, not claims about approved elective choices.
const eecCourses = <TemplateCourse>[
  TemplateCourse('CHEM 1201', 'Basic Chemistry', 3, 1),
  TemplateCourse('MATH 1550', 'Calculus I', 5, 1, minimumC: true),
  TemplateCourse('EE 1820', 'Introduction to ECE', 2, 1),
  TemplateCourse('ART', 'Art general education', 3, 1),
  TemplateCourse('ENGL 1001', 'Composition I', 3, 1, minimumC: true),
  TemplateCourse('EE 2741', 'Digital Logic I', 3, 2, minimumC: true),
  TemplateCourse(
    'CSC 1253',
    'Introduction to Computer Science I',
    3,
    2,
    minimumC: true,
  ),
  TemplateCourse('MATH 1552', 'Calculus II', 4, 2, minimumC: true),
  TemplateCourse('PHYS 2110', 'General Physics I', 3, 2, minimumC: true),
  TemplateCourse('PHYS 2108', 'Physics Laboratory', 1, 2),
  TemplateCourse('LIFE', 'Life science general education', 3, 2),
  TemplateCourse('EE 2742', 'Digital Logic II', 2, 3, minimumC: true),
  TemplateCourse('CSC 1254', 'Introduction to Computer Science II', 3, 3),
  TemplateCourse('MATH 2070', 'Engineering Mathematics', 4, 3, minimumC: true),
  TemplateCourse('EE 2120', 'Circuits I', 3, 3, minimumC: true),
  TemplateCourse('PHYS 2113', 'General Physics III', 3, 3, minimumC: true),
  TemplateCourse('EE 2820', 'Introduction to Design', 2, 4, minimumC: true),
  TemplateCourse('MATH 2057', 'Calculus III', 3, 4, minimumC: true),
  TemplateCourse('EE 2130', 'Circuits II', 3, 4, minimumC: true),
  TemplateCourse('EE 2230', 'Electronics I', 3, 4),
  TemplateCourse('EE 2231', 'Electronics I Laboratory', 2, 4),
  TemplateCourse('ENGL 2000', 'Composition II', 3, 4, minimumC: true),
  TemplateCourse(
    'EE 3755',
    'Computer Organization',
    3,
    5,
    minimumC: true,
    offered: 'Fall',
  ),
  TemplateCourse(
    'EE 3752',
    'Microprocessors + Laboratory',
    3,
    5,
    minimumC: true,
    offered: 'Fall',
  ),
  TemplateCourse('EE 3150', 'Probability', 3, 5, minimumC: true),
  TemplateCourse(
    'BREADTH',
    'EEC breadth elective',
    3,
    5,
    choices: [
      'EE 3160 · Digital Signal Processing',
      'EE 3220 · Electronics II',
      'EE 3320 · Electromagnetic Fields',
      'EE 3410 · Electric Power',
      'EE 3530 · Controls Engineering',
      'EE 3610 · Signals and Communications',
    ],
  ),
  TemplateCourse('PHIL 2020', 'Ethics', 3, 5),
  TemplateCourse('SOC', 'Social science general education', 3, 5),
  TemplateCourse('EE 3740', 'Discrete Mathematics', 3, 6, offered: 'Spring'),
  TemplateCourse('CSC 3102', 'Advanced Data Structures', 3, 6),
  TemplateCourse(
    'EE 3710',
    'Communications in Computing',
    3,
    6,
    offered: 'Spring',
  ),
  TemplateCourse('SOC2000', '2000+ social science elective', 3, 6),
  TemplateCourse('HUM1', 'Humanities general education I', 3, 6),
  TemplateCourse('EE 4755', 'HDL and Digital Design', 3, 7, offered: 'Fall'),
  TemplateCourse('CSC 4103', 'Operating Systems', 3, 7),
  TemplateCourse(
    'EE 4810',
    'Senior Design I',
    3,
    7,
    minimumC: true,
    offered: 'Fall',
  ),
  TemplateCourse('DESIGN1', 'EEC design elective I', 3, 7),
  TemplateCourse('TECH1', 'Technical elective I', 3, 7),
  TemplateCourse('EE 4720', 'Computer Architecture', 3, 8, offered: 'Spring'),
  TemplateCourse('EE 4820', 'Senior Design II', 3, 8, offered: 'Spring'),
  TemplateCourse('DESIGN2', 'EEC design elective II', 3, 8),
  TemplateCourse('TECH2', 'Technical elective II', 3, 8),
  TemplateCourse('HUM2', 'Humanities general education II', 3, 8),
];

const eecLinks = <CourseLink>[
  CourseLink('MATH 1550', 'EE 2741'),
  CourseLink('MATH 1550', 'CSC 1253', concurrent: true),
  CourseLink('MATH 1550', 'MATH 1552'),
  CourseLink('MATH 1550', 'PHYS 2110'),
  CourseLink('MATH 1552', 'PHYS 2110', concurrent: true),
  CourseLink('PHYS 2110', 'PHYS 2108', concurrent: true),
  CourseLink('MATH 1552', 'MATH 2070'),
  CourseLink('MATH 1552', 'MATH 2057'),
  CourseLink('MATH 1552', 'PHYS 2113'),
  CourseLink('PHYS 2110', 'PHYS 2113'),
  CourseLink('EE 2741', 'EE 2742'),
  CourseLink('CSC 1253', 'EE 2742', concurrent: true),
  CourseLink('CSC 1253', 'CSC 1254'),
  CourseLink('EE 1820', 'EE 2120', concurrent: true),
  CourseLink('MATH 2070', 'EE 2120', concurrent: true),
  CourseLink('PHYS 2113', 'EE 2120', concurrent: true),
  CourseLink('EE 1820', 'EE 2820'),
  CourseLink('EE 2120', 'EE 2820'),
  CourseLink('MATH 2070', 'EE 2130'),
  CourseLink('EE 2120', 'EE 2130'),
  CourseLink('PHYS 2113', 'EE 2130'),
  CourseLink('EE 2120', 'EE 2230'),
  CourseLink('EE 2230', 'EE 2231', concurrent: true),
  CourseLink('ENGL 1001', 'ENGL 2000'),
  CourseLink('MATH 2057', 'EE 3150'),
  CourseLink('EE 2742', 'EE 3755'),
  CourseLink('EE 2742', 'EE 3752'),
  CourseLink('CSC 1253', 'EE 3752'),
  CourseLink('EE 2130', 'BREADTH'),
  CourseLink('EE 2742', 'EE 3740'),
  CourseLink('CSC 1254', 'CSC 3102'),
  CourseLink('EE 2741', 'CSC 3102', concurrent: true),
  CourseLink('EE 2741', 'EE 3710'),
  CourseLink('EE 3150', 'EE 3710', concurrent: true),
  CourseLink('EE 3755', 'EE 4755'),
  CourseLink('CSC 3102', 'CSC 4103'),
  CourseLink('EE 2820', 'EE 4810'),
  CourseLink('EE 3752', 'EE 4810'),
  CourseLink('EE 2742', 'EE 4720'),
  CourseLink('EE 3755', 'EE 4720'),
  CourseLink('EE 3752', 'EE 4720'),
  CourseLink('EE 4810', 'EE 4820'),
];
