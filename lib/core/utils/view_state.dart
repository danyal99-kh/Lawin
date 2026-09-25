import '../errors/app_failure.dart';

enum ViewStatus { initial, loading, success, empty, error }

/// وضعیت استاندارد یک صفحه/بخش برای Loading / Error / Empty / Retry.
/// همه‌ی Providerها از همین ساختار استفاده می‌کنند تا اتصال به API بعداً یکدست باشد.
class ViewState<T> {
  const ViewState._(this.status, {this.data, this.failure});

  const ViewState.initial() : this._(ViewStatus.initial);
  const ViewState.loading({T? previous})
      : this._(ViewStatus.loading, data: previous);
  const ViewState.success(T data) : this._(ViewStatus.success, data: data);
  const ViewState.empty() : this._(ViewStatus.empty);
  const ViewState.error(AppFailure failure, {T? previous})
      : this._(ViewStatus.error, failure: failure, data: previous);

  final ViewStatus status;
  final T? data;
  final AppFailure? failure;

  bool get isLoading => status == ViewStatus.loading;
  bool get hasData => data != null;
}
