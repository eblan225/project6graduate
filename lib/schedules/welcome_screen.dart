import 'package:flutter/material.dart';

import '../ui/app_theme.dart';
import '../models/degree_timeline.dart';

/// Planning preferences live here; semester schedules have their own screen.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key, required this.onContinue});
  final ValueChanged<DegreeTimeline> onContinue;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final form = GlobalKey<FormState>();
  final major = TextEditingController();
  int programYears = 4;
  int currentSemester = 1;
  bool startsInFall = true;
  final startYear = TextEditingController();

  DegreeTimeline? get timeline {
    final year = int.tryParse(startYear.text.trim());
    if (year == null || year < 1900 || year > 2200) return null;
    return DegreeTimeline(
      programYears: programYears,
      startYear: year,
      startsInFall: startsInFall,
      currentSemester: currentSemester,
    );
  }

  @override
  void dispose() {
    major.dispose();
    startYear.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Form(
        key: form,
        child: AppPage(
          children: [
            const SizedBox(height: 24),
            const Align(
              alignment: Alignment.centerLeft,
              child: CircleAvatar(
                radius: 28,
                backgroundColor: Color(0xFFECE8FF),
                child: Icon(
                  Icons.school_outlined,
                  size: 30,
                  color: AppStyle.purple,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Graduate!',
              style: TextStyle(
                fontSize: 38,
                fontWeight: FontWeight.w800,
                color: AppStyle.purple,
                letterSpacing: -1.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'What does your path look like?',
              style: Theme.of(context).textTheme.headlineMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            const Text(
              'Start with your major and degree program length. You can change these here anytime.',
              style: TextStyle(
                height: 1.6,
                color: Color(0xFF767085),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 28),
            TextFormField(
              controller: major,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'What is your major?',
                hintText: 'e.g. Computer Science or Undecided',
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter your major, or type Undecided'
                  : null,
            ),
            const SizedBox(height: 24),
            Text(
              'How long is your degree program?',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: programYears,
              decoration: const InputDecoration(labelText: 'Degree program'),
              items: const [2, 4, 5]
                  .map(
                    (years) => DropdownMenuItem(
                      value: years,
                      child: Text('$years-year program'),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() {
                programYears = value!;
                if (currentSemester > programYears * 2) {
                  currentSemester = programYears * 2;
                }
              }),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<bool>(
              initialValue: startsInFall,
              decoration: const InputDecoration(
                labelText: 'First semester term',
              ),
              items: const [
                DropdownMenuItem(value: true, child: Text('Fall')),
                DropdownMenuItem(value: false, child: Text('Spring')),
              ],
              onChanged: (value) => setState(() => startsInFall = value!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: startYear,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'First semester year',
                hintText: 'e.g. 2027',
              ),
              onChanged: (_) => setState(() {}),
              validator: (_) =>
                  timeline == null ? 'Enter a year from 1900 to 2200' : null,
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<int>(
              key: ValueKey(programYears),
              initialValue: currentSemester,
              decoration: const InputDecoration(
                labelText: 'Current semester in your degree',
              ),
              isExpanded: true,
              items: List.generate(
                programYears * 2,
                (i) => DropdownMenuItem(
                  value: i + 1,
                  child: Text(
                    'Semester ${i + 1}${timeline == null ? '' : ' · ${timeline!.semesterLabel(i + 1)}'}',
                  ),
                ),
              ),
              onChanged: (value) => setState(() => currentSemester = value!),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Final semester time period',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      timeline == null
                          ? 'Semester ${programYears * 2} · End of year $programYears'
                          : '${timeline!.semesterLabel(programYears * 2)} · Semester ${programYears * 2}',
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(color: AppStyle.purple),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      timeline == null
                          ? 'Enter your first semester to see calendar dates. Uses Fall and Spring; summers are excluded.'
                          : '${timeline!.semestersAfterCurrent} semesters after your current semester. Uses Fall and Spring; summers are excluded.',
                      style: TextStyle(height: 1.5, color: Color(0xFF767085)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: () {
                if (form.currentState!.validate()) {
                  FocusScope.of(context).unfocus();
                  widget.onContinue(timeline!);
                }
              },
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Continue to schedules'),
            ),
            const SizedBox(height: 20),
            const Text(
              'Save changes with Continue to schedules. Dates and remaining semesters guide your timeline; required courses still need degree requirements and completed-course information.',
              style: TextStyle(height: 1.5, color: Color(0xFF767085)),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    ),
  );
}
