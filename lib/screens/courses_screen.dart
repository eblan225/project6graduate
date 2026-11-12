import 'package:material_ui/material_ui.dart';

import '../data/student_data_source.dart';
import '../main.dart';
import '../models/academic_models.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({
    super.key,
    required this.dataSource,
    required this.onChanged,
  });
  final StudentDataSource dataSource;
  final VoidCallback onChanged;

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  CourseStatus filter = CourseStatus.completed;

  @override
  Widget build(BuildContext context) {
    final student = widget.dataSource.student;
    final courses = student.courses
        .where((course) => course.status == filter)
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('My courses'),
        actions: [
          IconButton(
            onPressed: _showImportInfo,
            icon: const Icon(Icons.file_download_outlined),
            tooltip: 'Import from Workday',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          Text(
            'Keep your academic record up to date.',
            style: Theme.of(context).textTheme.bodyLarge
                ?.copyWith(color: Colors.black54),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _CreditSummary(
                  label: 'Completed',
                  credits: student.completedCredits,
                  icon: Icons.check_circle_outline,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _CreditSummary(
                  label: 'In progress',
                  credits: student.inProgressCredits,
                  icon: Icons.timelapse,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF0EAF7),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.sync_alt, color: Color(0xFF461D7C)),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Workday connection is not configured yet. You can add sample entries while integration is being prepared.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
                TextButton(
                  onPressed: _showImportInfo,
                  child: const Text('Details'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SegmentedButton<CourseStatus>(
            segments: const [
              ButtonSegment(
                value: CourseStatus.completed,
                label: Text('Completed'),
              ),
              ButtonSegment(
                value: CourseStatus.inProgress,
                label: Text('Current'),
              ),
              ButtonSegment(
                value: CourseStatus.planned,
                label: Text('Planned'),
              ),
            ],
            selected: {filter},
            onSelectionChanged: (value) => setState(() => filter = value.first),
            showSelectedIcon: false,
          ),
          const SizedBox(height: 12),
          if (courses.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 42),
              child: Column(
                children: [
                  Icon(
                    Icons.menu_book_outlined,
                    size: 42,
                    color: Colors.black38,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'No courses here yet',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Add a course or import an approved Workday report.',
                    style: TextStyle(color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ...courses.map((course) => _CourseTile(course: course)),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _showImportInfo,
            icon: const Icon(Icons.upload_file),
            label: const Text('Import course history'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addCourse,
        icon: const Icon(Icons.add),
        label: const Text('Add course'),
      ),
    );
  }

  void _showImportInfo() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Workday import'),
        content: const Text(
          'The app is ready for a student data source, but LSU Workday access and an approved import format have not been set up. Never enter your Workday password here. For now, add course entries manually.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Future<void> _addCourse() async {
    final result = await showModalBottomSheet<CourseRecord>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _AddCourseSheet(),
    );
    if (result == null) return;
    await widget.dataSource.addCourse(result);
    widget.onChanged();
    if (mounted) setState(() {});
  }
}

class _CreditSummary extends StatelessWidget {
  const _CreditSummary({
    required this.label,
    required this.credits,
    required this.icon,
  });
  final String label;
  final int credits;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$credits',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _CourseTile extends StatelessWidget {
  const _CourseTile({required this.course});
  final CourseRecord course;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 9),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFFF0EAF7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          course.status == CourseStatus.completed
              ? Icons.check
              : Icons.menu_book_outlined,
          color: const Color(0xFF461D7C),
        ),
      ),
      title: Text(
        course.code,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        '${course.title}${course.term == null ? '' : '  •  ${course.term}'}',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(
        creditLabel(course.credits),
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
      ),
    ),
  );
}

class _AddCourseSheet extends StatefulWidget {
  const _AddCourseSheet();
  @override
  State<_AddCourseSheet> createState() => _AddCourseSheetState();
}

class _AddCourseSheetState extends State<_AddCourseSheet> {
  final formKey = GlobalKey<FormState>();
  final codeController = TextEditingController();
  final titleController = TextEditingController();
  final creditController = TextEditingController(text: '3');
  CourseStatus status = CourseStatus.completed;

  @override
  void dispose() {
    codeController.dispose();
    titleController.dispose();
    creditController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 22,
      ),
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add course',
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: codeController,
              decoration: const InputDecoration(
                labelText: 'Course code',
                hintText: 'e.g., ENGL 1001',
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter a course code'
                  : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Course title'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter a course title'
                  : null,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: creditController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Credits'),
                    validator: (value) {
                      final number = int.tryParse(value ?? '');
                      return number == null || number < 1 || number > 12
                          ? 'Use 1–12'
                          : null;
                    },
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: DropdownButtonFormField<CourseStatus>(
                    initialValue: status,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: const [
                      DropdownMenuItem(
                        value: CourseStatus.completed,
                        child: Text('Completed'),
                      ),
                      DropdownMenuItem(
                        value: CourseStatus.inProgress,
                        child: Text('Current'),
                      ),
                      DropdownMenuItem(
                        value: CourseStatus.planned,
                        child: Text('Planned'),
                      ),
                    ],
                    onChanged: (value) => setState(
                      () => status = value ?? CourseStatus.completed,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  if (!formKey.currentState!.validate()) return;
                  Navigator.pop(
                    context,
                    CourseRecord(
                      code: codeController.text.trim().toUpperCase(),
                      title: titleController.text.trim(),
                      credits: int.parse(creditController.text),
                      status: status,
                    ),
                  );
                },
                child: const Text('Save course'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
