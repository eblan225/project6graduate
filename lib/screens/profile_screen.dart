import 'package:flutter/material.dart';

import '../models/academic_models.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.student});
  final StudentProfile student;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Profile')),
    body: ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 28), children: [
      Center(child: Column(children: [
        CircleAvatar(radius: 38, backgroundColor: const Color(0xFFEDE5F6), child: Text(student.name.split(' ').map((part) => part[0]).take(2).join(), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 22, color: Color(0xFF461D7C)))),
        const SizedBox(height: 12),
        Text(student.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(student.major, style: const TextStyle(color: Colors.black54)),
        const SizedBox(height: 4),
        Text(student.college, style: const TextStyle(color: Colors.black54, fontSize: 12)),
      ])),
      const SizedBox(height: 26),
      const Text('ACADEMIC DETAILS', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1, fontSize: 11, color: Colors.black54)),
      const SizedBox(height: 8),
      Card(child: Column(children: [
        ListTile(leading: const Icon(Icons.school_outlined), title: const Text('Program'), subtitle: Text(student.major)),
        const Divider(height: 1, indent: 56),
        ListTile(leading: const Icon(Icons.flag_outlined), title: const Text('Target graduation'), subtitle: Text(student.targetGraduation), trailing: const Icon(Icons.chevron_right)),
        const Divider(height: 1, indent: 56),
        const ListTile(leading: Icon(Icons.calendar_view_month_outlined), title: Text('Catalog year'), subtitle: Text('Not set')),
      ])),
      const SizedBox(height: 18),
      const Text('DATA & CONNECTION', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1, fontSize: 11, color: Colors.black54)),
      const SizedBox(height: 8),
      Card(child: Column(children: [
        const ListTile(leading: Icon(Icons.cloud_sync_outlined), title: Text('LSU Workday'), subtitle: Text('Not connected'), trailing: Chip(label: Text('Coming later'))),
        const Divider(height: 1, indent: 56),
        const ListTile(leading: Icon(Icons.privacy_tip_outlined), title: Text('Privacy'), subtitle: Text('Connection method and data handling are not configured')),
      ])),
      const SizedBox(height: 16),
      const Text('Prototype profile uses synthetic sample data. Profile editing and account security will be added after product requirements are confirmed.', style: TextStyle(color: Colors.black54, fontSize: 12, height: 1.4)),
    ]),
  );
}
