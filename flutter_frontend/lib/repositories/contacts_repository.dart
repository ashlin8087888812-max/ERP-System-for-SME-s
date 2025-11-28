import '../services/api_client.dart';
import '../models/contact_model.dart';

class ContactsRepository {
  final ApiClient _apiClient;

  ContactsRepository(this._apiClient);

  Future<List<ContactModel>> fetchContacts({String? q, int limit = 50, int offset = 0}) async {
    final query = <String, dynamic>{
      if (q != null && q.isNotEmpty) 'q': q,
      'limit': limit,
      'offset': offset,
    };

    final resp = await _apiClient.dio.get('/contacts/', queryParameters: query);
    final data = resp.data as List<dynamic>;
    return data.map((e) => ContactModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ContactModel> getContact(int id) async {
    final resp = await _apiClient.dio.get('/contacts/$id');
    return ContactModel.fromJson(resp.data as Map<String, dynamic>);
  }
}