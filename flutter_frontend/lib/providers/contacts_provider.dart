// lib/providers/contacts_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/contacts_repository.dart';
import '../models/contact_model.dart';
import '../injection_container.dart' as di; // or however you provide deps

final contactsRepositoryProvider = Provider<ContactsRepository>((ref) {
  return di.sl<ContactsRepository>(); // register in your di
});

final contactsListProvider = FutureProvider.family<List<ContactModel>, Map<String, dynamic>>(
  (ref, params) {
    final repo = ref.read(contactsRepositoryProvider);
    final q = params['q'] as String?;
    final limit = params['limit'] as int? ?? 50;
    final offset = params['offset'] as int? ?? 0;
    return repo.fetchContacts(q: q, limit: limit, offset: offset);
  },
);

final contactDetailProvider = FutureProvider.family<ContactModel, int>((ref, id) {
  final repo = ref.read(contactsRepositoryProvider);
  return repo.getContact(id);
});