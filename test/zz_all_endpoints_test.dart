import 'package:cafe_book_admin/core/errors/result.dart';
import 'package:cafe_book_admin/core/network/api_client.dart';
import 'package:cafe_book_admin/core/network/token_storage.dart';
import 'package:cafe_book_admin/models/report.dart';
import 'package:cafe_book_admin/repositories/api/api_accounting_repository.dart';
import 'package:cafe_book_admin/repositories/api/api_cafe_status_repository.dart';
import 'package:cafe_book_admin/repositories/api/api_category_repository.dart';
import 'package:cafe_book_admin/repositories/api/api_credit_repository.dart';
import 'package:cafe_book_admin/repositories/api/api_dashboard_repository.dart';
import 'package:cafe_book_admin/repositories/api/api_expense_repository.dart';
import 'package:cafe_book_admin/repositories/api/api_inventory_repository.dart';
import 'package:cafe_book_admin/repositories/api/api_order_repository.dart';
import 'package:cafe_book_admin/repositories/api/api_product_repository.dart';
import 'package:cafe_book_admin/repositories/api/api_purchase_repository.dart';
import 'package:cafe_book_admin/repositories/api/api_recipe_repository.dart';
import 'package:cafe_book_admin/repositories/api/api_report_repository.dart';
import 'package:cafe_book_admin/repositories/api/api_settings_repository.dart';
import 'package:cafe_book_admin/repositories/api/api_table_repository.dart';
import 'package:cafe_book_admin/repositories/api/api_waiter_call_repository.dart';
import 'package:cafe_book_admin/repositories/api/api_waste_repository.dart';
import 'package:flutter_test/flutter_test.dart';

const _token = String.fromEnvironment('LAWIN_TEST_TOKEN');

class _S implements TokenStorage {
  _S(this.t);
  final String t;
  @override
  Future<String?> read() async => t;
  @override
  Future<void> write(String token) async {}
  @override
  Future<void> clear() async {}
}

final failures = <String>[];

Future<void> check(String label, Future<Result<dynamic>> f) async {
  try {
    final r = await f;
    if (r is Failure) {
      failures.add(label);
      // ignore: avoid_print
      print('FAIL $label :: ${r.failure.type} :: ${r.failure.details}');
    } else {
      // ignore: avoid_print
      print('ok   $label');
    }
  } catch (e) {
    failures.add(label);
    // ignore: avoid_print
    print('THROW $label :: $e');
  }
}

void main() {
  if (_token.isEmpty) {
    test('skipped', () {});
    return;
  }
  late ApiClient api;

  setUp(() {
    api = ApiClient(_S(_token));
    failures.clear();
  });

  test('every endpoint the admin app loads', () async {
    await check('tables', ApiTableRepository(api).getTables());
    await check('orders', ApiOrderRepository(api).getOrders());
    await check('dashboard', ApiDashboardRepository(api).getSummary());
    await check(
        'waiter-calls active', ApiWaiterCallRepository(api).getActiveCalls());
    await check(
        'orders/changes (no cursor)', ApiOrderRepository(api).changes(null));
    await check('settings', ApiSettingsRepository(api).getSettings());
    await check(
        'welcome settings', ApiSettingsRepository(api).getWelcomeSettings());
    await check('products', ApiProductRepository(api).getProducts());
    await check('categories', ApiCategoryRepository(api).getCategories());
    await check('inventory items', ApiInventoryRepository(api).getItems());
    await check('expenses', ApiExpenseRepository(api).getExpenses());
    await check('purchases', ApiPurchaseRepository(api).getPurchases());
    await check('wastes', ApiWasteRepository(api).getWastes());
    await check('recipes', ApiRecipeRepository(api).getRecipes());
    await check(
        'accounting entries', ApiAccountingRepository(api).getEntries());
    await check(
        'ledger verification', ApiAccountingRepository(api).verifyLedger());
    await check(
        'reports', ApiReportRepository(api).getReport(ReportPeriod.today));
    await check(
        'cafe status', ApiCafeStatusRepository(api).getStatus());
    final creditsRepo = ApiCreditRepository(api);
    await check('credits', creditsRepo.getCredits());
    await check('credit debtors', creditsRepo.getDebtors());
    await check('credit payments', creditsRepo.getPayments());

    // ignore: avoid_print
    print('\n=== FAILURES (${failures.length}): $failures ===');
  }, timeout: const Timeout(Duration(minutes: 3)));
}
