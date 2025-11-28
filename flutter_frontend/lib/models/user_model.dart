class UserModel {
  final int id;
  final String email;
  final String? fullName;
  final int companyId;
  final String role;

  const UserModel({
    required this.id,
    required this.email,
    this.fullName,
    required this.companyId,
    required this.role,
  });
}
