// تست UI درخواست گارسون:
//  - روی کارت میز فقط وقتی درخواست فعال وجود دارد نوار دیده می‌شود.
//  - دکمه‌های «دیدم» و «انجام شد» همان درخواست را به Provider می‌فرستند.
//  - پنل داشبورد همه‌ی درخواست‌های فعال را با شمارنده‌ی «در انتظار» نشان می‌دهد.
import 'package:cafe_book_admin/core/errors/app_failure.dart';
import 'package:cafe_book_admin/core/errors/result.dart';
import 'package:cafe_book_admin/models/cafe_table.dart';
import 'package:cafe_book_admin/models/enums.dart';
import 'package:cafe_book_admin/models/table_overview.dart';
import 'package:cafe_book_admin/models/waiter_call.dart';
import 'package:cafe_book_admin/pages/dashboard/widgets/waiter_calls_panel.dart';
import 'package:cafe_book_admin/pages/tables/widgets/table_card.dart';
import 'package:cafe_book_admin/pages/tables/widgets/waiter_call_banner.dart';
import 'package:cafe_book_admin/providers/waiter_call_provider.dart';
import 'package:cafe_book_admin/repositories/waiter_call_repository.dart';
import 'package:cafe_book_admin/services/waiter_alert_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

WaiterCall call({
  String id = 'call-1',
  int tableId = 2,
  WaiterCallStatus status = WaiterCallStatus.pending,
}) =>
    WaiterCall(
      id: id,
      tableId: tableId,
      tableNumber: tableId,
      status: status,
      createdAt: DateTime.now().subtract(const Duration(minutes: 3)),
    );

TableOverview overview({WaiterCall? waiterCall, int tableId = 2}) =>
    TableOverview(
      table:
          CafeTable(id: tableId, number: tableId, status: TableStatus.active),
      waiterCall: waiterCall,
    );

/// Repository ساختگی با رفتار واقع‌گرایانه (فقط pending → acknowledged).
class _FakeRepository implements WaiterCallRepository {
  _FakeRepository(this.stored);
  List<WaiterCall> stored;
  AppFailure? error;
  final List<String> actions = [];

  @override
  Future<Result<List<WaiterCall>>> getActiveCalls() async => Success([
        for (final c in stored)
          if (c.isActive) c
      ]);

  @override
  Future<Result<WaiterCall>> acknowledge(String id) async {
    actions.add('ack:$id');
    if (error != null) return Failure(error!);
    final updated = stored
        .firstWhere((c) => c.id == id)
        .copyWith(status: WaiterCallStatus.acknowledged);
    stored = [
      for (final c in stored)
        if (c.id == id) updated else c
    ];
    return Success(updated);
  }

  @override
  Future<Result<WaiterCall>> complete(String id) async {
    actions.add('complete:$id');
    if (error != null) return Failure(error!);
    final updated = stored
        .firstWhere((c) => c.id == id)
        .copyWith(status: WaiterCallStatus.completed);
    stored = [
      for (final c in stored)
        if (c.id == id) updated else c
    ];
    return Success(updated);
  }
}

/// صدا در تست‌های ویجت لازم نیست.
class _SilentAlerter implements WaiterAlerter {
  @override
  Future<void> play() async {}
}

Future<void> pumpCard(
  WidgetTester tester, {
  required TableOverview overview,
  WaiterCall? waiterCall,
  ValueChanged<WaiterCall>? onAcknowledge,
  ValueChanged<WaiterCall>? onComplete,
}) =>
    tester.pumpWidget(MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: TableCard(
            overview: overview,
            onTap: () {},
            waiterCall: waiterCall,
            onAcknowledgeWaiter: onAcknowledge,
            onCompleteWaiter: onComplete,
          ),
        ),
      ),
    ));

