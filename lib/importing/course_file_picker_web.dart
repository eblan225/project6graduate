import 'package:file_selector/file_selector.dart';
import 'package:file_selector_web/file_selector_web.dart';

/// Resolve the web implementation directly. A running Flutter debug session may
/// still have the old platform registry after adding a plugin through hot reload.
/// Call synchronously from the user's button press to preserve browser activation.
Future<XFile?> pickCourseFile() => FileSelectorWeb().openFile(
  acceptedTypeGroups: const [
    XTypeGroup(label: 'Course files', extensions: ['xlsx', 'pdf']),
  ],
);
