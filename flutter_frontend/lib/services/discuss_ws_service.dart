import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import '../repositories/threads_repository.dart';
import '../providers/threads_provider.dart';

class DiscussWebSocketService {
  final Ref _ref;
  WebSocketChannel? _channel;
  bool _isConnecting = false;
  Timer? _reconnectTimer;
  
  DiscussWebSocketService(this._ref);

  void connect(int companyId, List<int> channelIds, String token) {
    if (_isConnecting) return;
    _isConnecting = true;

    // 1. Get base URL
    String url = dotenv.env['WS_URL'] ?? '';
    if (url.isEmpty) {
      final baseUrl = dotenv.env['BASE_URL'] ?? 'http://localhost:8000/api/v1';
      url = baseUrl.replaceFirst('http', 'ws');
      if (!url.endsWith('/')) url += '/';
      if (!url.contains('/ws')) url += 'ws';
    }

    // 2. Platform-specific fix for Android Emulator
    if (defaultTargetPlatform == TargetPlatform.android) {
      if (url.contains('localhost')) {
        url = url.replaceFirst('localhost', '10.0.2.2');
      }
    }

    // 3. Construct endpoint
    final channelIdsStr = channelIds.join(',');
    final fullUrl = '$url/discuss?token=$token&company_id=$companyId&channel_ids=$channelIdsStr';
    
    _channel = WebSocketChannel.connect(Uri.parse(fullUrl));

    _channel!.stream.listen(
      (message) {
        if (message == 'ping') {
          _channel!.sink.add('pong');
          return;
        }
        
        try {
          final data = jsonDecode(message);
          _handleMessage(data);
        } catch (e) {
          // Log error
        }
      },
      onDone: () => _reconnect(companyId, channelIds, token),
      onError: (e) => _reconnect(companyId, channelIds, token),
    );
    
    _isConnecting = false;
  }

  void _handleMessage(Map<String, dynamic> data) {
    final repo = _ref.read(threadsRepositoryProvider);
    final msg = repo.processWebSocketMessage(data);
    
    if (msg != null) {
      // Propagation to Riverpod State
      final channelId = data['channel_id'];
      _ref.read(threadMessagesProvider(channelId).notifier).onNewMessage(msg);
    }
  }

  void _reconnect(int companyId, List<int> channelIds, String token) {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      connect(companyId, channelIds, token);
    });
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
  }
}

final discussWebSocketProvider = Provider((ref) {
  final service = DiscussWebSocketService(ref);
  ref.onDispose(() => service.disconnect());
  return service;
});
