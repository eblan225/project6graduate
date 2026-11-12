import 'package:material_ui/material_ui.dart';

import '../ui/app_theme.dart';
import 'schedule.dart';

class ScheduleDetailScreen extends StatefulWidget {
  const ScheduleDetailScreen({
    super.key,
    required this.schedule,
    required this.onChanged,
  });
  final SemesterSchedule schedule;
  final Future<void> Function() onChanged;
  @override
  State<ScheduleDetailScreen> createState() => _ScheduleDetailScreenState();
}

class _ScheduleDetailScreenState extends State<ScheduleDetailScreen> {
  bool calendar = false;
  Future<void> editClass([int? index]) async {
    final existing = index == null ? null : widget.schedule.classes[index];
    final name = TextEditingController(text: existing?.name);
    final time = TextEditingController(text: existing?.time);
    final form = GlobalKey<FormState>();
    final result = await showDialog<ScheduleClass>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(index == null ? 'Add a class' : 'Edit class'),
        content: Form(
          key: form,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Class name'),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Enter a class name'
                      : null,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: time,
                  decoration: const InputDecoration(
                    labelText: 'Meeting time (optional)',
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (form.currentState!.validate()) {
                Navigator.pop(
                  context,
                  ScheduleClass(name: name.text.trim(), time: time.text.trim()),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    // Wait for the dialog's dismissal animation before releasing its controllers.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    name.dispose();
    time.dispose();
    if (!mounted || result == null) return;
    setState(() {
      if (index == null) {
        widget.schedule.classes.add(result);
      } else {
        widget.schedule.classes[index] = result;
      }
    });
    await widget.onChanged();
  }

  Future<void> removeClass(int index) async {
    final course = widget.schedule.classes[index];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove class?'),
        content: Text('Remove ${course.name} from this semester?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    setState(() => widget.schedule.classes.removeAt(index));
    await widget.onChanged();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.schedule.name)),
    body: AppPage(
      children: [
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(
              value: false,
              icon: Icon(Icons.view_list_outlined),
              label: Text('Classes'),
            ),
            ButtonSegment(
              value: true,
              icon: Icon(Icons.calendar_view_week_outlined),
              label: Text('Calendar'),
            ),
          ],
          selected: {calendar},
          onSelectionChanged: (v) => setState(() => calendar = v.first),
        ),
        const SizedBox(height: 24),
        Text(
          '${widget.schedule.classes.length} classes',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          calendar
              ? 'Calendar preview • Meeting times are notes until scheduling is connected.'
              : 'Tap a class to update its name or meeting time.',
          style: const TextStyle(color: Color(0xFF767085), height: 1.5),
        ),
        const SizedBox(height: 20),
        if (calendar)
          const EmptyPanel(
            icon: Icons.calendar_month_outlined,
            title: 'Your week starts here',
            message: 'A timed weekly calendar will appear here once structured days and times are supported. Your class notes are listed below.',
          ),
        for (var i = 0; i < widget.schedule.classes.length; i++)
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 8,
              ),
              leading: const Icon(
                Icons.menu_book_outlined,
                color: AppStyle.purple,
              ),
              title: Text(widget.schedule.classes[i].name),
              subtitle: Text(
                widget.schedule.classes[i].time.isEmpty
                    ? 'Time not added'
                    : widget.schedule.classes[i].time,
              ),
              trailing: IconButton(
                tooltip: 'Remove class',
                icon: const Icon(Icons.delete_outline),
                onPressed: () => removeClass(i),
              ),
              onTap: () => editClass(i),
            ),
          ),
        const SizedBox(height: 88),
      ],
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () => editClass(),
      icon: const Icon(Icons.add),
      label: const Text('Add class'),
    ),
  );
}
