import 'package:file_picker/file_picker.dart';

import '../core/errors/app_failure.dart';

import 'dart:io';

/// انتخاب تصویر از دستگاه (Android و Windows). UI فقط با این interface کار می‌کند؛
/// اگر نسخه‌ی file_picker تغییر کرد فقط همین فایل اصلاح می‌شود.
abstract interface class ImagePickerService {
  /// مسیر فایل انتخاب‌شده، یا null اگر کاربر انصراف داد.
  Future<String?> pickImagePath();

  /// فایل انتخاب‌شده، یا null اگر کاربر انصراف داد.
  Future<File?> pickImageFile();
}

class FilePickerImageService implements ImagePickerService {
  @override
  Future<String?> pickImagePath() async {
    try {
      final file = await FilePicker.pickFile(type: FileType.image);
      if (file == null) return null;
      return file.path;
    } catch (_) {
      throw AppFailure.validation('انتخاب تصویر انجام نشد. دوباره تلاش کنید.');
    }
  }

  @override
  Future<File?> pickImageFile() async {
    final path = await pickImagePath();
    if (path == null) return null;
    return File(path);
  }
}
