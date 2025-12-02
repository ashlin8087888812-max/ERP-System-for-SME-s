import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equatable/equatable.dart';
import '../repositories/contacts_repository.dart';
import '../models/contact_model.dart';
import '../injection_container.dart' as di;
import '../services/websocket_service.dart';

final contactsRepositoryProvider = Provider<ContactsRepository>((ref) {
  return di.sl<ContactsRepository>();
});

final webSocketServiceProvider = Provider<WebSocketService>((ref) {
  return di.sl<WebSocketService>();
});

class ContactsFilter extends Equatable {
  final String? q;
  final String type;
  final int limit;
  final int offset;

  const ContactsFilter({
    this.q,
    this.type = 'both',
    this.limit = 50,
    this.offset = 0,
  });

  @override
  List<Object?> get props => [q, type, limit, offset];
}

final contactsListProvider = FutureProvider.autoDispose.family<List<ContactModel>, ContactsFilter>(
  (ref, filter) {
    final repo = ref.read(contactsRepositoryProvider);
    final wsService = ref.read(webSocketServiceProvider);

    // Ensure WebSocket connected
    wsService.connect();

    // Listen for real-time updates
    final sub = wsService.stream.listen((data) {
      if (data['type'] == 'model_updated' && data['model'] == 'res.partner') {
        ref.invalidateSelf();
      }
    });

    ref.onDispose(() {
      sub.cancel();
    });

    return repo.fetchContacts(
      q: filter.q,
      type: filter.type,
      limit: filter.limit,
      offset: filter.offset,
    );
  },
);

final contactDetailProvider = FutureProvider.autoDispose.family<ContactModel, int>((ref, id) {
  final repo = ref.read(contactsRepositoryProvider);
  final wsService = ref.read(webSocketServiceProvider);

  // Ensure WebSocket connected
  wsService.connect();

  final sub = wsService.stream.listen((data) {
    if (data['type'] == 'model_updated' &&
        data['model'] == 'res.partner' &&
        data['id'] == id) {
      // Invalidate this specific contact's data
      ref.invalidateSelf();
    }
  });

  ref.onDispose(() {
      sub.cancel();
    });

  return repo.getContact(id);
});