import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equatable/equatable.dart';
import '../repositories/accounting_repository.dart';
import '../models/invoice_model.dart';
import '../injection_container.dart' as di;

final accountingRepositoryProvider = Provider<AccountingRepository>((ref) {
  return di.sl<AccountingRepository>();
});

class AccountingQuery extends Equatable {
  final String? q;
  final int limit;
  final int offset;

  const AccountingQuery({
    this.q,
    this.limit = 50,
    this.offset = 0,
  });

  @override
  List<Object?> get props => [q, limit, offset];
}

final invoiceListProvider = FutureProvider.autoDispose.family<List<InvoiceModel>, AccountingQuery>(
  (ref, filter) {
    final repo = ref.read(accountingRepositoryProvider);
    return repo.fetchInvoices(
      q: filter.q,
      limit: filter.limit,
      offset: filter.offset,
    );
  },
);

final invoiceDetailProvider = FutureProvider.autoDispose.family<InvoiceModel, int>((ref, id) {
  final repo = ref.read(accountingRepositoryProvider);
  return repo.getInvoice(id);
});
