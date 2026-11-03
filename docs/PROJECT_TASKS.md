# Project 6 product task list

This is the end-to-end checklist for the LSU degree-planning app. The app remains a Flutter mobile app. Items are checked only when the corresponding work exists in this repository; checks do not imply LSU approval or production readiness.

## 1. Product scope and LSU decisions

- [ ] Confirm the initial student audience and supported LSU campus/programs.
- [ ] Identify authoritative degree requirements and supported catalog years for each program.
- [ ] Define “graduate on time”: student-selected target term, program default, or both.
- [ ] Confirm the academic calendar rules, including summer terms and term boundaries.
- [ ] Establish requirements with LSU advising/registrar or another authorized LSU stakeholder.
- [ ] Define a process and owner for keeping degree rules and course offerings current.

## 2. Workday data access and import

- [ ] Ask LSU what student-authorized Workday integration or export method is permitted.
- [ ] Confirm whether the app will use a supported API, a student-downloaded report, or manual entry.
- [ ] Document required permissions, authentication, data fields, rate limits, and review requirements.
- [ ] Do not request or store Workday passwords; use an approved authentication flow if direct access is permitted.
- [ ] Define the import format and map Workday course, term, grade/status, credits, program, and catalog-year fields.
- [ ] Implement the approved data source behind `StudentDataSource` so screens remain independent of Workday details.
- [ ] Add import progress, clear errors, duplicate detection, and a way to retry or cancel.
- [ ] Let students review and correct imported records before saving them.
- [ ] Keep manual course entry available for corrections and students without import access.

## 3. Student and academic data foundation

- [x] Add initial course and student profile models for the app shell.
- [x] Add a `StudentDataSource` interface and a clearly labeled synthetic demo implementation.
- [ ] Define validated models for courses, terms, grades, transfer/AP credit, requirements, prerequisites, and catalog years.
- [ ] Define course states: completed, in progress, planned, withdrawn, and repeated where applicable.
- [ ] Decide what data is stored on device, in a service, or not stored.
- [ ] Add persistence and migration strategy for student profile, course history, and saved plans.
- [ ] Add data export, correction, deletion, and account reset behavior as required.

## 4. Degree requirement and planning engine

- [ ] Model total-credit, general-education, major, concentration, elective, and other program requirements.
- [ ] Represent alternatives, minimum grades, prerequisite/corequisite rules, and course substitutions.
- [ ] Track term availability and credit-hour ranges for courses when authoritative data is available.
- [ ] Match completed and in-progress courses to requirement slots and flag uncertain matches for review.
- [ ] Calculate remaining course and credit requirements without double-counting courses.
- [ ] Build a semester planner for the selected graduation term, honoring prerequisites and term availability.
- [ ] Calculate the minimum feasible credits per term and flag targets that cannot be met from available terms.
- [ ] Support student constraints such as preferred term load, summer enrollment, and already planned courses.
- [ ] Explain assumptions, unresolved requirements, and why each course appears in a plan.
- [ ] Validate calculations against adviser-reviewed examples for every supported program/catalog year.
- [ ] Never claim an estimate is an official degree audit or guarantee of graduation eligibility.

## 5. Flutter mobile app experience

- [x] Replace the default counter with a phone-first Flutter app shell and bottom navigation.
- [x] Add overview, course list, semester-plan, and profile screens.
- [x] Add manual course-entry UI and completed/current/planned course filters.
- [x] Clearly label synthetic demo records and unconfigured Workday integration.
- [ ] Add onboarding for program, catalog year, credits, and target graduation term.
- [ ] Add a guided Workday import and record-review flow for the approved access method.
- [ ] Show requirements satisfied, remaining, and needing student/adviser review.
- [ ] Show a semester-by-semester plan with course choices, prerequisites, credit totals, and alternatives.
- [ ] Let students edit constraints and compare saved plan scenarios.
- [ ] Add loading, empty, offline, permission-denied, and recoverable error states.
- [ ] Check accessibility, text scaling, screen-reader semantics, keyboard use, and color contrast.
- [ ] Confirm supported phone platforms and test layouts on representative screen sizes.

## 6. Privacy, security, and compliance

- [ ] Complete a data inventory and privacy review with LSU requirements before connecting student records.
- [ ] Define consent, purpose limitation, retention, deletion, and breach-response policies.
- [ ] Minimize collected data and avoid logging course history or sensitive identifiers.
- [ ] Secure any backend transport, tokens, secrets, storage, and access controls.
- [ ] Review university/vendor terms and applicable student-record obligations with the responsible LSU office.
- [ ] Document privacy practices in the app before collecting real student data.
- [ ] Verify that the app never collects Workday credentials directly.

## 7. Quality, testing, and operations

- [ ] Add unit tests for credit totals, requirement matching, remaining-credit calculations, and term planning.
- [ ] Add tests for import parsing, validation, duplicates, and malformed or partial records.
- [ ] Add Flutter widget tests for onboarding, course review, editing, plan changes, and failure states.
- [ ] Add integration tests for the authorized import method and app data flow using synthetic accounts/data.
- [ ] Run `flutter analyze`, `flutter test`, and platform builds in CI.
- [ ] Test offline behavior, upgrade/migration behavior, and data recovery.
- [ ] Set up crash/error monitoring without collecting student course data in telemetry.
- [ ] Define support, incident response, and LSU curriculum-data update procedures.

## 8. Pilot and release

- [ ] Review the app and sample plans with LSU advisers and representative students.
- [ ] Pilot with synthetic or explicitly authorized data before broader use.
- [ ] Resolve pilot findings and publish known limitations.
- [ ] Prepare app-store listing, support contact, privacy materials, and release process.
- [ ] Obtain all required LSU approvals before production Workday access or real-record use.
- [ ] Release only after access, privacy, calculation validation, and operational readiness are approved.

## Current verification

No Flutter analysis, tests, or platform builds have been run for the new app shell yet. Workday access, LSU requirements, and calculation correctness are not implemented or validated.
