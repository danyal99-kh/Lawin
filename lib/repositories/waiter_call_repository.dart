import '../core/errors/result.dart';
import '../models/waiter_call.dart';

abstract interface class WaiterCallRepository {
  /// درخواست‌های فعال (`pending` + `acknowledged`) — معادل `GET /api/v1/waiter-calls/?active=1`.
  /// برای هشدار صوتی و نمایش روی کارت میزها استفاده می‌شود.
  Future<Result<List<WaiterCall>>> getActiveCalls();

  /// «دیدم»؛ گارسون رسیده است. صدا و تایمر این درخواست متوقف می‌شود.
  Future<Result<WaiterCall>> acknowledge(String callId);

  /// «انجام شد»؛ درخواست بسته می‌شود و از فهرست فعال حذف می‌گردد.
  Future<Result<WaiterCall>> complete(String callId);
}
