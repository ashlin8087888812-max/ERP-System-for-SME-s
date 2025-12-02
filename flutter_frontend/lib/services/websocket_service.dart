import 'dart:async';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:flutter/foundation.dart';
import 'auth_storage.dart';
import '../injection_container.dart' as di;

class WebSocketService {
  WebSocketChannel? _channel;
  final _controller = StreamController<Map<String, dynamic>>.broadcast();
  final AuthStorage _authStorage;
  bool _isConnected = false;

  WebSocketService({AuthStorage? authStorage})
      : _authStorage = authStorage ?? di.sl<AuthStorage>();

  Stream<Map<String, dynamic>> get stream => _controller.stream;
  bool get isConnected => _isConnected;



  Future<void> connect() async {
    if (_isConnected) return;

    final token = await _authStorage.getToken();
    if (token == null) return;

    // 1. Get base URL (prefer WS_URL, fallback to BASE_URL converted to ws)
    String url = dotenv.env['WS_URL'] ?? '';
    
    // Fix common mistake where WS_URL is set to /ws instead of /api/v1/ws
    if (url.isNotEmpty && url.endsWith('/ws') && !url.endsWith('/api/v1/ws')) {
      debugPrint('Warning: WS_URL $url is missing /api/v1 prefix. Auto-correcting.');
      url = url.replaceFirst('/ws', '/api/v1/ws');
    }

    if (url.isEmpty) {
      // Default to localhost with API prefix if not set
      final baseUrl = dotenv.env['BASE_URL'] ?? 'http://localhost:8000/api/v1';
      
      // Ensure we have the correct path structure
      if (baseUrl.endsWith('/api/v1')) {
        url = baseUrl.replaceFirst('http', 'ws') + '/ws';
      } else {
        // If BASE_URL doesn't have /api/v1, append it
        url = baseUrl.replaceFirst('http', 'ws');
        if (!url.endsWith('/')) url += '/';
        url += 'api/v1/ws';
      }
    }

    // 2. Platform-specific fix for Android Emulator
    if (defaultTargetPlatform == TargetPlatform.android) {
      if (url.contains('localhost')) {
        url = url.replaceFirst('localhost', '10.0.2.2');
      }
    }

    // 3. Append token
    final wsUrl = '$url?token=$token';

    try {
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _isConnected = true;

      _channel!.stream.listen(
        (message) {
          try {
            if (message == 'pong') return; // Ignore pongs
            final data = jsonDecode(message);
            _controller.add(data);
          } catch (e) {
            print('WebSocket decode error: $e');
          }
        },
        onDone: () {
          _isConnected = false;
          _reconnect();
        },
        onError: (error) {
          print('WebSocket error: $error');
          _isConnected = false;
          _reconnect();
        },
      );
    } catch (e) {
      print('WebSocket connection failed: $e');
      _isConnected = false;
      _reconnect();
    }
  }

  void _reconnect() {
    if (_isConnected) return;
    // Simple exponential backoff could be added here
    Future.delayed(const Duration(seconds: 5), () => connect());
  }

  void disconnect() {
    _channel?.sink.close(status.goingAway);
    _isConnected = false;
  }
  
  void send(String message) {
    if (_isConnected) {
      _channel?.sink.add(message);
    }
  }
}
