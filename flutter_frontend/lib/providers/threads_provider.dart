import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/threads/thread.dart';
import '../../repositories/threads_repository.dart';

// State for active messages in a specific channel
class ThreadMessagesState {
  final List<ThreadMessage> messages;
  final bool isLoading;
  final bool hasMore;

  ThreadMessagesState({
    this.messages = const [],
    this.isLoading = false,
    this.hasMore = true,
  });

  ThreadMessagesState copyWith({
    List<ThreadMessage>? messages,
    bool? isLoading,
    bool? hasMore,
  }) {
    return ThreadMessagesState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class ThreadMessagesNotifier extends StateNotifier<ThreadMessagesState> {
  final ThreadsRepository _repository;
  final String threadId;

  ThreadMessagesNotifier(this._repository, this.threadId) : super(ThreadMessagesState()) {
    fetchMessages();
  }

  Future<void> fetchMessages({bool loadMore = false}) async {
    if (state.isLoading || (!state.hasMore && loadMore)) return;

    state = state.copyWith(isLoading: true);
    
    try {
      final offset = loadMore ? state.messages.length : 0;
      List<ThreadMessage> newMessages;
      
      if (threadId.startsWith('mail.box_')) {
        newMessages = await _repository.getFolderMessages(threadId, offset: offset);
      } else {
        final channelId = int.parse(threadId);
        newMessages = await _repository.getMessages(channelId, offset: offset);
      }
      
      state = state.copyWith(
        messages: loadMore ? [...state.messages, ...newMessages] : newMessages,
        isLoading: false,
        hasMore: newMessages.length == 50,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  void addMessageOptimistically(String content, int senderId, String senderName) {
    // Generate a temporary message for immediate UI feedback
    final optimisticMsg = ThreadMessage(
      id: -DateTime.now().millisecondsSinceEpoch, // Temp ID
      content: content,
      timestamp: DateTime.now(),
      senderId: senderId,
      senderName: senderName,
      sequence: 999999999, // Place at bottom
    );

    state = state.copyWith(messages: [optimisticMsg, ...state.messages]);
  }

  // Handle live updates from WebSocket listener
  void onNewMessage(ThreadMessage message) {
    // Check if it's already there (optimistic or duplicate)
    final index = state.messages.indexWhere((m) => m.id == message.id);
    if (index != -1) return;

    // Remove optimistic version if it exists (by matching content/sender roughly if needed)
    // For simplicity, we just add the real one and Sort by sequence/id
    final updatedList = [message, ...state.messages];
    updatedList.sort((a, b) => b.id.compareTo(a.id)); // Newest first
    
    state = state.copyWith(messages: updatedList);
  }
}

final threadMessagesProvider = StateNotifierProvider.family<ThreadMessagesNotifier, ThreadMessagesState, String>((ref, threadId) {
  final repo = ref.watch(threadsRepositoryProvider);
  return ThreadMessagesNotifier(repo, threadId);
});

// Sidebar Channel List state
final channelsProvider = FutureProvider<List<Thread>>((ref) async {
  final repo = ref.watch(threadsRepositoryProvider);
  
  // 1. Fetch real channels
  final realChannels = await repo.getChannels();
  
  // 2. Prepend virtual folders
  return [
    Thread.virtual('mail.box_inbox', 'Inbox', ChannelType.channel),
    Thread.virtual('mail.box_starred', 'Starred messages', ChannelType.channel),
    Thread.virtual('mail.box_history', 'History', ChannelType.channel),
    ...realChannels,
  ];
});
