import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/errors/app_failure.dart';
import '../core/errors/result.dart';
import '../core/utils/view_state.dart';
import '../models/waiter_call.dart';
import '../repositories/waiter_call_repository.dart';
import '../services/waiter_alert_service.dart';

/// وضعیت درخواست‌های گارسون + هشدار صوتی تکرارشونده.
/// منطق این کلاس (کدام درخواست فعال است، کِی باید صدا بخورد، کِی تایمر باید
/// متوقف شود) فقط همین‌جاست؛ صفحه‌ها فقط می‌خوانند و درخواست می‌فرستند.
class WaiterCallProvider extends ChangeNotifier {
  WaiterCallProvider(
    this._repository, {
    WaiterAlerter? alerter,
    this.reminderInterval = defaultReminderInterval,
  }) : _alerter = alerter ?? const SystemWaiterAlerter();

  /// فاصله‌ی یادآوری صدا برای درخواست‌های «در انتظار» (الزام محصول: هر ۳۰ ثانیه).
  static const Duration defaultReminderInterval = Duration(seconds: 30);

  final WaiterCallRepository _repository;
  final WaiterAlerter _alerter;
  final Duration reminderInterval;

  ViewState<List<WaiterCall>> _state = const ViewState.initial();
  ViewState<List<WaiterCall>> get state => _state;

  final Set<String> _busy = {};
  bool _disposed = false;
  Timer? _reminder;

  List<WaiterCall> get calls => _state.data ?? const [];

  /// فقط `pending`؛ این‌ها هستند که هشدار صوتی می‌گیرند.
  List<WaiterCall> get pending => [
        for (final c in calls)
          if (c.isPending) c
      ];

  List<WaiterCall> get acknowledged => [
        for (final c in calls)
          if (c.isAcknowledged) c
      ];

  bool get hasPending => pending.isNotEmpty;
  int get pendingCount => pending.length;

  /// درخواست فعالِ یک میز، برای نمایش روی کارت میز.
  /// [fallback] (همان `waiter_call` توکارِ جدولِ میز) فقط تا وقتی استفاده می‌شود که
  /// لیستِ فعال هنوز از سرور نیامده باشد؛ بعد از آن Provider منبع حقیقت است تا
  /// درخواست «انجام‌شده» دوباره از روی داده‌ی کهنه ظاهر نشود.
  WaiterCall? callForTable(int tableId, {WaiterCall? fallback}) {
    for (final c in calls) {
      if (c.tableId == tableId && c.isActive) return c;
    }
    return _state.data == null ? fallback : null;
  }

  bool isBusy(String callId) => _busy.contains(callId);
  bool get busy => _busy.isNotEmpty;

  /// بارگذاری اولیه در استارتاپ و همچنین بازیابی بعد از قطع Realtime.
  Future<void> load() async {
    final previous = _state.data;
    _state = previous == null
        ? const ViewState<List<WaiterCall>>.loading()
        : ViewState<List<WaiterCall>>.loading(previous: previous);
    _notify();
    final result = await _repository.getActiveCalls();
    _state = result.when<ViewState<List<WaiterCall>>>(
      success: (list) => _sorted(list),
      failure: (f) => ViewState<List<WaiterCall>>.error(f, previous: previous),
    );
    _reconcileReminder();
    _notify();
  }

  /// «دیدم»؛ بعد از این صدا و تایمر آن درخواست قطع می‌شود.
  /// در صورت خطای قابل‌نمایش، همان را برمی‌گرداند.
  Future<AppFailure?> acknowledge(String callId) =>
      _run(callId, () => _repository.acknowledge(callId));

  /// «انجام شد»؛ درخواست از فهرست فعال حذف می‌شود.
  Future<AppFailure?> complete(String callId) =>
      _run(callId, () => _repository.complete(callId));

  WaiterCall? callById(String id) {
    for (final c in calls) {
      if (c.id == id) return c;
    }
    return null;
  }

  /// اعمال رویداد Realtime. `completed` یعنی حذف از فعال‌ها؛ بقیه upsert.
  /// [alert] فقط برای ورودِ درخواستِ تازه‌ی «در انتظار» صدا می‌زند؛ صدای چرخه‌ای
  /// کارِ تایمر است تا با ری‌لود صفحه صدا تکرار نشود.
  void applyCall(WaiterCall call, {bool alert = true}) {
    final list = [...calls];
    final index = list.indexWhere((c) => c.id == call.id);
    final wasPending = index >= 0 && list[index].isPending;
    if (call.isCompleted) {
      if (index >= 0) list.removeAt(index);
    } else if (index == -1) {
      list.add(call);
    } else {
      list[index] = call;
    }
    _state = _sorted(list);
    _reconcileReminder();
    _notify();
    if (alert && call.isPending && !wasPending) _playAlert();
  }

  /// توقف یادآوری صوتی؛ وقتی دیگر درخواست «در انتظار» نیست یا Provider از کار افتاد.
  void stop() {
    _reminder?.cancel();
    _reminder = null;
  }

  Future<AppFailure?> _run(
    String callId,
    Future<Result<WaiterCall>> Function() action,
  ) async {
    if (_busy.contains(callId)) return null;
    _busy.add(callId);
    _notify();
    final result = await action();
    AppFailure? failure;
    result.when<void>(
      success: applyCall,
      failure: (f) => failure = f,
    );
    _busy.remove(callId);
    _notify();
    return failure;
  }

  ViewState<List<WaiterCall>> _sorted(List<WaiterCall> list) =>
      ViewState<List<WaiterCall>>.success([
        ...list..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
      ]);

  /// تایمر یادآوری فقط وقتی درخواست «در انتظار» داریم فعال است.
  void _reconcileReminder() {
    if (hasPending) {
      _reminder ??= Timer.periodic(reminderInterval, (_) => _playAlert());
    } else {
      stop();
    }
  }

  void _playAlert() {
    if (_disposed || !hasPending) return;
    // خطای پخش صدا نباید جریان اپ را بشکند.
    _alerter.play().catchError((Object _) {});
  }

  @override
  void dispose() {
    _disposed = true;
    stop();
    super.dispose();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }
}
