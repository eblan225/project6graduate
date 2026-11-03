import 'package:flutter/material.dart';

import '../main.dart';
import '../models/academic_models.dart';

class PlanScreen extends StatelessWidget {
  const PlanScreen({super.key, required this.student});
  final StudentProfile student;

  @override
  Widget build(BuildContext context) {
    const termNames = ['Spring 2027', 'Fall 2027', 'Spring 2028'];
    final perTerm = student.minimumCreditsPerTerm;
    return Scaffold(
      appBar: AppBar(title: const Text('Graduation plan'), actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.tune), tooltip: 'Plan settings')]),
      body: ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 28), children: [
        Text('A draft path to your target date.', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.black54)),
        const SizedBox(height: 18),
        Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('TARGET GRADUATION', style: TextStyle(fontSize: 11, letterSpacing: 1, fontWeight: FontWeight.w700, color: Colors.black54)),
          const SizedBox(height: 7),
          Row(children: [const Icon(Icons.flag_outlined, color: Color(0xFF461D7C)), const SizedBox(width: 9), Text(student.targetGraduation, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800))]),
          const SizedBox(height: 14),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Credits remaining'), Text('${student.remainingCredits}', style: const TextStyle(fontWeight: FontWeight.w700))]),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Terms in this sample plan'), const Text('3', style: TextStyle(fontWeight: FontWeight.w700))]),
          const Divider(height: 22),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Simple minimum per term', style: TextStyle(fontWeight: FontWeight.w700)), Text('$perTerm credits', style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF461D7C)))]),
        ]))),
        const SizedBox(height: 20),
        const SectionTitle('Semester outline'),
        for (var i = 0; i < termNames.length; i++) ...[
          _TermCard(term: termNames[i], credits: (student.remainingCredits - perTerm * i).clamp(0, perTerm).toInt(), index: i),
          if (i < termNames.length - 1) const Padding(padding: EdgeInsets.only(left: 28), child: SizedBox(height: 16, child: VerticalDivider(width: 1, color: Color(0xFFD7CBE6)))),
        ],
        const SizedBox(height: 14),
        Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xFFFFF8E1), borderRadius: BorderRadius.circular(16)), child: const Text('This is only a credit-hour sketch using sample records and three assumed terms. Course requirements, prerequisites, term availability, and LSU rules are not included.', style: TextStyle(fontSize: 12, height: 1.4, color: Color(0xFF684B0B)))),
      ]),
    );
  }
}

class _TermCard extends StatelessWidget {
  const _TermCard({required this.term, required this.credits, required this.index});
  final String term;
  final int credits;
  final int index;

  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(15), child: Row(children: [
    Container(width: 36, height: 36, decoration: BoxDecoration(color: const Color(0xFFF0EAF7), borderRadius: BorderRadius.circular(11)), child: Center(child: Text('${index + 1}', style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF461D7C))))),
    const SizedBox(width: 12),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(term, style: const TextStyle(fontWeight: FontWeight.w700)), const SizedBox(height: 4), const Text('Course selection will be added after requirements are defined', style: TextStyle(fontSize: 11, color: Colors.black54))])),
    Text(creditLabel(credits), style: const TextStyle(fontWeight: FontWeight.w800)),
  ])));
}


