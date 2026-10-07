import '../services/api_client.dart';
import '../models/invoice_model.dart';

class AccountingRepository {
  final ApiClient _apiClient;

  AccountingRepository(this._apiClient);

  Future<List<InvoiceModel>> fetchInvoices({
    String? q,
    int limit = 50,
    int offset = 0,
  }) async {
    final query = <String, dynamic>{
      if (q != null && q.isNotEmpty) 'q': q,
      'limit': limit,
      'offset': offset,
    };

    final resp = await _apiClient.dio.get('/accounting/invoices', queryParameters: query);
    final data = resp.data as List<dynamic>;
    return data.map((e) => InvoiceModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<InvoiceModel> getInvoice(int id) async {
    final resp = await _apiClient.dio.get('/accounting/invoices/$id');
    return InvoiceModel.fromJson(resp.data as Map<String, dynamic>);
  }
}
