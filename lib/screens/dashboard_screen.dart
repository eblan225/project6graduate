import 'package:flutter/material.dart';

import '../models/academic_models.dart';
import '../main.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.student, required this.onOpenCourses});
  final StudentProfile student;
  final VoidCallback onOpenCourses;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      children: [
        Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: theme.colorScheme.primary, borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.school, color: Colors.white),
          ),
          const SizedBox(width: 12),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('TigerTrack', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            Text('Your path to graduation', style: TextStyle(color: Colors.black54, fontSize: 12)),
          ])),
          IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none), tooltip: 'Notifications'),
        ]),
        const SizedBox(height: 22),
        Text('Good afternoon,', style: theme.textTheme.titleMedium?.copyWith(color: Colors.black54)),
        Text(student.name.split(' ').first, style: theme.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w800, height: 1.2)),
        const SizedBox(height: 6),
        Text('${student.major}  •  LSU', style: theme.textTheme.bodyLarge?.copyWith(color: Colors.black54)),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF461D7C), Color(0xFF6A3B9B)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('DEGREE PROGRESS', style: TextStyle(color: Colors.white70, letterSpacing: 1.1, fontSize: 11, fontWeight: FontWeight.w700)),
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: Colors.white.withValues(alpha: .16), borderRadius: BorderRadius.circular(20)), child: Text('Target ${student.targetGraduation}', style: const TextStyle(color: Colors.white, fontSize: 11))),
            ]),
            const SizedBox(height: 12),
            Text('${student.completionFraction == 0 ? 0 : (student.completionFraction * 100).round()}%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 38)),
            const Text('of estimated credits complete', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 18),
            ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: student.completionFraction, minHeight: 9, backgroundColor: Colors.white24, color: const Color(0xFFFDD023))),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('${student.earnedOrInProgressCredits} / ${student.requiredCredits} credits', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              Text('${student.remainingCredits} left', style: const TextStyle(color: Colors.white70)),
            ]),
          ]),
        ),
        const SizedBox(height: 18),
        Row(children: [
          Expanded(child: _MetricCard(icon: Icons.event_available, label: 'Target finish', value: student.targetGraduation, tint: const Color(0xFFEEE6F8))),
          const SizedBox(width: 12),
          Expanded(child: _MetricCard(icon: Icons.bolt, label: 'Min. per term*', value: '${student.minimumCreditsPerTerm} credits', tint: const Color(0xFFFFF3CE))),
        ]),
        const SizedBox(height: 24),
        SectionTitle('Your next steps', action: 'See courses', onAction: onOpenCourses),
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
          _StepRow(number: '1', title: 'Review your course history', subtitle: 'Make sure completed and current classes are right', complete: student.courses.isNotEmpty),
          const Divider(height: 24),
          const _StepRow(number: '2', title: 'Connect or import Workday', subtitle: 'Set up once LSU-approved access is available', complete: false),
          const Divider(height: 24),
          const _StepRow(number: '3', title: 'Build your semester plan', subtitle: 'See a draft path to your target graduation', complete: false),
        ]))),
        const SizedBox(height: 14),
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFFFF8E1), borderRadius: BorderRadius.circular(14)), child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.info_outline, size: 18, color: Color(0xFF8A6410)),
          SizedBox(width: 8),
          Expanded(child: Text('Prototype with sample data. Credit totals and term estimates are not an LSU degree audit.', style: TextStyle(fontSize: 12, color: Color(0xFF684B0B)))),
        ])),
        const SizedBox(height: 8),
        const Text('*Simple estimate using three remaining terms; excludes prerequisites, course availability, and program rules.', style: TextStyle(fontSize: 11, color: Colors.black45)),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.icon, required this.label, required this.value, required this.tint});
  final IconData icon;
  final String label;
  final String value;
  final Color tint;

  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(15), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(10)), child: Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary)),
        const SizedBox(height: 13),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        const SizedBox(height: 3),
        Text(label, style: const TextStyle(color: Colors.black54, fontSize: 11)),
      ])));
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.number, required this.title, required this.subtitle, required this.complete});
  final String number;
  final String title;
  final String subtitle;
  final bool complete;

  @override
  Widget build(BuildContext context) => Row(children: [
        CircleAvatar(radius: 16, backgroundColor: complete ? const Color(0xFFE9F5EC) : const Color(0xFFF0EDF4), child: complete ? const Icon(Icons.check, size: 17, color: Color(0xFF27733C)) : Text(number, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)), const SizedBox(height: 3), Text(subtitle, style: const TextStyle(color: Colors.black54, fontSize: 11))])),
      ]);
}
