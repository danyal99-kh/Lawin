import 'package:file_picker/file_picker.dart';

import '../core/errors/app_failure.dart';

/// انتخاب تصویر از دستگاه (Android و Windows). UI فقط با این interface کار می‌کند؛
/// اگر نسخه‌ی file_picker تغییر کرد فقط همین فایل اصلاح می‌شود.
abstract interface class ImagePickerService {
  /// مسیر فایل انتخاب‌شده، یا null اگر کاربر انصراف داد.
  Future<String?> pickImagePath();
}

class FilePickerImageService implements ImagePickerService {
  @override
  Future<String?> pickImagePath() async {
    try {
      final result = await FilePicker.platform
          .pickFiles(type: FileType.image, allowMultiple: false);
      if (result == null || result.files.isEmpty) return null;
      return result.files.single.path;
    } catch (_) {
      throw AppFailure.validation('انتخاب تصویر انجام نشد. دوباره تلاش کنید.');
    }
  }
}
