import 'package:cafe_book_admin/core/errors/result.dart';
import 'package:cafe_book_admin/core/network/api_client.dart';
import 'package:cafe_book_admin/core/network/token_storage.dart';
import 'package:cafe_book_admin/models/table_overview.dart';
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

void main() {
  if (_token.isEmpty) {
    test('skipped', () {});
    return;
  }
  test('tables via a host that is NOT in DJANGO_ALLOWED_HOSTS', () async {
    final api = ApiClient(_S(_token));
    final r = await api.get<List<TableOverview>>(
      '/api/v1/tables/',
      (j) => (j as List).map((e) => TableOverview.fromJson(e as Map<String, dynamic>)).toList(),
    );
    final f = r.failureOrNull;
    if (f != null) {
      // ignore: avoid_print
      print('RESULT type=${f.type}');
      // ignore: avoid_print
      print('RESULT details=${f.details}');
      // ignore: avoid_print
      print('RESULT userMessage=${f.userMessage}');
    } else {
      // ignore: avoid_print
      print('RESULT OK (${r.dataOrNull!.length} tables)');
    }
  }, timeout: const Timeout(Duration(minutes: 1)));
}