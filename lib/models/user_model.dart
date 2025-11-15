class User {
  final int id;
  final String username;
  final String password;
  final String role;
   bool active;

  // ADD THESE PERMISSION FIELDS
  final bool? canCreateCustomer;
  final bool? canManageGoods;
  final bool? canManageChallans;
  final bool? canManageProfiles;
  final bool? canManageSettings;
  final bool? canManagePassbook; // ← NEW FIELD

  User({
    required this.id,
    required this.username,
    required this.password,
    required this.role,
    required this.active,
    this.canCreateCustomer,
    this.canManageGoods,
    this.canManageChallans,
    this.canManageProfiles,
    this.canManageSettings,
    this.canManagePassbook, // ← NEW FIELD
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      password: json['password'] ?? '',
      role: json['role'],
      active: json['active'],
      canCreateCustomer: json['canCreateCustomer'],
      canManageGoods: json['canManageGoods'],
      canManageChallans: json['canManageChallans'],
      canManageProfiles: json['canManageProfiles'],
      canManageSettings: json['canManageSettings'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'role': role,
      'active': active,
      'canCreateCustomer': canCreateCustomer,
      'canManageGoods': canManageGoods,
      'canManageChallans': canManageChallans,
      'canManageProfiles': canManageProfiles,
      'canManageSettings': canManageSettings,
    };
  }
}