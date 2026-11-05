# TigerTrack (Project 6)

A phone-first Flutter app foundation for helping LSU students understand what degree requirements remain and estimate a semester-by-semester path to a target graduation date.

The current build is a prototype shell with synthetic sample data. It is not connected to LSU Workday and does not contain verified LSU degree requirements. The Workday import action is intentionally a placeholder until LSU confirms an approved access method. Do not enter Workday credentials into the app.

## Run locally

From this directory, with a compatible Flutter SDK installed:

```powershell
flutter pub get
flutter run
```

The app includes overview, courses, graduation plan, and profile tabs. Course entries added in the prototype live only in memory and reset when the app restarts.

## Project docs

- [Handover](handover.md): product goal, current architecture, and known limits.
- [Product task list](docs/PROJECT_TASKS.md): end-to-end implementation, validation, and release checklist.

## Current status

Flutter phone-first UI and a replaceable `StudentDataSource` boundary are in place. The demo implementation uses synthetic records, not LSU curriculum data. Planning currently shows a simple evenly divided credit estimate; it does not match requirements, prerequisites, course offerings, or actual LSU rules.

Local formatting, analysis, the widget test, and Android debug APK build have passed. GitHub Actions is configured in `.github/workflows/flutter-ci.yml`; its first hosted run is pending.

## Mockup-based starting screens

The current entry flow is Graduate!: welcome → empty schedules → manual semester entry → editable class list / calendar preview. The previous academic demo screens and data-source boundary remain available in the source for future integration. No account credentials are collected. File upload, authentication, and timed calendar placement are placeholders; schedules reset on app restart.

To change the layout later:

- `lib/ui/app_theme.dart`: shared colors, control styles, page padding, maximum content width, and reusable page/empty-state widgets.
- `lib/schedules/`: separate welcome, schedule list, creation, and semester detail screens.
- `lib/schedules/schedule.dart`: session-only schedule records, separate from degree planning models.
- `lib/main.dart`: app entry and navigation into the schedule flow.

Manual entry accepts one class per line, with an optional `|` followed by meeting-time notes. Tap a class to edit it, or use Add class. Calendar mode currently displays a clearly marked preview and the entered notes; it does not interpret times or place classes on a weekly grid.

The starting screen collects a major and a 2-, 4-, or 5-year degree program length. A final-semester summary below the selection assumes two semesters per academic year; calendar dates depend on the student’s start date. The My goals and Semesters tabs separate these preferences from semester schedule editing and preserve both while switching tabs during a session. These preferences do not yet drive graduation calculations and reset when the app restarts.

## Google sign-in

The app now opens with Google sign-in or a guest preview. Google Cloud OAuth registration is required to activate sign-in; see [platform setup instructions](docs/GOOGLE_SIGN_IN.md). Google identity does not yet enable cloud saving. Signing out clears session-only goals and schedules.

Degree timelines now collect the first Fall/Spring term and year plus the student's current semester number. The final semester and count after the current semester use two semesters per academic year, excluding summers. Continue to schedules saves these preferences for the session. New schedule forms offer every semester from that starting date as a name template and default to the current semester; names remain editable. Changing the timeline updates templates without renaming existing schedules. Remaining required courses are not inferred from elapsed semesters.
