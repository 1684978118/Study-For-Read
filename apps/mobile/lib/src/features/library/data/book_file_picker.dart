import 'dart:io';

import 'package:file_picker/file_picker.dart';

abstract interface class BookFilePicker {
  Future<File?> pickBookFile();
}

class PlatformBookFilePicker implements BookFilePicker {
  const PlatformBookFilePicker();

  @override
  Future<File?> pickBookFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['txt', 'epub'],
      withData: false,
    );
    final path = result?.files.single.path;
    if (path == null) {
      return null;
    }
    return File(path);
  }
}
