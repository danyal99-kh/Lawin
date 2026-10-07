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
  ApiClient(
    this._tokens, {
    http.Client? client,
    this.securityTicket,
    this.onSecurityTicket,
  }) : _http = client ?? http.Client();

  /// نام هدری که بلیت رمز امنیتی در آن به Backend فرستاده و از آن دریافت می‌شود.
  static const String securityTicketHeader = 'X-Security-Ticket';

  final TokenStorage _tokens;
  final http.Client _http;

  /// توکن احراز هویتِ نشستِ فعلی (از حافظه). اگر null برگرداند، از
  /// `TokenStorage` (fallback) خوانده می‌شود.
  ///
  /// این فیلد توسط `AuthProvider` در سازنده‌اش وصل می‌شود تا همه‌ی درخواست‌ها
  /// بدون وابستگی به دسترسی پیرامونی به رسانه‌ی امن، توکنِ نشستِ جاری را
  /// بفرستند. روی پلتفرم‌هایی که حافظه‌ی امن خاموش است (مثلاً دسکتاپ بدون
  /// secret service)، نوشتن/خواندن امن بی‌صدا شکست می‌خورد؛ استفاده از حافظه
  /// کاریِ نشست، لاگین و داشبورد را همچنان کار می‌کند.
  String? Function()? authToken;

  /// بلیت رمز امنیتی فعلی (برای مسیرهای حسابداری/گزارش‌ها). اگر null برگرداند
  /// هدر فرستاده نمی‌شود. هر بار که درخواست ساخته می‌شود خوانده می‌شود.
  ///
  /// این دو فیلد «مقدار اولیه» دارند ولی توسط گیت امنیتی بعد از ساخته شدن
  /// (در AppProviders) وصل می‌شوند؛ به این ترتیب درخواست‌های قبل از وجود گیت
  /// (مثلاً باطل‌کردن توکن هنگام شروع برنامه) بدون بلیت می‌مانند و کرش نمی‌کنند.
  String? Function()? securityTicket;

  /// هرگاه پاسخ سرور بلیت تازه‌ای در هدر بلیت برگرداند (نشست لغزان) صدا زده
  /// می‌شود تا Provider امنیتی آن را نگه دارد.
  void Function(String)? onSecurityTicket;

  /// وقتی 401 دریافت شود صدا زده می‌شود (مثلاً رفتن به صفحه‌ی ورود).
  void Function()? onUnauthorized;

  Uri _uri(String path, [Map<String, String>? query]) {
    final base = Uri.parse(AppConfig.apiBaseUrl);
    return base.replace(path: path, queryParameters: query);
  }

  Future<Map<String, String>> _headers({bool json = true}) async {
    final token = authToken?.call() ?? await _tokens.read();
    final security = securityTicket?.call();
    return {
      if (json) 'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Token $token',
      if (security != null && security.isNotEmpty)
        securityTicketHeader: security,
    };
  }

  Future<Result<T>> _send<T>(
    Future<http.Response> Function(Map<String, String> h) call,
    T Function(dynamic json) parse,
  ) async {
    try {
      final res =
          await call(await _headers()).timeout(AppConfig.requestTimeout);
      _consumeSecurityHeader(res);
      final body = _decodeBody(res);
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

  /// اگر پاسخ، بلیت تازه‌ای برگرداند، آن را به لایه‌ی امنیتی می‌دهد.
  void _consumeSecurityHeader(http.Response res) {
    final onNew = onSecurityTicket;
    if (onNew == null) return;
    final value = _headerValue(res.headers, securityTicketHeader);
    if (value != null && value.isNotEmpty) onNew(value);
  }

  /// نام هدرها در بسته‌ی http ممکن است حروف‌بزرگ/کوچک متفاوتی داشته باشند؛
  /// این جستجو به حروف بزرگ/کوچک حساس نیست.
  static String? _headerValue(Map<String, String> headers, String name) {
    for (final entry in headers.entries) {
      if (entry.key.toLowerCase() == name.toLowerCase()) return entry.value;
    }
    return null;
  }

  /// بدنه‌ی پاسخ را به JSON تبدیل می‌کند، اما اگر سرور HTML برگرداند
  /// (مثلاً صفحه‌ی خطای Django یا DisallowedHost) به‌جای پرتاب FormatException
  /// مقدار null می‌دهد. بدون این محافظت، هر پاسخ غیر‑JSON به «خطای غیرمنتظره»
  /// تبدیل می‌شد و علت واقعی (کد وضعیت و متن سرور) پنهان می‌ماند.
  static dynamic _decodeBody(http.Response res) {
    if (res.bodyBytes.isEmpty) return null;
    try {
      return jsonDecode(utf8.decode(res.bodyBytes));
    } on FormatException {
      return null;
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
      case 'security_denied':
        return AppFailure.security(message);
      case 'security_not_configured':
        return AppFailure.securityNotConfigured(message);
    }
    if (status == 401 || status == 403) return AppFailure.unauthorized(message);
    if (status == 404) return AppFailure.notFound();
    if (status >= 500) return AppFailure.server(body);
    // پاسخ ۴xx بدون JSON معتبر: سرور چیزی غیر از قرارداد API برگردانده
    // (صفحه‌ی خطای Django، پروکسی، یا هاستی که در DJANGO_ALLOWED_HOSTS نیست).
    if (body == null) {
      return AppFailure(
        FailureType.server,
        message: 'پاسخ غیرمنتظره از سرور (کد $status). آدرس API و تنظیمات '
            'ALLOWED_HOSTS بک‌اند را بررسی کنید.',
      );
    }
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
      _consumeSecurityHeader(res);
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
