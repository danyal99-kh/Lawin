import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../errors/app_failure.dart';
import '../errors/result.dart';
import 'token_storage.dart';

/// کلاینت HTTP مرکزی: Token، Timeout و تبدیل خطای Django به AppFailure.
class ApiClient {
  ApiClient(this._tokens, {http.Client? client})
      : _http = client ?? http.Client();

  final TokenStorage _tokens;
  final http.Client _http;

  /// وقتی 401 دریافت شود صدا زده می‌شود (مثلاً رفتن به صفحه‌ی ورود).
  void Function()? onUnauthorized;

  Uri _uri(String path, [Map<String, String>? query]) {
    final base = Uri.parse(AppConfig.apiBaseUrl);
    return base.replace(path: path, queryParameters: query);
  }

  Future<Map<String, String>> _headers({bool json = true}) async {
    final token = await _tokens.read();
    return {
      if (json) 'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Token $token',
    };
  }

  Future<Result<T>> _send<T>(
    Future<http.Response> Function(Map<String, String> h) call,
    T Function(dynamic json) parse,
  ) async {
    try {
      final res =
          await call(await _headers()).timeout(AppConfig.requestTimeout);
      final body =
          res.bodyBytes.isEmpty ? null : jsonDecode(utf8.decode(res.bodyBytes));
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return Success(parse(body));
      }
      final failure = _failureFrom(res.statusCode, body);
      if (failure.type == FailureType.unauthorized) onUnauthorized?.call();
      return Failure(failure);
    } on TimeoutException {
      return Failure(AppFailure.timeout());
    } on SocketException {
      return Failure(AppFailure.network());
    } on http.ClientException {
      return Failure(AppFailure.network());
    } on HandshakeException {
      return Failure(AppFailure.network());
    } catch (e) {
      return Failure(AppFailure.unknown(e));
    }
  }

  AppFailure _failureFrom(int status, dynamic body) {
    String? code;
    String? message;
    if (body is Map && body['error'] is Map) {
      code = body['error']['code'] as String?;
      message = body['error']['message'] as String?;
    }
    switch (code) {
      case 'insufficient_stock':
        return AppFailure(FailureType.insufficientStock, message: message);
      case 'inactive_product':
        return AppFailure(FailureType.inactiveProduct, message: message);
      case 'conflict':
        return AppFailure.conflict(message);
      case 'not_found':
        return AppFailure.notFound();
      case 'unauthorized':
        return AppFailure.unauthorized(message);
      case 'validation':
        return AppFailure.validation(message);
    }
    if (status == 401 || status == 403) return AppFailure.unauthorized(message);
    if (status == 404) return AppFailure.notFound();
    if (status >= 500) return AppFailure.server(body);
    return AppFailure.validation(message);
  }

  Future<Result<T>> get<T>(String path, T Function(dynamic) parse,
          {Map<String, String>? query}) =>
      _send((h) => _http.get(_uri(path, query), headers: h), parse);

  Future<Result<T>> post<T>(String path, T Function(dynamic) parse,
          {Object? body}) =>
      _send(
          (h) => _http.post(_uri(path),
              headers: h, body: jsonEncode(body ?? {})),
          parse);

  Future<Result<T>> put<T>(String path, T Function(dynamic) parse,
          {Object? body}) =>
      _send(
          (h) => _http.put(_uri(path), headers: h, body: jsonEncode(body ?? {})),
          parse);

  Future<Result<T>> patch<T>(String path, T Function(dynamic) parse,
          {Object? body}) =>
      _send(
          (h) =>
              _http.patch(_uri(path), headers: h, body: jsonEncode(body ?? {})),
          parse);

  Future<Result<void>> delete(String path) =>
      _send<void>((h) => _http.delete(_uri(path), headers: h), (_) {});

  /// Multipart request برای آپلود فایل‌ها (مثلاً تصویر محصول)
  Future<Result<T>> multipartRequest<T>(
    String method,
    String path,
    T Function(dynamic json) parse, {
    Map<String, String>? fields,
    Map<String, File>? files,
  }) async {
    try {
      final headers = await _headers(json: false);
      final request = http.MultipartRequest(method, _uri(path));
      request.headers.addAll(headers);
      if (fields != null) {
        request.fields.addAll(fields);
      }
      if (files != null) {
        for (final entry in files.entries) {
          final file = entry.value;
          request.files.add(await http.MultipartFile.fromPath(
            entry.key,
            file.path,
          ));
        }
      }
      final streamedRes = await request.send().timeout(AppConfig.requestTimeout);
      final res = await http.Response.fromStream(streamedRes);
      final body =
          res.bodyBytes.isEmpty ? null : jsonDecode(utf8.decode(res.bodyBytes));
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return Success(parse(body));
      }
      final failure = _failureFrom(res.statusCode, body);
      if (failure.type == FailureType.unauthorized) onUnauthorized?.call();
      return Failure(failure);
    } on TimeoutException {
      return Failure(AppFailure.timeout());
    } on SocketException {
      return Failure(AppFailure.network());
    } on http.ClientException {
      return Failure(AppFailure.network());
    } on HandshakeException {
      return Failure(AppFailure.network());
    } catch (e) {
      return Failure(AppFailure.unknown(e));
    }
  }
}
