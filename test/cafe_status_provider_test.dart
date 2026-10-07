// تست Provider وضعیت کافه: باز/بسته کردن، نگه‌داشتن وضعیت قبلی در خطا و
// جلوگیری از درخواست هم‌زمان. Repository ساختگی، پس بدون شبکه.
import 'dart:async';

import 'package:cafe_book_admin/core/errors/app_failure.dart';
import 'package:cafe_book_admin/core/errors/result.dart';
import 'package:cafe_book_admin/core/utils/view_state.dart';
import 'package:cafe_book_admin/models/cafe_status.dart';
import 'package:cafe_book_admin/providers/cafe_status_provider.dart';
import 'package:cafe_book_admin/repositories/cafe_status_repository.dart';
import 'package:flutter_test/flutter_test.dart';

const _closed = CafeStatus(isOpen: false);
const _open = CafeStatus(
  isOpen: true,
  openedAt: null,
  closedAt: null,
);

/// Repository قابل‌کنترل: نتیجه هر متد را خود تست عوض می‌کند و برای «در
/// جریان بودن» می‌تواند پاسخ را تا باز شدن قفل عقب بیندازد.
class _FakeRepository implements CafeStatusRepository {
  Result<CafeStatus> status = const Success(_closed);

  /// وقتی ست باشد، open/close قبل از پاسخ منتظر [Completer.future] می‌مانند.
  Completer<Result<CafeStatus>>? gate;

  int getCalls = 0;
  int openCalls = 0;
  int closeCalls = 0;

  @override
  Future<Result<CafeStatus>> getStatus() async {
    getCalls++;
    return status;
  }

  @override
  Future<Result<CafeStatus>> open() {
    openCalls++;
    final g = gate;
    if (g != null) return g.future;
    return Future.value(status);
  }

  @override
  Future<Result<CafeStatus>> close() {
    closeCalls++;
    final g = gate;
    if (g != null) return g.future;
    return Future.value(status);
  }
}

void main() {
  late _FakeRepository repo;
  late CafeStatusProvider provider;

  setUp(() {
    repo = _FakeRepository();
    provider = CafeStatusProvider(repo);
  });

  test('starts as initial with nothing loaded', () {
    expect(provider.state.status, ViewStatus.initial);
    expect(provider.state.data, isNull);
    expect(provider.saving, isFalse);
  });

  group('load', () {
    test('load() fills the state from the repository', () async {
      var notified = 0;
      provider.addListener(() => notified++);
      await provider.load();
      expect(provider.state.status, ViewStatus.success);
      expect(provider.state.data?.isOpen, isFalse);
      expect(repo.getCalls, 1);
      expect(notified, greaterThanOrEqualTo(2)); // loading + success
    });

    test('load() failure keeps previous data and shows retry state', () async {
      await provider.load();
      repo.status = Failure(AppFailure.network());
      await provider.load();
      expect(provider.state.status, ViewStatus.error);
      expect(provider.state.failure?.type, FailureType.network);
      expect(provider.state.data?.isOpen, isFalse); // داده قبلی حفظ شد
      expect(repo.getCalls, 2);
    });
  });

  group('open / close', () {
    test('open() flips the state and returns no failure', () async {
      repo.status = const Success(_open);
      final failure = await provider.open();
      expect(failure, isNull);
      expect(provider.saving, isFalse);
      expect(provider.state.status, ViewStatus.success);
      expect(provider.state.data?.isOpen, isTrue);
      expect(repo.openCalls, 1);
    });

    test('close() flips an open cafe back to closed', () async {
      repo.status = const Success(_open);
      await provider.open();
      repo.status = const Success(_closed);
      final failure = await provider.close();
      expect(failure, isNull);
      expect(provider.state.data?.isOpen, isFalse);
      expect(repo.closeCalls, 1);
    });

    test('failure returns the failure and leaves the state untouched',
        () async {
      await provider.load();
      final before = provider.state.data;
      repo.status = Failure(AppFailure.network());
      final failure = await provider.open();
      expect(failure?.type, FailureType.network);
      expect(provider.state.data, same(before)); // هیچ تغییر صوری‌ای
      expect(provider.state.status, ViewStatus.success);
      expect(provider.saving, isFalse);
    });
  });

  group('concurrent guard', () {
    test('saving is true while a request is in flight', () async {
      repo.gate = Completer<Result<CafeStatus>>();
      repo.status = const Success(_open);
      final pending = provider.open();
      expect(provider.saving, isTrue);
      repo.gate!.complete(const Success(_open));
      await pending;
      expect(provider.saving, isFalse);
      expect(provider.state.data?.isOpen, isTrue);
    });

    test('a second request while saving is rejected without touching the repo',
        () async {
      repo.gate = Completer<Result<CafeStatus>>();
      final pending = provider.open();
      final second = await provider.close();
      expect(second?.type, FailureType.validation); // درخواست دوم رد شد
      expect(repo.closeCalls, 0); // هیچ درخواستی به منبع نرفت
      repo.gate!.complete(const Success(_open));
      await pending;
      expect(repo.openCalls, 1);
      expect(provider.state.data?.isOpen, isTrue);
    });
  });

  test('does not notify after dispose', () async {
    provider.dispose();
    await provider.load();
    expect(provider.state.status, ViewStatus.success);
  });
}