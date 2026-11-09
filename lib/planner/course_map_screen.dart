import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/degree_timeline.dart';
import '../schedules/schedule.dart';
import '../ui/app_theme.dart';
import 'course_plan.dart';
import 'course_template.dart';
import '../importing/import_courses_screen.dart';

class CourseMapScreen extends StatefulWidget {
  const CourseMapScreen({
    super.key,
    required this.plan,
    this.timeline,
    required this.onCreateSchedule,
  });
  final CoursePlan plan;
  final DegreeTimeline? timeline;
  final ValueChanged<SemesterSchedule> onCreateSchedule;
  @override
  State<CourseMapScreen> createState() => _CourseMapScreenState();
}

class _CourseMapScreenState extends State<CourseMapScreen> {
  String? selected;
  Size viewport = Size.zero;
  Size diagramSize = Size.zero;
  final transform = TransformationController();
  String term(int n) =>
      widget.timeline != null && n <= widget.timeline!.totalSemesters
      ? widget.timeline!.semesterLabel(n)
      : 'Semester $n';
  int get columns => math.max(
    widget.plan.courses
        .map((c) => widget.plan.placements[c.id]!)
        .fold<int>(1, math.max),
    widget.timeline?.totalSemesters ?? 8,
  );
  @override
  void dispose() {
    transform.dispose();
    super.dispose();
  }

