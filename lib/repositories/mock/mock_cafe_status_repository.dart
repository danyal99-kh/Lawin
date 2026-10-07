import 'package:cafe_book_admin/repositories/cafe_status_repository.dart';

import '../../core/errors/result.dart';
import '../../models/cafe_status.dart';

/// وضعیت کافه فقط در حافظه نگه‌داری می‌شود (بدون وابستگی به MockDatabase،
/// چون با هیچ Repository دیگری داده مشترک ندارد).
///
/// مقادیر اولیه عیناً پیش‌فرض‌های مدل Django هستند تا قرارداد پاسخ با حالت
/// واقعی یکی باشد: بسته، بدون هیچ زمانی تا اولین «باز کردن کافه».
class MockCafeStatusRepository implements CafeStatusRepository {
  CafeStatus _status = const CafeStatus(isOpen: false);

  Future<void> _latency() =>
      Future<void>.delayed(const Duration(milliseconds: 250));

  @override
  Future<Result<CafeStatus>> getStatus() async {
    await _latency();
    return Success(_status);
  }

  @override
  Future<Result<CafeStatus>> open() async {
    await _latency();
    if (_status.isOpen) return Success(_status);
    _status = CafeStatus(
      isOpen: true,
      openedAt: DateTime.now(),
      closedAt: null,
    );
    return Success(_status);
  }

  @override
  Future<Result<CafeStatus>> close() async {
    await _latency();
    if (!_status.isOpen) return Success(_status);
    _status = CafeStatus(
      isOpen: false,
      openedAt: _status.openedAt,
      closedAt: DateTime.now(),
    );
    return Success(_status);
  }
}
