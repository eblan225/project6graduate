# TigerTrack (Project 6)

A phone-first Flutter foundation for the intended LSU degree-planning app. The current build supports locally saved semester schedules and a configurable credit-load estimate; Workday access and verified LSU degree requirements remain future work.

It is not connected to LSU Workday and does not contain verified LSU degree requirements. Do not enter Workday credentials into the app.

## Run locally

From this directory, with a compatible Flutter SDK installed:

```powershell
flutter pub get
flutter run
```

The app includes Google sign-in or a guest preview, a welcome flow, semester list and templates, manual schedule editing, and a degree credit planner. Google OAuth needs platform setup; see [Google sign-in setup](docs/GOOGLE_SIGN_IN.md). Schedule data and degree-plan inputs are stored locally on the device and are not synced to an account or cloud service.

## Project docs

- [Handover](handover.md): product goal, current architecture, and known limits.
- [Product task list](docs/PROJECT_TASKS.md): end-to-end implementation, validation, and release checklist.

## Current status

Students can create semesters, add/edit/remove class entries, and remove semesters. The credit planner accepts total required credits, completed credits, current-term credits, current term, target graduation term, and summer preference. It calculates the remaining credit load and distributes it across future terms. Students can also enter course codes completed/in progress and course codes required by their audit; the app shows required codes missing from the entered history. This manual comparison does not validate LSU requirements or match substitutions, and the credit estimate does not account for prerequisites or course availability. Workday access and authoritative LSU rules are not implemented.

Local formatting, `flutter analyze`, all Flutter tests, and the Android debug APK build passed. GitHub Actions is configured in `.github/workflows/flutter-ci.yml`; its first hosted run is pending.

Commit `b63126a1ad80fb0a1d92779e9c3b2f8021ee74fd` refreshes the semester's class count when returning to the list after adding or removing a class. ECC confirmed this fix by source inspection and `git diff --check` passed; Flutter tests and emulator checks were not run for this fix.

## Mockup-based starting screens

The current entry flow is Graduate!: sign-in/guest choice → degree timeline preferences → semester schedules → manual semester entry → editable class list / calendar preview. The degree credit planner is available from the schedules page. Older academic scaffolding remains in the source for future integration. Google sign-in is an identity scaffold and does not enable cloud sync. File upload and timed calendar placement are placeholders; goals remain in the session while schedules and credit-plan inputs persist locally.

To change the layout later:

- `lib/ui/app_theme.dart`: shared colors, control styles, page padding, maximum content width, and reusable page/empty-state widgets.
- `lib/schedules/`: separate welcome, schedule list, creation, and semester detail screens.
- `lib/schedules/schedule.dart`: serialized semester and class records, separate from degree planning models.
- `lib/main.dart`: app entry and navigation into the schedule flow.

Manual entry accepts one class per line, with an optional `|` followed by meeting-time notes. Tap a class to edit it, or use Add class. Calendar mode currently displays a clearly marked preview and the entered notes; it does not interpret times or place classes on a weekly grid.

The starting screen collects a major and a 2-, 4-, or 5-year degree program length. A final-semester summary below the selection assumes two semesters per academic year; calendar dates depend on the student’s start date. The My goals and Semesters tabs separate these preferences from semester schedule editing and preserve both while switching tabs during a session. These preferences do not yet drive graduation calculations and reset when the app restarts.

## Google sign-in

The app now opens with Google sign-in or a guest preview. Google Cloud OAuth registration is required to activate sign-in; see [platform setup instructions](docs/GOOGLE_SIGN_IN.md). Google identity does not yet enable cloud saving. Signing out clears session-only goals and schedules.

Degree timelines now collect the first Fall/Spring term and year plus the student's current semester number. The final semester and count after the current semester use two semesters per academic year, excluding summers. Continue to schedules saves these preferences for the session. New schedule forms offer every semester from that starting date as a name template and default to the current semester; names remain editable. Changing the timeline updates templates without renaming existing schedules. Remaining required courses are not inferred from elapsed semesters.

## Visual course planning

Course map provides a reusable blank Computer Engineering 2026–27 flowchart template: tap or drag courses between semesters, inspect solid prerequisite and dotted co-requisite arrows, choose elective placeholders, review sequencing/term conflicts, and copy a semester into a schedule. If the selected semester has no unfinished map courses, loading map courses shows a message and keeps the current class list. No personal spreadsheet data or grades are preloaded. See [course map notes](docs/COURSE_MAP.md) for source limitations and editable data/layout files.


File import is now available under **Course map → Import XLSX / PDF** and **New schedule → Import XLSX / PDF**. Imports have a course-review step and add/replace confirmation. Spreadsheet grades and personal progress are excluded. The supported EEC PDF uses a matching predefined flowchart; other text PDFs require credit/placement review and manual dependency arrows. Scanned PDFs are not supported yet.
