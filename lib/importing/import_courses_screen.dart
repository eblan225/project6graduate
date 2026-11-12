import 'dart:ui' as ui;
import 'dart:math' as math;

import 'package:file_selector/file_selector.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:pdfrx/pdfrx.dart';

import '../planner/course_plan.dart';
import '../planner/course_template.dart';
import '../ui/app_theme.dart';
import 'course_import.dart';
import 'flowchart_layout.dart';
import 'course_file_picker.dart';

class ImportCoursesScreen extends StatefulWidget {
  const ImportCoursesScreen({
    super.key,
    required this.plan,
    this.pickFile,
    this.initialMerge = true,
  });
  final CoursePlan plan;
  final bool initialMerge;
  final Future<XFile?> Function()? pickFile;
  @override
  State<ImportCoursesScreen> createState() => _ImportCoursesScreenState();
}

class _ImportCoursesScreenState extends State<ImportCoursesScreen> {
  CourseImport? draft;
  String? fileName, error;
  bool busy = false;
  late bool merge;

  @override
  void initState() {
    super.initState();
    merge = widget.initialMerge;
  }

  List<Uint8List> previews = [];
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
      final images = <Uint8List>[];
      if (file.name.toLowerCase().endsWith('.xlsx')) {
        result = parseAcademicXlsx(bytes);
      } else if (file.name.toLowerCase().endsWith('.pdf')) {
        await pdfrxFlutterInitialize();
        final doc = await PdfDocument.openData(bytes);
        try {
          if (doc.pages.length > 30) {
            throw const FormatException('Use a PDF with 30 pages or fewer.');
          }
          final results = <CourseImport>[];
          for (final page in doc.pages) {
            final raw = await page.loadText();
            final scale = 1800 / math.max(page.width, page.height);
            final image = await page.render(
              fullWidth: page.width * scale,
              fullHeight: page.height * scale,
            );
            if (image == null) {
              throw const FormatException('Could not render PDF page.');
            }
            try {
              final text = <ChartText>[];
              if (raw != null) {
                for (
                  var i = 0;
                  i < raw.fullText.length && i < raw.charRects.length;
                  i++
                ) {
                  final r = raw.charRects[i].rotate(page.rotation.index, page);
                  if (raw.fullText[i] == '\n' ||
                      raw.fullText[i] == '\r' ||
                      r.width <= 0 ||
                      r.height <= 0) {
                    continue;
                  }
                  text.add(
                    ChartText(
                      raw.fullText[i],
                      Rect.fromLTRB(
                        r.left * scale,
                        (page.height - r.top) * scale,
                        r.right * scale,
                        (page.height - r.bottom) * scale,
                      ),
                    ),
                  );
                }
              }
              try {
                results.add(
                  parseFlowchartPages([
                    FlowchartPage(
                      image.width,
                      image.height,
                      image.pixels,
                      text,
                    ),
                  ], pageNumberOffset: page.pageNumber - 1),
                );
              } on FormatException {
                // Cover/legend-only pages have no importable courses.
              }
              final buffer = await ui.ImmutableBuffer.fromUint8List(
                image.pixels,
              );
              final descriptor = ui.ImageDescriptor.raw(
                buffer,
                width: image.width,
                height: image.height,
                pixelFormat: ui.PixelFormat.bgra8888,
              );
              final codec = await descriptor.instantiateCodec();
              final frame = await codec.getNextFrame();
              final png = await frame.image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              if (png != null) images.add(png.buffer.asUint8List());
              frame.image.dispose();
              codec.dispose();
              descriptor.dispose();
              buffer.dispose();
            } finally {
              image.dispose();
            }
          }
          if (results.isEmpty) {
            throw const FormatException(
              'No course boxes or course codes found. Use a text-based PDF; scanned files need OCR.',
            );
          }
          result = results.length == 1
              ? results.single
              : CourseImport(
                  {
                    for (final r in results)
                      for (final c in r.courses) c.id: c,
                  }.values.toList(),
                  results.map((r) => r.note).toSet().join('\n\n'),
                  links: [
                    for (final r in results)
                      ...r.supportedFlowchart ? eecLinks : r.links,
                  ],
                );
        } finally {
          await doc.dispose();
        }
      } else {
        throw const FormatException('Choose an XLSX or PDF file.');
      }
      if (!mounted) return;
      setState(() {
        draft = result;
        previews = images;
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
            for (var i = 0; i < previews.length; i++)
              ExpansionTile(
                title: Text('Original flowchart • Page ${i + 1}'),
                children: [
                  SizedBox(
                    height: 400,
                    child: InteractiveViewer(
                      maxScale: 6,
                      child: Image.memory(previews[i]),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 12),
            const Text(
              'Review connections',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text(
              'Confirm direction and type against the original. Crossing, dashed and alternative paths may need to be added here.',
            ),
            for (final link in List.of(draft!.links))
              ListTile(
                title: Text(
                  '${courseDisplayId(link.from)} → ${courseDisplayId(link.to)}',
                ),
                subtitle: Text(
                  link.concurrent
                      ? 'Credit or registration required'
                      : 'Credit required',
                ),
                onTap: () => editLink(link),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Remove connection',
                  onPressed: () => setState(() => draft!.links.remove(link)),
                ),
              ),
            TextButton.icon(
              onPressed: () => editLink(null),
              icon: const Icon(Icons.add_link),
              label: const Text('Add connection'),
            ),
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
                  title: Text(courseDisplayId(draft!.courses[i].id)),
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

  Future<void> editLink(CourseLink? existing) async {
    final ids = draft!.courses
        .where((c) => c.include)
        .map((c) => c.id)
        .toList();
    if (ids.length < 2) return;
    var from = ids.contains(existing?.from) ? existing!.from : ids.first;
    var to = ids.contains(existing?.to) ? existing!.to : ids[1];
    var concurrent = existing?.concurrent ?? false;
    final result = await showDialog<CourseLink>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, refresh) => AlertDialog(
          title: const Text('Review connection'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: from,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Required course',
                  ),
                  items: ids
                      .map(
                        (id) => DropdownMenuItem(
                          value: id,
                          child: Text(courseDisplayId(id)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => refresh(() => from = value!),
                ),
                DropdownButtonFormField<String>(
                  initialValue: to,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Following course',
                  ),
                  items: ids
                      .map(
                        (id) => DropdownMenuItem(
                          value: id,
                          child: Text(courseDisplayId(id)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => refresh(() => to = value!),
                ),
                SwitchListTile(
                  title: const Text('Credit or registration allowed'),
                  subtitle: const Text('Dashed/open arrow in this flowchart'),
                  value: concurrent,
                  onChanged: (v) => refresh(() => concurrent = v),
                ),
                if (from == to) const Text('Choose two different courses.'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: from == to
                  ? null
                  : () => Navigator.pop(
                      context,
                      CourseLink(from, to, concurrent: concurrent),
                    ),
              child: const Text('Save connection'),
            ),
          ],
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() {
        draft!.links.removeWhere(
          (l) =>
              identical(l, existing) ||
              (l.from == result.from && l.to == result.to),
        );
        draft!.links.add(result);
      });
    }
  }

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
        title: Text(courseDisplayId(course.id)),
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
        minimumC: known?.minimumC ?? r.minimumC,
        offered: known?.offered ?? r.offered,
        choices: known?.choices ?? const [],
      );
    }).toList();
    final ids = courses.map((c) => c.id).toSet();
    widget.plan.importCourses(
      courses,
      draft!.links
          .where((l) => ids.contains(l.from) && ids.contains(l.to))
          .toList(),
      merge: merge,
    );
    Navigator.pop(context, true);
  }
}
