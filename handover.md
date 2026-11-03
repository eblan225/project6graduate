# Project 6 handover

Updated 3 November 2026. This document describes the current local checkout and separates the prototype from confirmed LSU requirements and verified behavior.

## Product goal

Build a phone-first Flutter app for LSU students. The student provides information from LSU Workday about classes completed or currently taken, plus their degree/program and applicable catalog requirements. The app should identify required classes still outstanding and estimate the minimum credit hours needed per semester to meet a selected graduation target.

The plan should show its assumptions, target term, remaining requirements, credit totals, and any course sequencing or term availability constraints used. Treat results as planning guidance for students to confirm with LSU advising and official degree audit information.

The approved input path is not known yet. Do not assume the app may sign in to, scrape, or connect directly to Workday. Confirm whether LSU permits a supported API, student-authorized export/import, or manual entry. Never collect Workday passwords.

## Current implementation

The default counter app has been replaced with a phone-first Flutter prototype using Material widgets and bottom navigation:

- Overview dashboard with sample degree progress, target date, and next steps.
- Course list with completed/current/planned filters and a manual course-entry sheet.
- Graduation-plan screen with a simple three-term credit sketch.
- Profile screen for sample academic details and Workday connection status.
- `StudentDataSource` abstraction in `lib/data/student_data_source.dart` separates screens from the current demo provider. The demo implementation in `lib/data/demo_student_data_source.dart` can later be replaced with an approved integration or import provider.
- Models in `lib/models/academic_models.dart` hold basic course and student records.

All displayed student/course records are synthetic examples, not actual LSU curriculum or degree audit data. Added course entries stay in memory and reset when the app restarts. The simple plan divides remaining credits over three assumed terms; it does not account for requirements, prerequisites, course availability, maximum loads, or LSU policies. Workday import is only a placeholder. Nothing connects to Workday or an LSU system.

## Repository and task tracking

- `README.md` has basic local run instructions and current limits.
- `docs/PROJECT_TASKS.md` is the end-to-end checklist for product decisions, Workday access, data models, planning, privacy, testing, and release.
- `test/widget_test.dart` is still the generated counter test and needs replacement with tests for the agreed app behaviors.

## Setup

Install a compatible Flutter SDK and platform toolchain. From the `project6graduate` folder:

```powershell
flutter pub get
flutter run
```

Useful checks when ready:

```powershell
flutter analyze
flutter test
```

## Verification status

No Flutter analysis, tests, or platform builds were run for this update. Workday access, LSU degree rules, sample calculation correctness, persistence, and data security have not been validated. Check `docs/PROJECT_TASKS.md` for remaining work.

## Immediate next steps

1. Confirm supported LSU programs, campuses, catalog years, and source of authoritative requirements.
2. Get LSU guidance on permitted student data access and select an approved Workday import/integration approach.
3. Define and validate course/degree requirement models and planning rules with advising stakeholders.
4. Implement persistence, requirement matching, and tests before presenting real graduation plans.

Do not present the prototype as an official LSU degree audit or guarantee of graduation eligibility.
