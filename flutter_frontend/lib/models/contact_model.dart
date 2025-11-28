
class ContactModel {
  final int id;
  final String? name;
  final String? email;
  final String? phone;
  final String? companyName;

  ContactModel({
    required this.id,
    this.name,
    this.email,
    this.phone,
    this.companyName,
  });

  factory ContactModel.fromJson(Map<String, dynamic> json) {
    return ContactModel(
      id: json['id'] as int,
      name: json['name'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      companyName: json['company_name'] as String?,
    );
  }
}
