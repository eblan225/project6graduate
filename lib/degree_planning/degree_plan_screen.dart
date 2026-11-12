import 'package:material_ui/material_ui.dart';

import '../ui/app_theme.dart';
import 'degree_plan.dart';
import 'degree_plan_repository.dart';

class DegreePlanScreen extends StatefulWidget {
  const DegreePlanScreen({super.key, this.repository});

  final DegreePlanRepository? repository;

  @override
  State<DegreePlanScreen> createState() => _DegreePlanScreenState();
}

class _DegreePlanScreenState extends State<DegreePlanScreen> {
  final formKey = GlobalKey<FormState>();
  final totalCreditsController = TextEditingController();
  final completedCreditsController = TextEditingController();
  final currentCreditsController = TextEditingController();
  final completedCoursesController = TextEditingController();
  final requiredCoursesController = TextEditingController();

  late final DegreePlanRepository repository;
  late AcademicTerm currentTerm;
  late AcademicTerm targetTerm;
  bool includeSummer = false;
  bool loading = true;
  String? loadError;
  String? planError;
  DegreePlanEstimate? estimate;

  @override
  void initState() {
    super.initState();
    repository = widget.repository ?? PreferencesDegreePlanRepository();
    currentTerm = AcademicTerm.fromDate(DateTime.now());
    targetTerm = currentTerm.next(includeSummer: false);
    _load();
  }

