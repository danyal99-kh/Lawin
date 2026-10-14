import 'package:flutter/foundation.dart';

import '../core/errors/app_failure.dart';
import '../core/errors/result.dart';
import '../core/utils/view_state.dart';
import '../models/offer.dart';
import '../repositories/offer_repository.dart';

/// مدیریت آفر/تخفیف: بارگذاری فهرست، پیش‌نمایش و فعال/غیرفعال‌سازی.
///
/// محاسبه‌ی قیمت مؤثر سمت سرور انجام می‌شود؛ این Provider فقط هماهنگ‌کننده است.
class OfferProvider extends ChangeNotifier {
  OfferProvider(this._repository);

  final OfferRepository _repository;

  ViewState<List<Offer>> _state = const ViewState.initial();
  ViewState<List<Offer>> get state => _state;
  List<Offer> get offers => _state.data ?? const [];

  bool _disposed = false;

  Future<void> load({int? productId, int? categoryId, bool? activeOnly}) async {
    final previous = _state.data;
    _state = ViewState<List<Offer>>.loading(previous: previous);
    _notify();
    final result = await _repository.getOffers(
        productId: productId, categoryId: categoryId, activeOnly: activeOnly);
    _state = result.when<ViewState<List<Offer>>>(
      success: (list) => ViewState<List<Offer>>.success(list),
      failure: (f) => ViewState<List<Offer>>.error(f, previous: previous),
    );
    _notify();
  }

  /// پیش‌نمایش بدون تغییر؛ نتیجه برای نمایش قیمت قبل/بعد و گرفتن اثر انگشت است.
  Future<Result<OfferPreview>> preview(OfferRequest request) =>
      _repository.preview(request);

  /// فعال‌سازی آفر با اثر انگشت پیش‌نمایش. null یعنی موفق.
  Future<AppFailure?> activate(
    OfferRequest request, {
    required String fingerprint,
    String? idempotencyKey,
  }) async {
    final result = await _repository.activate(request,
        fingerprint: fingerprint, idempotencyKey: idempotencyKey);
    final failure = result.failureOrNull;
    if (failure != null) return failure;
    _upsert(result.dataOrNull!);
    return null;
  }

  Future<AppFailure?> deactivate(int id) async {
    final result = await _repository.deactivate(id);
    final failure = result.failureOrNull;
    if (failure != null) return failure;
    _upsert(result.dataOrNull!);
    return null;
  }

  void _upsert(Offer saved) {
    final exists = offers.any((o) => o.id == saved.id);
    _state = ViewState<List<Offer>>.success(exists
        ? [for (final o in offers) o.id == saved.id ? saved : o]
        : [...offers, saved]);
    _notify();
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
