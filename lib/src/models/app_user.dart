enum UserRole { customer, admin }

class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.name,
    this.role = UserRole.customer,
    this.createdAt,
  });

  final String id;
  final String email;
  final String name;
  final UserRole role;
  final DateTime? createdAt;

  bool get isAdmin => role == UserRole.admin;

  AppUser copyWith({UserRole? role}) =>
      AppUser(id: id, email: email, name: name, role: role ?? this.role, createdAt: createdAt);

  /// Linha da tabela `profiles`.
  factory AppUser.fromProfile(Map<String, dynamic> row) => AppUser(
        id: row['id'].toString(),
        email: (row['email'] as String?) ?? '',
        name: (row['name'] as String?)?.trim().isNotEmpty == true ? row['name'] as String : 'Cliente NICE',
        role: row['role'] == 'admin' ? UserRole.admin : UserRole.customer,
        createdAt: DateTime.tryParse(row['created_at']?.toString() ?? '')?.toLocal(),
      );
}
