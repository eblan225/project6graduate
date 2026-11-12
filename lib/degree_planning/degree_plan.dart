enum AcademicSeason { spring, summer, fall }

class AcademicTerm implements Comparable<AcademicTerm> {
  const AcademicTerm(this.year, this.season);

  final int year;
  final AcademicSeason season;

  String get label =>
      '${season.name[0].toUpperCase()}${season.name.substring(1)} $year';

  int get _sortKey => year * AcademicSeason.values.length + season.index;

  factory AcademicTerm.fromDate(DateTime date) {
    final season = switch (date.month) {
      <= 4 => AcademicSeason.spring,
      <= 7 => AcademicSeason.summer,
      _ => AcademicSeason.fall,
    };
    return AcademicTerm(date.year, season);
  }

  AcademicTerm next({bool includeSummer = true}) {
    if (!includeSummer && season == AcademicSeason.summer) {
      return AcademicTerm(year, AcademicSeason.fall);
    }
    final seasons = includeSummer
        ? AcademicSeason.values
        : const [AcademicSeason.spring, AcademicSeason.fall];
    final index = seasons.indexOf(season);
    if (index < 0 || index == seasons.length - 1) {
      return AcademicTerm(year + 1, seasons.first);
    }
    return AcademicTerm(year, seasons[index + 1]);
  }

  Map<String, Object?> toJson() => {'year': year, 'season': season.name};

  factory AcademicTerm.fromJson(Map<String, Object?> json) {
    final year = json['year'];
    final seasonName = json['season'];
    final season = AcademicSeason.values.where(
      (value) => value.name == seasonName,
    );
    if (year is! int || season.isEmpty) {
      throw const FormatException('Saved academic term is invalid.');
    }
    return AcademicTerm(year, season.first);
  }

  @override
  int compareTo(AcademicTerm other) => _sortKey.compareTo(other._sortKey);

  @override
  bool operator ==(Object other) =>
      other is AcademicTerm && year == other.year && season == other.season;

  @override
  int get hashCode => Object.hash(year, season);
}

class DegreePlanInput {
  const DegreePlanInput({
    required this.totalCreditsRequired,
    required this.completedCredits,
    required this.currentTermCredits,
    required this.currentTerm,
    required this.targetTerm,
    required this.includeSummer,
    this.completedCourseCodes = const [],
    this.requiredCourseCodes = const [],
  });

  final int totalCreditsRequired;
  final int completedCredits;
  final int currentTermCredits;
  final AcademicTerm currentTerm;
  final AcademicTerm targetTerm;
  final bool includeSummer;
  final List<String> completedCourseCodes;
  final List<String> requiredCourseCodes;

  Map<String, Object?> toJson() => {
    'totalCreditsRequired': totalCreditsRequired,
    'completedCredits': completedCredits,
    'currentTermCredits': currentTermCredits,
    'currentTerm': currentTerm.toJson(),
    'targetTerm': targetTerm.toJson(),
    'includeSummer': includeSummer,
    'completedCourseCodes': completedCourseCodes,
    'requiredCourseCodes': requiredCourseCodes,
  };

  factory DegreePlanInput.fromJson(Map<String, Object?> json) {
    final total = json['totalCreditsRequired'];
    final completed = json['completedCredits'];
    final currentCredits = json['currentTermCredits'];
    final currentTerm = json['currentTerm'];
    final targetTerm = json['targetTerm'];
    final includeSummer = json['includeSummer'];
    final completedCourses = json['completedCourseCodes'] ?? const <Object?>[];
    final requiredCourses = json['requiredCourseCodes'] ?? const <Object?>[];
    if (total is! int ||
        completed is! int ||
        currentCredits is! int ||
        currentTerm is! Map ||
        targetTerm is! Map ||
        includeSummer is! bool ||
        completedCourses is! List ||
        requiredCourses is! List ||
        completedCourses.any((code) => code is! String) ||
        requiredCourses.any((code) => code is! String)) {
      throw const FormatException('Saved degree plan is invalid.');
    }
    return DegreePlanInput(
      totalCreditsRequired: total,
      completedCredits: completed,
      currentTermCredits: currentCredits,
      currentTerm: AcademicTerm.fromJson(
        Map<String, Object?>.from(currentTerm),
      ),
      targetTerm: AcademicTerm.fromJson(Map<String, Object?>.from(targetTerm)),
      includeSummer: includeSummer,
      completedCourseCodes: List<String>.from(completedCourses),
      requiredCourseCodes: List<String>.from(requiredCourses),
    );
  }
}

