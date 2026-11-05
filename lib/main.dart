import 'package:flutter/material.dart';

import 'ui/app_theme.dart';
import 'schedules/welcome_screen.dart';
import 'schedules/schedules_screen.dart';

void main() => runApp(const TigerTrackApp());

class TigerTrackApp extends StatelessWidget {
  const TigerTrackApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Graduate!',
    debugShowCheckedModeBanner: false,
    theme: AppStyle.theme,
    home: const _StartScreen(),
  );
}

class _StartScreen extends StatelessWidget {
  const _StartScreen();
  @override
  Widget build(BuildContext context) => WelcomeScreen(
    onContinue: () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(builder: (_) => const SchedulesScreen()),
      );
    },
  );
}

String creditLabel(int credits) =>
    '$credits ${credits == 1 ? 'credit' : 'credits'}';

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.action, this.onAction});
  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        title,
        style: Theme.of(context).textTheme.titleLarge
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
      if (action != null) TextButton(onPressed: onAction, child: Text(action!)),
    ],
  );
}
