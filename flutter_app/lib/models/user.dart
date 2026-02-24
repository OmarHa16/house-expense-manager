class User {
  final int id;
  final String name;
  final bool isAdmin;
  final DateTime? createdAt;

  User({
    required this.id,
    required this.name,
    required this.isAdmin,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      isAdmin: json['is_admin'] == 1 || json['is_admin'] == true,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'is_admin': isAdmin,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  User copyWith({
    int? id,
    String? name,
    bool? isAdmin,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      isAdmin: isAdmin ?? this.isAdmin,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class AuthResponse {
  final String token;
  final User user;

  AuthResponse({
    required this.token,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'],
      user: User.fromJson(json['user']),
    );
  }
}
