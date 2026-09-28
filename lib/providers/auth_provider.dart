import 'package:flutter/foundation.dart';

import '../core/errors/app_failure.dart';
import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';
import '../core/network/token_storage.dart';

enum AuthStatus { unknown, signedOut, signedIn }

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._api, this._tokens) {
    _api.onUnauthorized = _handleUnauthorized;
  }

  final ApiClient _api;
  final TokenStorage _tokens;

  AuthStatus _status = AuthStatus.unknown;
  AuthStatus get status => _status;

  String? _token;
  String? get token => _token;

  bool _busy = false;
  bool get busy => _busy;

  Future<void> restore() async {
    _token = await _tokens.read();
    _status = _token == null ? AuthStatus.signedOut : AuthStatus.signedIn;
    notifyListeners();
  }

  Future<AppFailure?> login(String username, String password) async {
    _busy = true;
    notifyListeners();
    final result = await _api.post<String>(
      ApiEndpoints.login,
      (j) => (j as Map<String, dynamic>)['token'] as String,
      body: {'username': username.trim(), 'password': password},
    );
    _busy = false;
    final failure = result.failureOrNull;
    if (failure != null) {
      notifyListeners();
      return failure;
    }
    _token = result.dataOrNull!;
    await _tokens.write(_token!);
    _status = AuthStatus.signedIn;
    notifyListeners();
    return null;
  }

  Future<void> logout() async {
    await _tokens.clear();
    _token = null;
    _status = AuthStatus.signedOut;
    notifyListeners();
  }

  void _handleUnauthorized() {
    if (_status == AuthStatus.signedIn) logout();
  }
}
