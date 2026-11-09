import 'package:file_selector/file_selector.dart';

Future<XFile?> pickCourseFile() => openFile(
  acceptedTypeGroups: const [
    XTypeGroup(
      label: 'Course files',
      extensions: ['xlsx', 'pdf'],
      uniformTypeIdentifiers: [
        'com.adobe.pdf',
        'org.openxmlformats.spreadsheetml.sheet',
      ],
    ),
  ],
);