  @override
  void dispose() {
    totalCreditsController.dispose();
    completedCreditsController.dispose();
    currentCreditsController.dispose();
    completedCoursesController.dispose();
    requiredCoursesController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      loadError = null;
    });
    try {
      final saved = await repository.load();
      if (!mounted) return;
      if (saved != null) {
        totalCreditsController.text = '${saved.totalCreditsRequired}';
        completedCreditsController.text = '${saved.completedCredits}';
        currentCreditsController.text = '${saved.currentTermCredits}';
        completedCoursesController.text = saved.completedCourseCodes.join('\n');
        requiredCoursesController.text = saved.requiredCourseCodes.join('\n');
        currentTerm = saved.currentTerm;
        targetTerm = saved.targetTerm;
        includeSummer = saved.includeSummer;
        estimate = DegreePlanner.calculate(saved);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        loadError = 'Saved degree-plan inputs could not be read. They were left untouched.';
      });
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _calculateAndSave() async {
    if (!formKey.currentState!.validate()) return;
    final input = DegreePlanInput(
      totalCreditsRequired: int.parse(totalCreditsController.text),
      completedCredits: int.parse(completedCreditsController.text),
      currentTermCredits: int.parse(currentCreditsController.text),
      currentTerm: currentTerm,
      targetTerm: targetTerm,
      includeSummer: includeSummer,
      completedCourseCodes: _parseCourseCodes(completedCoursesController.text),
      requiredCourseCodes: _parseCourseCodes(requiredCoursesController.text),
    );
    final result = DegreePlanner.calculate(input);
    if (result == null) {
      setState(() {
        planError = 'Choose a graduation term after your current term. Enable summer if your target is a summer term.';
        estimate = null;
      });
      return;
    }
    setState(() {
      planError = null;
      estimate = result;
    });
    try {
      await repository.save(input);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'The estimate is ready, but could not be saved on this device.',
          ),
        ),
      );
    }
  }

  List<AcademicTerm> get terms {
    final firstYear = DateTime.now().year - 2;
    return [
      for (var year = firstYear; year <= firstYear + 12; year++)
        for (final season in AcademicSeason.values) AcademicTerm(year, season),
    ];
  }

  List<String> _parseCourseCodes(String value) => value
      .split(RegExp(r'[,\n;]'))
      .map((code) => code.trim().toUpperCase().replaceAll(RegExp(r'\s+'), ' '))
      .where((code) => code.isNotEmpty)
      .toSet()
      .toList();

  String? _validateCredits(String? value, {required bool allowZero}) {
    final credits = int.tryParse(value ?? '');
    if (credits == null) return 'Enter a whole number';
    if (credits < (allowZero ? 0 : 1) || credits > 300) {
      return allowZero ? 'Enter 0–300 credits' : 'Enter 1–300 credits';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Degree credit planner')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : loadError != null
          ? AppPage(
              children: [
                const SizedBox(height: 48),
                EmptyPanel(
                  icon: Icons.storage_outlined,
                  title: 'Could not load your plan',
                  message: loadError!,
                ),
                const SizedBox(height: 16),
                FilledButton(onPressed: _load, child: const Text('Try again')),
              ],
            )
          : AppPage(
              children: [
                Text(
                  'Estimate the credit load to reach your graduation term.',
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                const _Notice(
                  text: 'Enter the credit requirement from your official degree audit. This estimate does not read Workday or know which LSU courses your program requires.',
                ),
                const SizedBox(height: 20),
                Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: totalCreditsController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Total credits required for your degree',
                          helperText: 'Use the total shown by your official LSU degree audit.',
                        ),
                        validator: (value) =>
                            _validateCredits(value, allowZero: false),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: completedCreditsController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Credits completed before this term',
                        ),
                        validator: (value) =>
                            _validateCredits(value, allowZero: true),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: currentCreditsController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Credits in progress this term',
                        ),
                        validator: (value) =>
                            _validateCredits(value, allowZero: true),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: completedCoursesController,
                        minLines: 2,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          labelText: 'Courses completed or in progress',
                          helperText: 'Optional. Enter course codes, one per line (example: MATH 1550).',
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: requiredCoursesController,
                        minLines: 2,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          labelText: 'Required course codes from your audit',
                          helperText: 'Optional. Remaining codes are calculated by matching this list above.',
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<AcademicTerm>(
                        initialValue: currentTerm,
                        decoration: const InputDecoration(
                          labelText: 'Current term',
                        ),
                        items: terms
                            .map(
                              (term) => DropdownMenuItem(
                                value: term,
                                child: Text(term.label),
                              ),
                            )
                            .toList(),
                        onChanged: (term) {
                          if (term != null) setState(() => currentTerm = term);
                        },
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<AcademicTerm>(
                        initialValue: targetTerm,
                        decoration: const InputDecoration(
                          labelText: 'Target graduation term',
                        ),
                        items: terms
                            .map(
                              (term) => DropdownMenuItem(
                                value: term,
                                child: Text(term.label),
                              ),
                            )
                            .toList(),
                        onChanged: (term) {
                          if (term != null) setState(() => targetTerm = term);
                        },
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Include summer terms'),
                        subtitle: const Text(
                          'Only count summer if you expect to take classes then.',
                        ),
                        value: includeSummer,
                        onChanged: (value) =>
                            setState(() => includeSummer = value),
                      ),
                      if (planError != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          planError!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: _calculateAndSave,
                        icon: const Icon(Icons.calculate_outlined),
                        label: const Text('Calculate and save'),
                      ),
                    ],
                  ),
                ),
                if (estimate case final result?) ...[
                  const SizedBox(height: 24),
                  _EstimateSummary(estimate: result),
                  if (result.remainingCourseCodes.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    Text(
                      'Required courses still to take',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(result.remainingCourseCodes.join('  •  ')),
                      ),
                    ),
                  ] else if (requiredCoursesController.text
                      .trim()
                      .isNotEmpty) ...[
                    const SizedBox(height: 18),
                    const Text(
                      'All listed course requirements are completed or in progress.',
                    ),
                  ],
                  const SizedBox(height: 18),
                  Text(
                    'Suggested future term loads',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  for (final load in result.termLoads)
                    Card(
                      child: ListTile(
                        leading: const Icon(
                          Icons.calendar_month_outlined,
                          color: AppStyle.purple,
                        ),
                        title: Text(load.term.label),
                        trailing: Text(
                          '${load.credits} credits',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  const SizedBox(height: 14),
                  const _Notice(
                    text: 'Course matching uses only the codes you entered. This evenly distributes remaining credits across future terms and does not account for prerequisites, course availability, credit caps, or LSU policy.',
                  ),
                ],
              ],
            ),
    );
  }
}

class _EstimateSummary extends StatelessWidget {
  const _EstimateSummary({required this.estimate});
  final DegreePlanEstimate estimate;

  @override
  Widget build(BuildContext context) => Card(
    color: AppStyle.purple.withValues(alpha: 0.08),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CREDIT LOAD ESTIMATE',
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 1,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${estimate.futureCreditsNeeded} credits left after this term',
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            'Plan for about ${estimate.minimumCreditsPerTerm} credits per future term across ${estimate.termLoads.length} terms.',
          ),
          const SizedBox(height: 6),
          Text(
            '${estimate.earnedOrCurrentCredits} completed or in-progress credits counted.',
            style: const TextStyle(color: Color(0xFF767085)),
          ),
        ],
      ),
    ),
  );
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF8E1),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.info_outline, size: 18, color: Color(0xFF8A6410)),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              height: 1.4,
              color: Color(0xFF684B0B),
            ),
          ),
        ),
      ],
    ),
  );
}
