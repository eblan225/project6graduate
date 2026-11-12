import '../degree_planning/degree_plan_repository.dart';
import '../schedules/schedule_repository.dart';

/// Clears only the local records owned by the planning features.
class UserPlanningDataCleanup {
  const UserPlanningDataCleanup({
    required this.schedules,
    required this.degreePlans,
  });

  final ScheduleRepository schedules;
  final DegreePlanRepository degreePlans;

  Future<void> clear() async {
    await Future.wait<void>([schedules.clear(), degreePlans.clear()]);
  }
}