void main() {
  group('TableCard waiter call', () {
    testWidgets('no active call means no banner', (tester) async {
      await pumpCard(tester, overview: overview());

      expect(find.byType(WaiterCallBanner), findsNothing);
    });

    testWidgets('a pending call shows the age and both actions',
        (tester) async {
      await pumpCard(tester,
          overview: overview(),
          waiterCall: call(),
          onAcknowledge: (_) {},
          onComplete: (_) {});

      expect(find.byType(WaiterCallBanner), findsOneWidget);
      expect(find.text('درخواست گارسون • ۳ دقیقه پیش'), findsOneWidget);
      expect(find.text('دیدم'), findsOneWidget);
      expect(find.text('انجام شد'), findsOneWidget);
      expect(find.text('در انتظار'), findsOneWidget);
    });

    testWidgets('an acknowledged call hides the acknowledge action',
        (tester) async {
      await pumpCard(tester,
          overview: overview(),
          waiterCall: call(status: WaiterCallStatus.acknowledged),
          onAcknowledge: (_) {},
          onComplete: (_) {});

      expect(find.byType(WaiterCallBanner), findsOneWidget);
      expect(find.text('دیدم'), findsNothing);
      expect(find.text('انجام شد'), findsOneWidget);
      expect(find.text('در حال رسیدن'), findsOneWidget);
    });

    testWidgets('tapping the actions sends the call id up', (tester) async {
      final acked = <String>[];
      final done = <String>[];
      await pumpCard(tester,
          overview: overview(),
          waiterCall: call(),
          onAcknowledge: (c) => acked.add(c.id),
          onComplete: (c) => done.add(c.id));

      await tester.tap(find.text('دیدم'));
      await tester.tap(find.text('انجام شد'));
      await tester.pump();

      expect(acked, ['call-1']);
      expect(done, ['call-1']);
    });

    testWidgets('the card renders exactly the call the page passes',
        (tester) async {
      await pumpCard(tester,
          overview: overview(waiterCall: call(id: 'from-overview')),
          waiterCall: call(id: 'from-provider'),
          onAcknowledge: (_) {},
          onComplete: (_) {});

      expect(find.text('دیدم'), findsOneWidget);
      expect(
        find.textContaining('۳ دقیقه'),
        findsOneWidget,
        reason: 'همان درخواستی که Provider داده است',
      );
    });

    testWidgets(
        'after complete the stale overview waiter_call does not come back',
        (tester) async {
      // overview هنوز درخواست «در انتظار» را در خود دارد (نتیجه‌ی بارگذاری اولیه)،
      // ولی Provider با موفقیت بارگذاری شده و درخواستی برای این میز ندارد.
      final provider = WaiterCallProvider(
        _FakeRepository([]),
        alerter: _SilentAlerter(),
        reminderInterval: const Duration(hours: 1),
      );
      addTearDown(provider.dispose);
      await provider.load();

      expect(
        provider.callForTable(2, fallback: call()),
        isNull,
        reason: 'بعد از بارگذاری، داده‌ی کهنه‌ی overview نباید بنر را برگرداند',
      );
      await pumpCard(tester,
          overview: overview(waiterCall: call()),
          waiterCall: provider.callForTable(2, fallback: call()));
      expect(find.byType(WaiterCallBanner), findsNothing);
    });

    testWidgets('the overview fallback is used until the first load finishes',
        (tester) async {
      final provider = WaiterCallProvider(
        _FakeRepository([]),
        alerter: _SilentAlerter(),
        reminderInterval: const Duration(hours: 1),
      );
      addTearDown(provider.dispose);

      expect(provider.callForTable(2, fallback: call())?.id, 'call-1');
    });
  });

  group('WaiterCallsPanel', () {
    Future<WaiterCallProvider> pumpPanel(
      WidgetTester tester,
      _FakeRepository repository,
    ) async {
      // تایمر یادآوری در این تست نباید باقی بماند؛ Provider در پایان dispose می‌شود.
      final provider = WaiterCallProvider(
        repository,
        alerter: _SilentAlerter(),
        reminderInterval: const Duration(hours: 1),
      );
      addTearDown(provider.dispose);
      await provider.load();
      await tester.pumpWidget(ChangeNotifierProvider<WaiterCallProvider>.value(
        value: provider,
        child: MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: const Scaffold(body: WaiterCallsPanel()),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      return provider;
    }

    testWidgets('lists every active call with the pending badge',
        (tester) async {
      final repo = _FakeRepository([
        call(id: 'a', tableId: 2),
        call(id: 'b', tableId: 7, status: WaiterCallStatus.acknowledged),
      ]);

      final provider = await pumpPanel(tester, repo);

      expect(find.text('درخواست‌های گارسون'), findsOneWidget);
      expect(find.text('میز ۲'), findsOneWidget);
      expect(find.text('میز ۷'), findsOneWidget);
      expect(find.text('۱ در انتظار'), findsOneWidget);
      // «دیدم» فقط برای درخواست‌های در انتظار
      expect(find.text('دیدم'), findsOneWidget);
      expect(find.text('انجام شد'), findsNWidgets(2));
      provider.stop();
    });

    testWidgets('shows an empty view when nothing is pending', (tester) async {
      await pumpPanel(tester, _FakeRepository([]));

      expect(find.text('درخواست فعالی وجود ندارد'), findsOneWidget);
      expect(find.text('در انتظار'), findsNothing);
    });

    testWidgets('acknowledging from the panel hits the repository',
        (tester) async {
      final repo = _FakeRepository([call(id: 'a')]);
      final provider = await pumpPanel(tester, repo);

      await tester.tap(find.text('دیدم'));
      await tester.pumpAndSettle();

      expect(repo.actions, ['ack:a']);
      expect(provider.hasPending, isFalse);
      provider.stop();
    });

    testWidgets('completing from the panel hits the repository',
        (tester) async {
      final repo = _FakeRepository([call(id: 'a')]);
      final provider = await pumpPanel(tester, repo);

      await tester.tap(find.text('انجام شد'));
      await tester.pumpAndSettle();

      expect(repo.actions, ['complete:a']);
      expect(find.text('درخواست فعالی وجود ندارد'), findsOneWidget);
      provider.stop();
    });

    testWidgets('a failure is reported to the user', (tester) async {
      final repo = _FakeRepository([call(id: 'a')])
        ..error = AppFailure.network();
      final provider = await pumpPanel(tester, repo);

      await tester.tap(find.text('دیدم'));
      await tester.pumpAndSettle();

      expect(find.textContaining('اتصال به سرور برقرار نشد'), findsOneWidget);
      provider.stop();
    });
  });
}
