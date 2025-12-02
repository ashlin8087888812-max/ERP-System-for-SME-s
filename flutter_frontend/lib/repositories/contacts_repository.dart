import '../services/api_client.dart';
import '../models/contact_model.dart';

class ContactsRepository {
  final ApiClient _apiClient;

  ContactsRepository(this._apiClient);

  Future<List<ContactModel>> fetchContacts({
    String? q,
    String type = 'both',
    int limit = 50,
    int offset = 0,
  }) async {
    final query = <String, dynamic>{
      if (q != null && q.isNotEmpty) 'q': q,
      'type': type,
      'limit': limit,
      'offset': offset,
    };

    try {
      final resp = await _apiClient.dio.get('/contacts/', queryParameters: query);
      
      // Debug logging
      print('DEBUG: fetchContacts response type: ${resp.data.runtimeType}');
      // print('DEBUG: fetchContacts response data: ${resp.data}'); 

      if (resp.data is! List) {
        print('ERROR: Expected List but got ${resp.data.runtimeType}');
        // If it's a map, it might be an error message
        if (resp.data is Map) {
          print('ERROR Details: ${resp.data}');
        }
        throw Exception('Invalid API response format: Expected List but got ${resp.data.runtimeType}');
      }

      final data = resp.data as List<dynamic>;
      return data.map((e) => ContactModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      print('ERROR in fetchContacts: $e');
      rethrow;
    }
  }

  Future<ContactModel> getContact(int id) async {
    final resp = await _apiClient.dio.get('/contacts/$id');
    return ContactModel.fromJson(resp.data as Map<String, dynamic>);
  }

  /// POST /contacts
  Future<ContactModel> createContact(ContactModel contact) async {
    final response = await _apiClient.dio.post(
      "/contacts",
      data: contact.toCreateJson(),
    );
    return ContactModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// PUT /contacts/{id}
  Future<ContactModel> updateContact(
    int id,
    ContactModel contact,
  ) async {
    final response = await _apiClient.dio.put(
      "/contacts/$id",
      data: contact.toUpdateJson(),
    );
    return ContactModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// DELETE /contacts/{id}
  Future<void> deleteContact(int id) async {
    await _apiClient.dio.delete("/contacts/$id");
  }
}