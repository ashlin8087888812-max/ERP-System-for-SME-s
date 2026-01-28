import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import '../../providers/threads_provider.dart';
import '../../models/threads/thread.dart';
import '../../repositories/threads_repository.dart';

class ChatWindow extends ConsumerStatefulWidget {
  final String threadId;
  const ChatWindow({super.key, required this.threadId});

  @override
  ConsumerState<ChatWindow> createState() => _ChatWindowState();
}

class _ChatWindowState extends ConsumerState<ChatWindow> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(threadMessagesProvider(widget.threadId).notifier).fetchMessages(loadMore: true);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(threadMessagesProvider(widget.threadId));
    
    return Column(
      children: [
        Expanded(
          child: state.messages.isEmpty && state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                controller: _scrollController,
                reverse: true, // Newest at bottom
                itemCount: state.messages.length,
                itemBuilder: (context, index) {
                  final message = state.messages[index];
                  return MessageBubble(
                    key: ValueKey('msg_${message.id}'), // Keyed for performance
                    message: message,
                  );
                },
              ),
        ),
        _buildInput(),
      ],
    );
  }

  Widget _buildInput() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(hintText: "Type a message..."),
              onSubmitted: (_) => _send(),
            ),
          ),
          IconButton(icon: const Icon(Icons.send), onPressed: _send),
        ],
      ),
    );
  }

  Future<void> _send() async {
    if (_messageController.text.trim().isEmpty) return;
    
    final content = _messageController.text;
    _messageController.clear();
    
    // 1. Optimistic Update
    ref.read(threadMessagesProvider(widget.threadId).notifier)
       .addMessageOptimistically(content, 0, "Me");
    
    // 2. Real Send
    try {
      if (widget.threadId.startsWith('mail.box_')) {
        // Handle folder actions if any (e.g., mark as read or just ignore send)
        return; 
      }
      final channelId = int.parse(widget.threadId);
      await ref.read(threadsRepositoryProvider).postMessage(channelId, content);
    } catch (e) {
      // Revert optimistic or show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: $e')),
      );
    }
  }
}

class MessageBubble extends StatelessWidget {
  final ThreadMessage message;
  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message.senderName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: HtmlWidget(message.content),
          ),
        ],
      ),
    );
  }
}
