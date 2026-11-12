import 'package:flutter_test/flutter_test.dart';
import 'package:project6graduate/auth/google_auth.dart';
import 'package:project6graduate/auth/user_planning_data_cleanup.dart';
import 'package:project6graduate/degree_planning/degree_plan.dart';
import 'package:project6graduate/degree_planning/degree_plan_repository.dart';
import 'package:project6graduate/schedules/schedule.dart';
import 'package:project6graduate/schedules/schedule_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  test(
    'sign out removes both planning records but preserves other settings',
    () async {
      final schedules = PreferencesScheduleRepository();
      final degreePlans = PreferencesDegreePlanRepository();
      await schedules.save([
        SemesterSchedule(
          name: 'Fall 2026',
          classes: [ScheduleClass(name: 'MATH 1550')],
        ),
      ]);
      await degreePlans.save(_plan);
      final preferences = SharedPreferencesAsync();
      await preferences.setBool('unrelated_theme_setting', true);
      var identitySignOutCalled = false;

      final auth = GoogleAuth(
        planningDataCleanup: UserPlanningDataCleanup(
          schedules: schedules,
          degreePlans: degreePlans,
        ),
        signOutIdentity: () async {
          expect(await schedules.load(), isEmpty);
          expect(await degreePlans.load(), isNull);
          identitySignOutCalled = true;
        },
      );

      expect(await auth.signOut(), isTrue);
      expect(identitySignOutCalled, isTrue);
      expect(await schedules.load(), isEmpty);
      expect(await degreePlans.load(), isNull);
      expect(await preferences.getBool('unrelated_theme_setting'), isTrue);
      auth.dispose();
    },
  );

  test(
    'a later account cannot load the previous account planning records',
    () async {
      final schedules = PreferencesScheduleRepository();
      final degreePlans = PreferencesDegreePlanRepository();
      await schedules.save([
        SemesterSchedule(name: 'Spring 2027', classes: []),
      ]);
      await degreePlans.save(_plan);
      final auth = GoogleAuth(
        planningDataCleanup: UserPlanningDataCleanup(
          schedules: schedules,
          degreePlans: degreePlans,
        ),
        signOutIdentity: () async {},
      );

      expect(await auth.signOut(), isTrue);

      // The repositories are device-wide; after account A signs out, account B
      // must see empty storage rather than account A's records.
      final accountBSchedules = PreferencesScheduleRepository();
      final accountBDegreePlans = PreferencesDegreePlanRepository();
      expect(await accountBSchedules.load(), isEmpty);
      expect(await accountBDegreePlans.load(), isNull);
      auth.dispose();
    },
  );

  test(
    'cleanup failure cancels sign out and reports that the user is signed in',
    () async {
      var identitySignOutCalled = false;
      final auth = GoogleAuth(
        planningDataCleanup: UserPlanningDataCleanup(
          schedules: _MemoryScheduleRepository(),
          degreePlans: _FailingDegreePlanRepository(),
        ),
        signOutIdentity: () async {
          identitySignOutCalled = true;
        },
      );

      expect(await auth.signOut(), isFalse);
      expect(identitySignOutCalled, isFalse);
      expect(auth.error, contains('You are still signed in'));
      auth.dispose();
    },
  );
}

final _plan = DegreePlanInput(
  totalCreditsRequired: 120,
  completedCredits: 30,
  currentTermCredits: 15,
  currentTerm: AcademicTerm(2026, AcademicSeason.fall),
  targetTerm: AcademicTerm(2028, AcademicSeason.spring),
  includeSummer: false,
);

class _MemoryScheduleRepository implements ScheduleRepository {
  @override
  Future<void> clear() async {}

  @override
  Future<List<SemesterSchedule>> load() async => [];

  @override
  Future<void> save(List<SemesterSchedule> schedules) async {}
}

class _FailingDegreePlanRepository implements DegreePlanRepository {
  @override
  Future<void> clear() => Future.error(StateError('storage unavailable'));

  @override
  Future<DegreePlanInput?> load() async => null;

  @override
  Future<void> save(DegreePlanInput input) async {}
}
