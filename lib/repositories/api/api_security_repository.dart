import 'package:cafe_book_admin/core/errors/result.dart';
import 'package:cafe_book_admin/core/network/api_client.dart';
import 'package:cafe_book_admin/core/network/api_endpoints.dart';

import '../security_repository.dart';

class ApiSecurityRepository implements SecurityRepository {
  ApiSecurityRepository(this._api);

  final ApiClient _api;

  @override
  Future<Result<String>> verify(String password) => _api.post<String>(
        ApiEndpoints.securityVerify,
        (j) => (j as Map<String, dynamic>)['ticket'] as String,
        body: {'password': password},
      );

  @override
  Future<Result<void>> changePassword({
    String? currentPassword,
    required String newPassword,
  }) =>
      _api.post<void>(
        ApiEndpoints.securityPassword,
        (_) {},
        body: {
          'current_password': currentPassword,
          'new_password': newPassword,
        },
      );
}