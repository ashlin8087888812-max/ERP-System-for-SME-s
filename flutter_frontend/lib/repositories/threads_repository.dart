import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/threads/thread.dart';
import '../../services/api_client.dart'; // Using the existing api_client.dart

import '../injection_container.dart' as di;

class ThreadsRepository {
  final ApiClient _api;
  
  // Cache for duplicate suppression
  final Set<int> _processedMessageIds = {};
  
  ThreadsRepository(this._api);

  Future<List<Thread>> getChannels() async {
    final response = await _api.dio.get('/discuss/channels');
    final data = response.data as List<dynamic>;
    return data.map((json) => Thread.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<List<ThreadMessage>> getMessages(int channelId, {int limit = 50, int offset = 0}) async {
    final response = await _api.dio.get(
      '/discuss/channels/$channelId/messages', 
      queryParameters: {
        'limit': limit,
        'offset': offset,
      },
    );
    
    final data = response.data as List<dynamic>;
    final messages = data.map((json) => ThreadMessage.fromJson(json as Map<String, dynamic>)).toList();
    
    // Store IDs to suppress duplicates from WS later
    for (var m in messages) {
       _processedMessageIds.add(m.id);
    }
    
    return messages;
  }

  Future<List<ThreadMessage>> getFolderMessages(String folderId, {int limit = 50, int offset = 0}) async {
    final endpoint = _getFolderEndpoint(folderId);
    final response = await _api.dio.get(endpoint, queryParameters: {
      'limit': limit,
      'offset': offset,
    });
    
    final data = response.data as List<dynamic>;
    final messages = data.map((json) => ThreadMessage.fromJson(json as Map<String, dynamic>)).toList();
    
    for (var m in messages) {
       _processedMessageIds.add(m.id);
    }
    
    return messages;
  }

  String _getFolderEndpoint(String folderId) {
    switch (folderId) {
      case 'mail.box_inbox': return '/discuss/inbox';
      case 'mail.box_starred': return '/discuss/starred';
      case 'mail.box_history': return '/discuss/history';
      default: throw Exception('Unknown folder: $folderId');
    }
  }

  Future<ThreadMessage> postMessage(int channelId, String content, {int? parentId}) async {
    final response = await _api.dio.post('/discuss/channels/$channelId/messages', data: {
      'content': content,
      'parent_id': parentId,
    });
    
    final msg = ThreadMessage.fromJson(response.data as Map<String, dynamic>);
    _processedMessageIds.add(msg.id);
    return msg;
  }

  // Duplicate Suppression Logic for WS
  ThreadMessage? processWebSocketMessage(Map<String, dynamic> json) {
    if (json['type'] == 'discuss.message.new') {
      final msgData = json['data'];
      final msgId = msgData['id'];
      
      if (_processedMessageIds.contains(msgId)) {
        return null; // Duplicate suppressed
      }
      
      final msg = ThreadMessage.fromJson(msgData);
      _processedMessageIds.add(msg.id);
      return msg;
    }
    return null;
  }

  void clearProcessedCache() {
    _processedMessageIds.clear();
    if (_processedMessageIds.length > 1000) {
      // Periodic pruning to prevent memory leak
      _processedMessageIds.clear();
    }
  }
}

final threadsRepositoryProvider = Provider<ThreadsRepository>((ref) {
  return di.sl<ThreadsRepository>();
});
