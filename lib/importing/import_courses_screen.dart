import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdfrx/pdfrx.dart';

import '../planner/course_plan.dart';
import '../planner/course_template.dart';
import '../ui/app_theme.dart';
import 'course_import.dart';
import 'course_file_picker.dart';

class ImportCoursesScreen extends StatefulWidget {
  const ImportCoursesScreen({super.key, required this.plan, this.pickFile});
  final CoursePlan plan;
  final Future<XFile?> Function()? pickFile;
  @override
  State<ImportCoursesScreen> createState() => _ImportCoursesScreenState();
}

class _ImportCoursesScreenState extends State<ImportCoursesScreen> {
  CourseImport? draft;
  String? fileName, error;
  bool busy = false, merge = true;
  final form = GlobalKey<FormState>();
  Future<void> pick() async {
    setState(() {
      busy = true;
      error = null;
    });
    var fileChosen = false;
    try {
      final file = await (widget.pickFile ?? pickCourseFile)();
      if (file == null) return;
      fileChosen = true;
      if (await file.length() > 10 * 1024 * 1024) {
        throw const FormatException('Choose a file under 10 MB.');
      }
      final bytes = await file.readAsBytes();
      CourseImport result;
      if (file.name.toLowerCase().endsWith('.xlsx')) {
        result = parseAcademicXlsx(bytes);
      } else if (file.name.toLowerCase().endsWith('.pdf')) {
        await pdfrxFlutterInitialize();
        final doc = await PdfDocument.openData(bytes);
        try {
          if (doc.pages.length > 30) {
            throw const FormatException('Use a PDF with 30 pages or fewer.');
          }
          final text = StringBuffer();
          for (final page in doc.pages) {
            text.writeln((await page.loadText())?.fullText ?? '');
          }
          result = parseCoursePdfText(text.toString());
        } finally {
          await doc.dispose();
        }
      } else {
        throw const FormatException('Choose an XLSX or PDF file.');
      }
      if (!mounted) return;
      setState(() {
        draft = result;
        fileName = file.name;
      });
    } on MissingPluginException {
      if (mounted) {
        setState(
          () => error = 'The file picker is not loaded in this debug session. Stop Flutter and run the app again; a hot reload cannot load a new native plugin.',
        );
      }
    } on FormatException catch (e) {
      if (mounted) setState(() => error = e.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => error = fileChosen
              ? 'Could not read the selected file. Try an unencrypted XLSX or text-based PDF. Your map has not changed.'
              : 'Could not open the file chooser. Reload the browser or restart the app, then try again. No file was read.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Import courses')),
    body: Form(
      key: form,
      child: AppPage(
        children: [
          const Text(
            'Bring your courses into the map',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Text(
            'Choose an academic-progress XLSX or a course-flowchart PDF. Files are processed locally. Grades and personal progress are not imported.',
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: busy ? null : pick,
            icon: const Icon(Icons.upload_file_outlined),
            label: Text(busy ? 'Reading file…' : 'Choose XLSX or PDF'),
          ),
          if (busy) const LinearProgressIndicator(),
          if (error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          if (draft != null) ...[
            const SizedBox(height: 24),
            Text(fileName!, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(draft!.note),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: merge,
              title: const Text('Add to existing map'),
              subtitle: const Text(
                'Turn off to replace the map. Existing semester schedule copies stay unchanged.',
              ),
              onChanged: (v) => setState(() => merge = v),
            ),
            const Text(
              'Review courses • Tap a row to edit title, credits or semester.',
            ),
            for (var i = 0; i < draft!.courses.length; i++)
              Card(
                child: CheckboxListTile(
                  value: draft!.courses[i].include,
                  onChanged: (v) =>
                      setState(() => draft!.courses[i].include = v!),
                  title: Text(draft!.courses[i].id),
                  subtitle: Text(
                    '${draft!.courses[i].credits ?? 'Missing'} credits · Semester ${draft!.courses[i].semester}',
                  ),
                  secondary: IconButton(
                    tooltip: 'Edit imported course',
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => edit(draft!.courses[i]),
                  ),
                ),
              ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: apply,
              child: const Text('Apply reviewed import'),
            ),
            const SizedBox(height: 24),
          ],
        ],
      ),
    ),
  );

  Future<void> edit(ImportCourse course) async {
    final credits = TextEditingController(
      text: course.credits?.toString() ?? '',
    );
    final title = TextEditingController(text: course.title);
    final semester = TextEditingController(text: course.semester.toString());
    final key = GlobalKey<FormState>();
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(course.id),
        content: Form(
          key: key,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: title,
                  decoration: const InputDecoration(labelText: 'Course title'),
                  validator: (v) => v!.trim().isEmpty ? 'Enter a title' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: credits,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Credit hours'),
                  validator: (v) =>
                      (int.tryParse(v ?? '') ?? 0) < 1 ||
                          (int.tryParse(v ?? '') ?? 0) > 12
                      ? 'Enter 1–12 credits'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: semester,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Semester number',
                  ),
                  validator: (v) =>
                      (int.tryParse(v ?? '') ?? 0) < 1 ||
                          (int.tryParse(v ?? '') ?? 0) > 10
                      ? 'Enter semester 1–10'
                      : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (key.currentState!.validate()) Navigator.pop(c, true);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (yes == true && mounted) {
      setState(() {
        course.title = title.text.trim();
        course.credits = int.parse(credits.text);
        course.semester = int.parse(semester.text);
      });
    }
    await Future<void>.delayed(const Duration(milliseconds: 300));
    credits.dispose();
    title.dispose();
    semester.dispose();
  }

  Future<void> apply() async {
    final rows = draft!.courses.where((c) => c.include).toList();
    if (rows.isEmpty ||
        rows.any(
          (c) => c.credits == null || c.credits! < 1 || c.credits! > 12,
        )) {
      setState(
        () => error = 'Select courses and fill in valid credit hours (1–12) for every selected row.',
      );
      return;
    }
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(
          merge ? 'Add ${rows.length} courses?' : 'Replace the course map?',
        ),
        content: Text(
          merge
              ? 'Existing course IDs will be kept without duplication. New courses start with blank progress.'
              : 'This clears existing placements and entered progress. Semester schedule copies remain unchanged.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Apply import'),
          ),
        ],
      ),
    );
    if (yes != true || !mounted) return;
    final courses = rows.map((r) {
      final known = draft!.supportedFlowchart ? knownCourse(r.id) : null;
      return TemplateCourse(
        r.id,
        r.title,
        r.credits!,
        r.semester,
        minimumC: known?.minimumC ?? false,
        offered: known?.offered,
        choices: known?.choices ?? const [],
      );
    }).toList();
    final ids = courses.map((c) => c.id).toSet();
    widget.plan.importCourses(
      courses,
      draft!.supportedFlowchart
          ? eecLinks
                .where((l) => ids.contains(l.from) && ids.contains(l.to))
                .toList()
          : [],
      merge: merge,
    );
    Navigator.pop(context, true);
  }
}