  Future<void> openImport() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ImportCoursesScreen(plan: widget.plan)),
    );
    if (result == true && mounted) {
      setState(() {
        selected = null;
        transform.value = Matrix4.identity();
      });
    }
  }

  Future<void> details(TemplateCourse course) async {
    setState(() => selected = course.id);
    var status = widget.plan.status(course.id);
    var placement = widget.plan.placements[course.id]!;
    var elective = widget.plan.selections[course.id];
    final grade = TextEditingController(
      text: widget.plan.grades[course.id] ?? '',
    );
    var electiveName = elective ?? '';
    final incomingLinks = widget.plan.links
        .where((l) => l.to == course.id)
        .toList();
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, refresh) => AlertDialog(
          title: Text('${course.id} · ${course.credits} credits'),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(course.title),
                  const SizedBox(height: 8),
                  if (course.minimumC) const Text('Minimum grade: C'),
                  if (course.offered != null)
                    Text('${course.offered} only (flowchart)'),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    initialValue: placement,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Place in semester',
                    ),
                    items: List.generate(
                      columns,
                      (i) => DropdownMenuItem(
                        value: i + 1,
                        child: Text(term(i + 1)),
                      ),
                    ),
                    onChanged: (v) => placement = v!,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<PlanStatus>(
                    initialValue: status,
                    decoration: const InputDecoration(labelText: 'Progress'),
                    items: const [
                      DropdownMenuItem(
                        value: PlanStatus.planned,
                        child: Text('Planned'),
                      ),
                      DropdownMenuItem(
                        value: PlanStatus.inProgress,
                        child: Text('In progress'),
                      ),
                      DropdownMenuItem(
                        value: PlanStatus.completed,
                        child: Text('Completed'),
                      ),
                    ],
                    onChanged: (v) => refresh(() => status = v!),
                  ),
                  if (status == PlanStatus.completed) ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: grade,
                      decoration: const InputDecoration(
                        labelText: 'Grade (optional)',
                        helperText: 'Blank/pass/transfer grades remain flagged for review.',
                      ),
                    ),
                  ],
                  if (course.id == 'BREADTH') ...[
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: elective,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Choose breadth course',
                      ),
                      items: course.choices
                          .map(
                            (v) => DropdownMenuItem(
                              value: v,
                              child: Text(v, overflow: TextOverflow.ellipsis),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        elective = v;
                        electiveName = v ?? '';
                      },
                    ),
                  ] else if (!course.id.contains(' ')) ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: electiveName,
                      decoration: const InputDecoration(
                        labelText: 'Course for this elective slot',
                        helperText: 'Confirm eligibility with your advisor.',
                      ),
                      onChanged: (v) => electiveName = v,
                    ),
                  ],
                  const SizedBox(height: 20),
                  const Text(
                    'Dependencies',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  for (final link in List.of(incomingLinks))
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${link.concurrent ? '⇢ Co-requisite' : '→ Prerequisite'}: ${link.from}',
                          ),
                        ),
                        IconButton(
                          tooltip: 'Remove dependency',
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () =>
                              refresh(() => incomingLinks.remove(link)),
                        ),
                      ],
                    ),
                  if (incomingLinks.isEmpty)
                    const Text(
                      'No incoming arrows. Add dependencies as needed.',
                    ),
                  TextButton.icon(
                    onPressed: () async {
                      final link = await pickDependency(course.id);
                      if (link != null &&
                          !incomingLinks.any((l) => l.from == link.from)) {
                        refresh(() => incomingLinks.add(link));
                      }
                    },
                    icon: const Icon(Icons.add_link),
                    label: const Text('Add dependency'),
                  ),
                  if (course.id == 'EE 4810')
                    const Text(
                      'Also: senior standing (90 credits) and one of EE 3160, 3220, 3410, 3530, or 3755.',
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save course'),
            ),
          ],
        ),
      ),
    );
    if (saved == true) {
      widget.plan.setDependencies(course.id, incomingLinks);
      widget.plan.move(course.id, placement);
      widget.plan.update(course.id, status, grade.text, electiveName);
    }
    await Future<void>.delayed(const Duration(milliseconds: 300));
    grade.dispose();
  }

  Future<CourseLink?> pickDependency(String to) async {
    final candidates = widget.plan.courses.where((c) => c.id != to).toList();
    if (candidates.isEmpty) return null;
    var from = candidates.first.id;
    var concurrent = false;
    return showDialog<CourseLink>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Add incoming arrow'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: from,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Required course'),
              items: candidates
                  .map((v) => DropdownMenuItem(value: v.id, child: Text(v.id)))
                  .toList(),
              onChanged: (v) => from = v!,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<bool>(
              initialValue: false,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Arrow type'),
              items: const [
                DropdownMenuItem(
                  value: false,
                  child: Text('Solid · prerequisite'),
                ),
                DropdownMenuItem(
                  value: true,
                  child: Text('Dotted · co-requisite'),
                ),
              ],
              onChanged: (v) => concurrent = v!,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(c, CourseLink(from, to, concurrent: concurrent)),
            child: const Text('Add arrow'),
          ),
        ],
      ),
    );
  }

  Future<void> createSchedule() async {
    if (widget.timeline == null) return;
    var semester = widget.timeline!.currentSemester;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create semester schedule'),
        content: DropdownButtonFormField<int>(
          initialValue: semester,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Semester'),
          items: List.generate(
            widget.timeline!.totalSemesters,
            (i) => DropdownMenuItem(value: i + 1, child: Text(term(i + 1))),
          ),
          onChanged: (v) => semester = v!,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Create schedule'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    final courses = widget.plan.courses
        .where(
          (c) =>
              widget.plan.placements[c.id] == semester &&
              widget.plan.status(c.id) != PlanStatus.completed,
        )
        .toList();
    if (courses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No planned or in-progress classes in that semester.'),
        ),
      );
      return;
    }
    widget.onCreateSchedule(
      SemesterSchedule(
        name: term(semester),
        classes: courses
            .map(
              (c) => ScheduleClass(
                name:
                    '${widget.plan.label(c)} — ${c.title} (${c.credits} credits)',
              ),
            )
            .toList(),
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Created a schedule copy in Semesters. Changes to this map won’t overwrite it.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.plan,
    builder: (context, _) {
      final issues = {
        for (final c in widget.plan.courses)
          c.id: widget.plan.warnings(c.id, widget.timeline),
      };
      final count = issues.values.where((v) => v.isNotEmpty).length;
      return Scaffold(
        appBar: AppBar(
          title: const Text('Course map'),
          actions: [
            IconButton(
              tooltip: 'Import XLSX or PDF',
              icon: const Icon(Icons.upload_file_outlined),
              onPressed: openImport,
            ),
            IconButton(
              tooltip: 'Fit map',
              onPressed: () {
                if (diagramSize.isEmpty) return;
                final scale = math
                    .min(
                      viewport.width / diagramSize.width,
                      viewport.height / diagramSize.height,
                    )
                    .clamp(0.1, 1.0);
                transform.value = Matrix4.identity()
                  ..scaleByDouble(scale, scale, 1, 1);
              },
              icon: const Icon(Icons.zoom_out_map),
            ),
            IconButton(
              tooltip: 'Reset template',
              icon: const Icon(Icons.restart_alt),
              onPressed: () async {
                final yes = await showDialog<bool>(
                  context: context,
                  builder: (c) => AlertDialog(
                    title: const Text('Reset course map?'),
                    content: const Text(
                      'This clears course moves, elective choices, and entered progress. Semester schedule copies stay unchanged.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(c, false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(c, true),
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                );
                if (yes == true) widget.plan.reset();
              },
            ),
          ],
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${widget.plan.title} · ${widget.plan.courses.fold<int>(0, (sum, c) => sum + c.credits)} credits',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Tap a course to place it. Long-press and drag to a semester header. Pinch to zoom; drag the map to pan.',
                    style: TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '→ Prerequisite    ⇢ Dotted: co-requisite    C: minimum C\nImported files exclude grades and personal progress',
                    style: TextStyle(fontSize: 12),
                  ),
                  if (widget.timeline == null)
                    const Text(
                      'Save My goals to attach calendar dates and create schedule copies.',
                      style: TextStyle(color: AppStyle.purple),
                    ),
                  Text(
                    '$count courses need review · Tap Review to inspect',
                    style: const TextStyle(fontSize: 12),
                  ),
                  Wrap(
                    spacing: 8,
                    children: [
                      TextButton.icon(
                        onPressed: openImport,
                        icon: const Icon(Icons.upload_file_outlined),
                        label: const Text('Import XLSX / PDF'),
                      ),
                      TextButton.icon(
                        onPressed: () => showModalBottomSheet<void>(
                          context: context,
                          isScrollControlled: true,
                          showDragHandle: true,
                          builder: (context) => SafeArea(
                            child: SizedBox(
                              height: MediaQuery.sizeOf(context).height * 0.65,
                              child: ListView(
                                padding: const EdgeInsets.all(20),
                                children: [
                                  const Text(
                                    'Planning review',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Text(
                                    'This advising template is not an official degree audit. Elective-specific prerequisites, transfer equivalencies, and live offerings require confirmation.',
                                  ),
                                  for (final c in widget.plan.courses.where(
                                    (c) => issues[c.id]!.isNotEmpty,
                                  ))
                                    ListTile(
                                      title: Text(c.id),
                                      subtitle: Text(issues[c.id]!.join('\n')),
                                    ),
                                  if (count == 0)
                                    const Text(
                                      'No ordering conflicts detected in the transcribed rules. Confirm your full plan with advising.',
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        icon: const Icon(Icons.rule),
                        label: const Text('Review'),
                      ),
                      TextButton.icon(
                        onPressed: widget.timeline == null
                            ? null
                            : createSchedule,
                        icon: const Icon(Icons.playlist_add),
                        label: const Text('Make schedule'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const laneWidth = 246.0, cardHeight = 132.0, step = 160.0;
                  final groups = List.generate(
                    columns,
                    (i) => widget.plan.courses
                        .where((c) => widget.plan.placements[c.id] == i + 1)
                        .toList(),
                  );
                  final height = math.max(
                    constraints.maxHeight,
                    130 + groups.map((g) => g.length).reduce(math.max) * step,
                  );
                  final positions = <String, Offset>{};
                  for (var i = 0; i < groups.length; i++) {
                    for (var j = 0; j < groups[i].length; j++) {
                      positions[groups[i][j].id] = Offset(
                        i * laneWidth + 16,
                        112 + j * step,
                      );
                    }
                  }
                  viewport = Size(constraints.maxWidth, constraints.maxHeight);
                  diagramSize = Size(columns * laneWidth, height);
                  return InteractiveViewer(
                    transformationController: transform,
                    constrained: false,
                    minScale: 0.1,
                    maxScale: 2,
                    boundaryMargin: const EdgeInsets.all(60),
                    child: SizedBox(
                      width: columns * laneWidth,
                      height: height,
                      child: Stack(
                        children: [
                          for (var i = 0; i < columns; i++)
                            Positioned(
                              left: i * laneWidth,
                              top: 0,
                              bottom: 0,
                              width: laneWidth,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: i.isEven
                                      ? const Color(0xFFF1EEF8)
                                      : Colors.white,
                                  border: const Border(
                                    right: BorderSide(color: Color(0xFFE3DFEF)),
                                  ),
                                ),
                              ),
                            ),
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _DependencyPainter(
                                positions,
                                selected,
                                cardHeight,
                                widget.plan.links,
                              ),
                            ),
                          ),
                          for (var i = 0; i < columns; i++)
                            Positioned(
                              left: i * laneWidth + 12,
                              top: 8,
                              width: laneWidth - 24,
                              child: DragTarget<String>(
                                onAcceptWithDetails: (details) =>
                                    widget.plan.move(details.data, i + 1),
                                builder: (context, incoming, rejected) => Container(
                                  height: 88,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: incoming.isNotEmpty
                                        ? const Color(0xFFDDD5FF)
                                        : const Color(0xFFECE8F8),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        term(i + 1),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        '${groups[i].fold<int>(0, (sum, c) => sum + c.credits)} credits · ${groups[i].length} courses',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      if (widget.timeline?.currentSemester ==
                                          i + 1)
                                        const Text(
                                          'Current semester',
                                          maxLines: 1,
                                          style: TextStyle(
                                            color: AppStyle.purple,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          for (final course in widget.plan.courses)
                            Positioned(
                              left: positions[course.id]!.dx,
                              top: positions[course.id]!.dy,
                              width: laneWidth - 32,
                              height: cardHeight,
                              child: LongPressDraggable<String>(
                                data: course.id,
                                feedback: Material(
                                  elevation: 6,
                                  borderRadius: BorderRadius.circular(12),
                                  child: SizedBox(
                                    width: 210,
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Text(course.id),
                                    ),
                                  ),
                                ),
                                childWhenDragging: Opacity(
                                  opacity: 0.3,
                                  child: _card(course, issues[course.id]!),
                                ),
                                child: _card(course, issues[course.id]!),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    },
  );

  Widget _card(TemplateCourse c, List<String> issues) => Material(
    color: widget.plan.status(c.id) == PlanStatus.completed
        ? const Color(0xFFE3F4E9)
        : Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(
        color: selected == c.id
            ? AppStyle.purple
            : issues.isNotEmpty
            ? const Color(0xFFAD701D)
            : const Color(0xFFD7D1E6),
        width: selected == c.id ? 2 : 1,
      ),
    ),
    child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => details(c),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.plan.label(c),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                if (issues.isNotEmpty)
                  const Icon(
                    Icons.warning_amber_rounded,
                    size: 17,
                    color: Color(0xFFAD701D),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Text(
                c.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
            ),
            Text(
              '${c.credits} credits${c.minimumC ? ' · C' : ''}${c.offered == null ? '' : ' · ${c.offered}'}',
              style: const TextStyle(fontSize: 12),
            ),
            Text(
              widget.plan.status(c.id).name,
              style: const TextStyle(fontSize: 11, color: AppStyle.purple),
            ),
          ],
        ),
      ),
    ),
  );
}

class _DependencyPainter extends CustomPainter {
  _DependencyPainter(
    this.positions,
    this.selected,
    this.cardHeight,
    this.links,
  );
  final Map<String, Offset> positions;
  final String? selected;
  final double cardHeight;
  final List<CourseLink> links;
  @override
  void paint(Canvas canvas, Size size) {
    for (final link in links) {
      final active = selected == link.from || selected == link.to;
      final from = positions[link.from]! + Offset(214, cardHeight / 2);
      final to = positions[link.to]! + Offset(0, cardHeight / 2);
      final paint = Paint()
        ..color = active
            ? (link.concurrent ? const Color(0xFF0A8178) : AppStyle.purple)
            : const Color(0xFFB9B1CB)
        ..strokeWidth = active ? 2.7 : 1.1
        ..style = PaintingStyle.stroke;
      final path = Path()..moveTo(from.dx, from.dy);
      if (to.dx > from.dx) {
        path.cubicTo(from.dx + 38, from.dy, to.dx - 38, to.dy, to.dx, to.dy);
      } else {
        path.cubicTo(
          from.dx + 28,
          from.dy - 80,
          to.dx - 28,
          to.dy - 80,
          to.dx,
          to.dy,
        );
      }
      if (link.concurrent) {
        for (final metric in path.computeMetrics()) {
          for (double n = 0; n < metric.length; n += 10) {
            canvas.drawPath(
              metric.extractPath(n, math.min(n + 4, metric.length)),
              paint,
            );
          }
        }
      } else {
        canvas.drawPath(path, paint);
      }
      final tangent = path.computeMetrics().first.getTangentForOffset(
        path.computeMetrics().first.length,
      )!;
      final direction = tangent.vector / tangent.vector.distance;
      final normal = Offset(-direction.dy, direction.dx);
      canvas.drawPath(
        Path()
          ..moveTo(to.dx, to.dy)
          ..lineTo(
            (to - direction * 9 + normal * 4).dx,
            (to - direction * 9 + normal * 4).dy,
          )
          ..moveTo(to.dx, to.dy)
          ..lineTo(
            (to - direction * 9 - normal * 4).dx,
            (to - direction * 9 - normal * 4).dy,
          ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DependencyPainter oldDelegate) => true;
}
