import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/threads_provider.dart';
import '../../models/threads/thread.dart';
import 'chat_window.dart';

class ThreadsPage extends ConsumerStatefulWidget {
  final String? threadId;
  const ThreadsPage({super.key, this.threadId});

  @override
  ConsumerState<ThreadsPage> createState() => _ThreadsPageState();
}

class _ThreadsPageState extends ConsumerState<ThreadsPage> {
  String? _selectedThreadId;

  @override
  void initState() {
    super.initState();
    _selectedThreadId = widget.threadId ?? 'mail.box_inbox';
  }

  @override
  Widget build(BuildContext context) {
    final channelsAsync = ref.watch(channelsProvider);
    final selectedThread = channelsAsync.value?.firstWhere((t) {
       final id = t.isVirtual ? t.uuid : t.id.toString();
       return id == _selectedThreadId;
    }, orElse: () => Thread.virtual('mail.box_inbox', 'Threads', ChannelType.channel));

    return Scaffold(
      appBar: AppBar(
        title: Text(selectedThread?.name ?? 'Threads'),
        leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.go('/'),
      ),
      ),
      body: Row(
        children: [
          // Sidebar: Channel List
          SizedBox(
            width: 250,
            child: channelsAsync.when(
              data: (threads) {
                final folders = threads.where((t) => t.isVirtual).toList();
                final channels = threads.where((t) => !t.isVirtual && t.type == ChannelType.channel).toList();
                final directMessages = threads.where((t) => !t.isVirtual && t.type == ChannelType.chat).toList();

                return ListView(
                  children: [
                    _buildSection('Folders', folders),
                    const Divider(),
                    _buildSection('Channels', channels),
                    const Divider(),
                    _buildSection('Direct Messages', directMessages),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
          const VerticalDivider(width: 1),
          // Main: Chat Window
          Expanded(
            child: _selectedThreadId != null
                ? ChatWindow(threadId: _selectedThreadId!)
                : const Center(child: Text('Select a channel to start chatting')),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Thread> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
        ),
        ...items.map((thread) {
          final id = thread.isVirtual ? thread.uuid : thread.id.toString();
          return ListTile(
            leading: Icon(_getIconFor(thread)),
            title: Text(thread.name),
            selected: _selectedThreadId == id,
            onTap: () {
              setState(() {
                _selectedThreadId = id;
              });
            },
          );
        }),
      ],
    );
  }

  IconData _getIconFor(Thread thread) {
    if (thread.isVirtual) {
      if (thread.uuid == 'mail.box_inbox') return Icons.inbox;
      if (thread.uuid == 'mail.box_starred') return Icons.star_border;
      return Icons.history;
    }
    return thread.type == ChannelType.chat ? Icons.person_outline : Icons.tag;
  }
}
