import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equatable/equatable.dart';
import '../repositories/sales_repository.dart';
import '../models/sales_order_model.dart';
import '../injection_container.dart' as di;

final salesRepositoryProvider = Provider<SalesRepository>((ref) {
  return di.sl<SalesRepository>();
});

class SalesQuery extends Equatable {
  final String? q;
  final int limit;
  final int offset;

  const SalesQuery({
    this.q,
    this.limit = 50,
    this.offset = 0,
  });

  @override
  List<Object?> get props => [q, limit, offset];
}

final salesListProvider = FutureProvider.autoDispose.family<List<SalesOrderModel>, SalesQuery>(
  (ref, filter) {
    final repo = ref.read(salesRepositoryProvider);
    return repo.fetchSalesOrders(
      q: filter.q,
      limit: filter.limit,
      offset: filter.offset,
    );
  },
);

final salesDetailProvider = FutureProvider.autoDispose.family<SalesOrderModel, int>((ref, id) {
  final repo = ref.read(salesRepositoryProvider);
  return repo.getSalesOrder(id);
});
