class User {
  final String id;
  final String username;
  final List<String> roles;

  User({
    required this.id,
    required this.username,
    required this.roles,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: (json['id'] ?? json['sub'] ?? '') as String,
      username: json['username'] as String,
      roles: List<String>.from(json['roles'] as List),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'roles': roles,
    };
  }

  bool get isAdmin => roles.contains('admin');
}
