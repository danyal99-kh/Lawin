import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../core/config/app_config.dart';

class RealtimeEvent {
  const RealtimeEvent(this.name, this.data);
  final String name;
  final Map<String, dynamic> data;
}

/// اتصال WebSocket ادمین با Reconnect خودکار (Exponential Backoff).
class RealtimeService {
  RealtimeService(this._tokenProvider);

  final Future<String?> Function() _tokenProvider;

  final _events = StreamController<RealtimeEvent>.broadcast();
  final _connected = StreamController<bool>.broadcast();

  Stream<RealtimeEvent> get events => _events.stream;

  /// با هر (باز)اتصال موفق true می‌دهد؛ برای همگام‌سازی REST.
  Stream<bool> get connection => _connected.stream;

  WebSocketChannel? _channel;
  StreamSubscription? _sub;
  Timer? _retryTimer;
  Timer? _pingTimer;
  int _retry = 0;
  bool _running = false;

  Uri _wsUri(String token) {
    final base = Uri.parse(AppConfig.apiBaseUrl);
    return Uri(
      scheme: base.scheme == 'https' ? 'wss' : 'ws',
      host: base.host,
      port: base.hasPort ? base.port : null,
      path: '/ws/admin/',
      queryParameters: {'token': token},
    );
  }

  Future<void> start() async {
    if (_running) return;
    _running = true;
    await _connect();
  }

  Future<void> _connect() async {
    if (!_running) return;
    final token = await _tokenProvider();
    if (token == null) return;
    try {
      final channel = WebSocketChannel.connect(_wsUri(token));
      _channel = channel;
      await channel.ready;
      _retry = 0;
      _connected.add(true);
      _pingTimer?.cancel();
      _pingTimer = Timer.periodic(const Duration(seconds: 25), (_) {
        try {
          channel.sink.add(jsonEncode({'type': 'ping'}));
        } catch (_) {}
      });
      _sub = channel.stream.listen(
        _onMessage,
        onDone: _scheduleReconnect,
        onError: (_) => _scheduleReconnect(),
        cancelOnError: true,
      );
    } catch (_) {
      _scheduleReconnect();
    }
  }

  void _onMessage(dynamic raw) {
    try {
      final m = jsonDecode(raw as String) as Map<String, dynamic>;
      final name = m['event'] as String?;
      if (name == null || name == 'pong') return;
      _events.add(RealtimeEvent(
          name, (m['data'] as Map?)?.cast<String, dynamic>() ?? {}));
    } catch (_) {}
  }

  void _scheduleReconnect() {
    _connected.add(false);
    _pingTimer?.cancel();
    _sub?.cancel();
    _channel = null;
    if (!_running) return;
    final seconds = (1 << _retry.clamp(0, 4)); // 1,2,4,8,16
    _retry++;
    _retryTimer?.cancel();
    _retryTimer = Timer(Duration(seconds: seconds), _connect);
  }

  Future<void> stop() async {
    _running = false;
    _retryTimer?.cancel();
    _pingTimer?.cancel();
    await _sub?.cancel();
    await _channel?.sink.close();
    _channel = null;
  }

  void dispose() {
    stop();
    _events.close();
    _connected.close();
  }
}
