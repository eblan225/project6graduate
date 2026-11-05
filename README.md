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
