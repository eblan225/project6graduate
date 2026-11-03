import 'package:flutter/material.dart';

import 'data/demo_student_data_source.dart';
import 'models/academic_models.dart';
import 'screens/courses_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/plan_screen.dart';
import 'screens/profile_screen.dart';

void main() {
  runApp(const TigerTrackApp());
}

class TigerTrackApp extends StatefulWidget {
  const TigerTrackApp({super.key});

  @override
  State<TigerTrackApp> createState() => _TigerTrackAppState();
}

class _TigerTrackAppState extends State<TigerTrackApp> {
  final dataSource = DemoStudentDataSource();
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final student = dataSource.student;
    final pages = [
      DashboardScreen(student: student, onOpenCourses: () => _select(1)),
      CoursesScreen(dataSource: dataSource, onChanged: _refresh),
      PlanScreen(student: student),
      ProfileScreen(student: student),
    ];

    return MaterialApp(
      title: 'TigerTrack',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF461D7C),
          primary: const Color(0xFF461D7C),
          secondary: const Color(0xFFFDD023),
          surface: const Color(0xFFF8F6FB),
        ),
        scaffoldBackgroundColor: const Color(0xFFF8F6FB),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF8F6FB),
          surfaceTintColor: Colors.transparent,
          titleTextStyle: TextStyle(
            color: Color(0xFF21152B),
            fontSize: 21,
            fontWeight: FontWeight.w700,
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFFECE7F1)),
          ),
        ),
      ),
      home: Scaffold(
        body: SafeArea(child: IndexedStack(index: selectedIndex, children: pages)),
        bottomNavigationBar: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: _select,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.space_dashboard_outlined), selectedIcon: Icon(Icons.space_dashboard), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book), label: 'Courses'),
            NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month), label: 'Plan'),
            NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }

  void _select(int index) => setState(() => selectedIndex = index);

  void _refresh() => setState(() {});
}

String creditLabel(int credits) => '$credits ${credits == 1 ? 'credit' : 'credits'}';

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.action, this.onAction});
  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          if (action != null)
            TextButton(onPressed: onAction, child: Text(action!)),
        ],
      );
}
