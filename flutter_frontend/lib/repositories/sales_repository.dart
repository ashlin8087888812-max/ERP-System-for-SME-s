import '../services/api_client.dart';
import '../models/sales_order_model.dart';

class SalesRepository {
  final ApiClient _apiClient;

  SalesRepository(this._apiClient);

  Future<List<SalesOrderModel>> fetchSalesOrders({
    String? q,
    int limit = 50,
    int offset = 0,
  }) async {
    final query = <String, dynamic>{
      if (q != null && q.isNotEmpty) 'q': q,
      'limit': limit,
      'offset': offset,
    };

    final resp = await _apiClient.dio.get('/sales/', queryParameters: query);
    final data = resp.data as List<dynamic>;
    return data.map((e) => SalesOrderModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<SalesOrderModel> getSalesOrder(int id) async {
    final resp = await _apiClient.dio.get('/sales/$id');
    return SalesOrderModel.fromJson(resp.data as Map<String, dynamic>);
  }
}
