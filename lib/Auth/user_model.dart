enum UserRole { admin, user, staff, creator }


class User {
  final String id;
  final String firstName;
  final String lastName;
  final String username;
  final String email;
  final UserRole role;
  final String? imageUrl;

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.email,
    required this.role,
    this.imageUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final userJson = json['User'] ?? json; // handles if nested under "User"
    return User(
      id: userJson['id'],
      firstName: userJson['first_name'],
      lastName: userJson['last_name'],
      username: userJson['username'],
      email: userJson['email'],
      role: UserRole.values.byName(userJson['role']),
      imageUrl: userJson['image_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "first_name": firstName,
      "last_name": lastName,
      "username": username,
      "email": email,
      "role": role.name,
      "image_url": imageUrl,
    };
  }
}