class TermCreditLoad {
  const TermCreditLoad({required this.term, required this.credits});

  final AcademicTerm term;
  final int credits;
}

class DegreePlanEstimate {
  const DegreePlanEstimate({
    required this.earnedOrCurrentCredits,
    required this.futureCreditsNeeded,
    required this.minimumCreditsPerTerm,
    required this.termLoads,
    required this.remainingCourseCodes,
  });

  final int earnedOrCurrentCredits;
  final int futureCreditsNeeded;
  final int minimumCreditsPerTerm;
  final List<TermCreditLoad> termLoads;
  final List<String> remainingCourseCodes;
}

class DegreePlanner {
  const DegreePlanner._();

  static final _courseCodePattern = RegExp(r'^([A-Z]+) ?([0-9]+[A-Z]*)$');

  static DegreePlanEstimate? calculate(DegreePlanInput input) {
    if (input.totalCreditsRequired <= 0 ||
        input.completedCredits < 0 ||
        input.currentTermCredits < 0 ||
        input.targetTerm.compareTo(input.currentTerm) <= 0) {
      return null;
    }

    final terms = <AcademicTerm>[];
    var term = input.currentTerm.next(includeSummer: input.includeSummer);
    while (term.compareTo(input.targetTerm) <= 0) {
      if (input.includeSummer || term.season != AcademicSeason.summer) {
        terms.add(term);
      }
      term = term.next(includeSummer: input.includeSummer);
    }
    if (terms.isEmpty || terms.last != input.targetTerm) return null;

    final countedCredits = input.completedCredits + input.currentTermCredits;
    final remaining = (input.totalCreditsRequired - countedCredits)
        .clamp(0, input.totalCreditsRequired)
        .toInt();
    final minimumPerTerm = remaining == 0
        ? 0
        : (remaining / terms.length).ceil();
    var creditsLeft = remaining;
    final loads = <TermCreditLoad>[];
    for (var i = 0; i < terms.length; i++) {
      final termsLeft = terms.length - i;
      final creditsThisTerm = creditsLeft == 0
          ? 0
          : (creditsLeft / termsLeft).ceil();
      loads.add(TermCreditLoad(term: terms[i], credits: creditsThisTerm));
      creditsLeft -= creditsThisTerm;
    }

    return DegreePlanEstimate(
      earnedOrCurrentCredits: countedCredits,
      futureCreditsNeeded: remaining,
      minimumCreditsPerTerm: minimumPerTerm,
      termLoads: List.unmodifiable(loads),
      remainingCourseCodes: List.unmodifiable(_remainingCourseCodes(input)),
    );
  }

  static List<String> _remainingCourseCodes(DegreePlanInput input) {
    final completed = input.completedCourseCodes
        .map(_normalizeCourseCode)
        .toSet();
    return input.requiredCourseCodes
        .map(_normalizeCourseCode)
        .where((code) => code.isNotEmpty && !completed.contains(code))
        .toSet()
        .toList()
      ..sort();
  }

  static String _normalizeCourseCode(String code) {
    final normalized = code.trim().toUpperCase().replaceAll(
      RegExp(r'\s+'),
      ' ',
    );
    final match = _courseCodePattern.firstMatch(normalized);
    if (match == null) return normalized;
    return '${match[1]} ${match[2]}';
  }
}
