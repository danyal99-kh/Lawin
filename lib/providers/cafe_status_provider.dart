import 'package:cafe_book_admin/repositories/cafe_status_repository.dart';
import 'package:flutter/foundation.dart';

import '../core/errors/app_failure.dart';
import '../core/errors/result.dart';
import '../core/utils/view_state.dart';
import '../models/cafe_status.dart';

/// وضعیت کافه در پنل. UI فقط این Provider را می‌خواند، نه Repository را.
///
/// باز/بسته کردن از طریق API انجام می‌شود؛ اگر درخواست شکست بخورد، وضعیت قبلی
/// دست‌نخورده می‌ماند (هیچ تغییر صوری‌ای در UI رخ نمی‌دهد) و همان خطا به
/// صفحه برمی‌گردد تا SnackBar نشان داده شود.
class CafeStatusProvider extends ChangeNotifier {
  CafeStatusProvider(this._repository);

  final CafeStatusRepository _repository;

  ViewState<CafeStatus> _state = const ViewState.initial();
  ViewState<CafeStatus> get state => _state;

  /// true یعنی یک درخواست باز/بسته کردن در جریان است؛ دکمه باید غیرفعال باشد.
  bool _saving = false;
  bool get saving => _saving;

  bool _disposed = false;

  /// بارگذاری/تازه‌سازی. داده‌ی قبلی هنگام بارگذاری مجدد نگه داشته می‌شود.
  Future<void> load() async {
    final previous = _state.data;
    _state = ViewState<CafeStatus>.loading(previous: previous);
    _notify();
    final result = await _repository.getStatus();
    _state = result.when<ViewState<CafeStatus>>(
      success: (data) => ViewState<CafeStatus>.success(data),
      failure: (f) => ViewState<CafeStatus>.error(f, previous: previous),
    );
    _notify();
  }

  /// null یعنی موفق؛ در غیر این صورت خطای قابل‌نمایش.
  Future<AppFailure?> open() => _set(_repository.open);

  /// null یعنی موفق؛ در غیر این صورت خطای قابل‌نمایش.
  Future<AppFailure?> close() => _set(_repository.close);

  Future<AppFailure?> _set(Future<Result<CafeStatus>> Function() action) async {
    // دکمه هنگام ارسال غیرفعال است؛ این نگهبان برای فراخوانی‌های موازی است
    // تا درخواست دومی ارسال نشود و پیام موفقیت جعلی نشان داده نشود.
    if (_saving) {
      return AppFailure.validation('تغییر وضعیت کافه در حال انجام است.');
    }
    _saving = true;
    _notify();
    final result = await action();
    AppFailure? failure;
    result.when<void>(
      success: (data) => _state = ViewState<CafeStatus>.success(data),
      // خطا: state قبلی دست نمی‌خورد تا وضعیت کافه به‌صورت جعلی عوض نشود.
      failure: (f) => failure = f,
    );
    _saving = false;
    _notify();
    return failure;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }
}
