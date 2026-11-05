import 'package:flutter/material.dart';

import '../ui/app_theme.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key, required this.onContinue});
  final VoidCallback onContinue;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: AppPage(
        children: [
          const SizedBox(height: 56),
          const Align(
            alignment: Alignment.centerLeft,
            child: CircleAvatar(
              radius: 32,
              backgroundColor: Color(0xFFECE8FF),
              child: Icon(
                Icons.school_outlined,
                size: 34,
                color: AppStyle.purple,
              ),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Graduate!',
            style: TextStyle(
              fontSize: 38,
              fontWeight: FontWeight.w800,
              color: AppStyle.purple,
              letterSpacing: -1.5,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'A little planning.\nA clearer path ahead.',
            style: Theme.of(context).textTheme.headlineMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          const Text(
            'Keep your semesters in one place. Add your classes, shape your schedule, and take the next step toward graduation.',
            style: TextStyle(
              height: 1.6,
              color: Color(0xFF767085),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 40),
          FilledButton(onPressed: onContinue, child: const Text('Get started')),
          const SizedBox(height: 16),
          const Text(
            'Layout preview • No account needed',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Sign-in and file import are coming later. For now, try manual schedule entry. Your schedules stay in memory for this session.',
                style: TextStyle(height: 1.5),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
