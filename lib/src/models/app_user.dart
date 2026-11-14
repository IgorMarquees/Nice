enum UserRole { customer, admin }

class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.name,
    this.role = UserRole.customer,
  });

  final String id;
  final String email;
  final String name;
  final UserRole role;

  bool get isAdmin => role == UserRole.admin;
}
