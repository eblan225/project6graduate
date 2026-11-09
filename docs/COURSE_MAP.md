# Reusable Computer Engineering course map

Source: user-supplied `eec_flowchart_2026-2027.pdf`, one-page 2026–27 Computer Engineering advising chart. The template contains 43 course/requirement slots totaling 127 credits. It is a manual transcription, not a connection to the LSU catalog or a validated degree audit.

The supplied `View_My_Academic_Progress.xlsx` was inspected only to understand the shape of requirement/status/registration/period/credit/grade fields. No personal records, grades, course history, academic periods, or inferred completions are included in the app, assets, or tests. No spreadsheet is bundled or automatically imported. Students can now explicitly choose a local file through Import XLSX / PDF.

## Use

1. Save a first term/year and current semester in My goals.
2. Open Course map. The blank-progress template starts with the flowchart's suggested eight-semester placement. If a different major was entered, this remains an explicitly labeled Computer Engineering template; it does not infer another major's requirements.
3. Tap a course to move it, choose an elective, or enter progress/grade manually. Long-press a course and drop it onto a semester header to move it visually. Pan or pinch to inspect the diagram; Fit map zooms out.
4. Solid arrows require earlier completion; dotted arrows allow the same semester or earlier. Tap a course to highlight its incoming/outgoing connections; its dialog lists incoming dependencies in text. C means minimum C under the user's requested interpretation. C- and blank/pass/transfer grades remain flagged where a C is needed rather than silently counting as satisfied.
5. Review flags ordering conflicts, the chart's Fall/Spring restrictions, unchosen electives, courses outside the selected program duration or before the current semester, and the Senior Design I 90-credit/one-of condition. The 90-credit forecast includes earlier planned courses; it is not an earned-credit certification.
6. Make schedule copies a selected semester's planned/in-progress classes into Semesters. Copies are independent and never overwrite existing schedules. Meeting times are blank. Completed courses are excluded from that copy.

Reset template clears diagram moves, elective choices, and entered progress after confirmation, but leaves existing semester copies alone. Everything remains session-only and is cleared on sign-out/app restart.

## Data and extension points

- `lib/planner/course_template.dart`: reusable course slots, credit hours, minimum grades, term flags, breadth choices, and directed dependency edges.
- `lib/planner/course_plan.dart`: per-session placements, progress, elective selections, and review rules.
- `lib/planner/course_map_screen.dart`: diagram layout, arrows, interactions, course editor, and schedule-copy action.

Elective placeholders retain distinct IDs so that two design, technical, or humanities slots cannot accidentally become one requirement. Entering an elective name does not verify that it belongs to an approved elective group. Only breadth choices explicitly printed on the supplied chart are offered as preset choices. Their additional catalog prerequisites are not invented or checked. Courses marked with an asterisk in the chart may have further downstream use depending on elective choice.

The spreadsheet and chart use differing course numbers for introductory ECE/design courses (1810/2810 versus 1820/2820). No equivalence is assumed: the template uses the chart's numbers. Grade C-range wording on the chart may differ from the requested at-least-C interpretation; advising should confirm how C- and transfer credit apply. Live course availability, placement rules, substitutions, repeat handling, transfer equivalencies, and official requirements need catalog/advisor validation before relying on this plan.


## File import

Import XLSX / PDF is available in Course map and New schedule. Select a file, review courses, edit missing credits/placement or deselect rows, choose add versus replace, and confirm Apply reviewed import. Canceling file selection or confirmation leaves the map unchanged. Files are read locally, are not uploaded, and are not persisted by the app.

XLSX supports the supplied academic-progress column structure (Registrations Used and Credit Hours), or Course/Course code/Course ID plus Credits/Credit Hours, with optional Title and Semester number columns. Grades, progress status, and academic periods are discarded. Duplicate course codes are collapsed to the first occurrence; repeated attempts and grade histories are not imported. Semester defaults for matching built-in course codes are suggestions only; unmatched codes start in semester 1 and are editable. No introductory-course equivalencies are assumed.

PDF supports text-based files. A matching full EEC 2026–27 chart uses the built-in, manually transcribed template and its arrows after review. This is recognition of a supported chart, not general extraction of graphical arrow geometry. Other text PDFs yield detected course codes and require credit entry and placement review. Scanned/image-only PDFs need OCR and are not supported. Password-protected/damaged/unsupported files show a read error. Files are limited to 10 MB, PDFs to 30 pages, and decompressed spreadsheets to 20 MB.

For any course, Add dependency lets students create a solid prerequisite or dotted co-requisite arrow from another course; existing incoming arrows can also be removed in the editor. Saving applies the edited arrows; Cancel discards dependency changes. Replacing a map clears its prior progress and moves. Adding courses keeps existing IDs and does not duplicate or overwrite them. Semester schedule copies remain independent.

In New schedule, import first, then Use this semester’s map courses to fill the manual class-entry field for the chosen semester. Inspect the diagram and review warnings before finalizing a plan.

Verification uses synthetic spreadsheet fixtures and synthetic PDF text only. Personal academic records are not test fixtures. iOS device verification requires the Apple SDK/toolchain, which is not installed in this environment.


### Chrome debug picker initialization

The web picker is invoked through the web implementation directly, rather than depending on plugin registration captured when an older `flutter run -d chrome` session started. File selection is initiated from the button press without an asynchronous setup step. Picker-opening failures are distinguished from errors reading a selected file; canceling selection clears no data and displays no read error. Native builds still use normal plugin registration and require a full stop/relaunch after adding native plugins.
