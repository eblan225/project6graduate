# Project 6 handover

Updated 5 November 2026. This handover distinguishes the current schedule prototype from the intended LSU degree-planning product.

## Product goal

The intended app is a phone-first LSU degree planner. Students should be able to provide course history and program/catalog information, identify remaining requirements, and estimate semester loads for a target graduation date. Workday access and authoritative LSU curriculum data are not yet available or implemented. Never collect Workday passwords or present a prototype plan as an official degree audit.

## Current app functionality

The active app flow is titled **Graduate!** and supports manual semester schedules:

- Create a semester schedule with a name and one or more class entries.
- Optionally enter plain-text meeting-time notes after `|` when creating the schedule.
- Add or edit individual classes and their meeting-time notes.
- Remove a class or delete a semester after confirmation.
- Open a Calendar preview; it lists entered class notes but does not parse times or draw a real weekly calendar.
- Save schedules locally and restore them on app launch. No account or cloud sync is used.
- Open the Degree credit planner from the school icon on the schedule list.
- Enter the total credit requirement from an official audit, completed credits, current-term credits, current term, graduation target, and whether summer terms are part of the plan.
- Optionally enter completed/in-progress course codes and required course codes from an audit; the planner compares normalized codes and lists requirements not found in the completed/in-progress list.
- Calculate the credits remaining after the current term and an even future-term load through the selected graduation term. Plan inputs are saved locally.

`ScheduleRepository` and `DegreePlanRepository` separate app screens from storage. Their preferences implementations store JSON using Flutter shared preferences. `ScheduleClass`, `SemesterSchedule`, and `DegreePlanInput` define local records and JSON mapping. `DegreePlanner` is a pure calculation module for the future-term credit estimate. `TigerTrackApp` accepts a schedule repository override for testability.

The older `lib/models/academic_models.dart`, `lib/data/`, and `lib/screens/` files are scaffolding for course-level degree planning and are not part of the active Graduate! navigation flow. The current planner can compare manually supplied course-code lists, but it does not import Workday data or verify that the manually supplied requirements are complete or correct for a student's program/catalog year. Its credit estimate uses aggregate totals and does not account for prerequisites, course availability, credit caps, or LSU policies.

The app now starts with a Google sign-in or guest-preview gate. Google OAuth platform setup is documented in `docs/GOOGLE_SIGN_IN.md`; sign-in is not configured until those platform credentials are supplied, and it does not provide cloud sync. Degree timeline preferences are kept in the active session. Sign-in/out resets those session preferences, while semester schedules and degree-plan inputs remain saved locally on the device.

## Persistence and data limits

Local preferences are convenient for this prototype, but schedules and degree inputs can reveal personal information. Shared preferences are not encrypted storage, cloud backup, or a durable database guarantee. Do not store passwords or secrets there. If saved JSON cannot be decoded, the app shows an error state and leaves the stored value untouched instead of replacing it with empty data.

## Repository guide

- `lib/main.dart`: app entry, welcome route, and repository injection.
- `lib/auth/`: Google identity adapter, sign-in UI, and guest-preview gate.
- `lib/models/degree_timeline.dart`: Fall/Spring timeline used by welcome preferences and semester name templates.
- `lib/schedules/`: schedule model, repository, list, creation, and detail flows.
- `lib/degree_planning/`: configurable degree-credit inputs, academic term handling, estimator, and persistence.
- `lib/ui/app_theme.dart`: shared theme and page widgets.
- `test/widget_test.dart`: schedule create/edit and reload behavior using an in-memory test repository.
- `test/degree_plan_test.dart`: future-term credit distribution, summer inclusion, target-term validation, and course-code matching.
- `test/degree_plan_screen_test.dart`: saved estimate display and update behavior.
- `docs/PROJECT_TASKS.md`: overall LSU product implementation and release checklist.
- `.github/workflows/flutter-ci.yml`: format, analyze, test, and Android debug build job.

## Local setup

From the `project6graduate` directory:

```powershell
flutter pub get
flutter run
```

Checks used by CI:

```powershell
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --debug
```

## Remaining work

1. Confirm LSU-approved Workday/API/export access and supported degree requirement sources.
2. Define the student, course-history, catalog, requirement, and course-offering models.
3. Import completed/in-progress courses and authoritative requirements, then replace the simple code-list comparison with validated requirement-slot matching.
4. Expand the estimator to honor specific remaining courses, prerequisites, availability, and approved load constraints.
5. Add secure account/data handling only after LSU privacy and access requirements are known.
6. Replace the placeholder Calendar preview with structured meeting-day/time support if a real weekly calendar remains in scope.

No live Workday connection, LSU rule verification, course conflict detection, or official audit capability is present.
