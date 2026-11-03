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

No Flutter analysis, widget tests, or builds have been run for this foundation yet.
