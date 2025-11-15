/// Simple token manager to store and retrieve authentication tokens
class TokenManager {
  static final TokenManager _instance = TokenManager._internal();

  factory TokenManager() {
    return _instance;
  }

  TokenManager._internal();

  String? _token;
  int? _id;        // Added: user id (Long)
  String? _role;    // Changed: username to role

  // ──────────────────────────────────────────────────────────────
  // NEW PERMISSION FLAGS (added without touching the old code)
  // ──────────────────────────────────────────────────────────────
  bool? _canCreateCustomers;
  bool? _canManageChallans;
  bool? _canManageGoodsItems;
  bool? _canManageProfiles;
  bool? _canManageSettings;
  bool? _canManagePassbook;


  // ──────────────────────────────────────────────────────────────
  // ORIGINAL GETTERS / SETTERS (unchanged)
  // ──────────────────────────────────────────────────────────────
  void setToken(String? token) => _token = token;
  String? getToken() => _token;

  void setId(int? id) => _id = id;
  int? getId() => _id;

  void setRole(String? role) => _role = role;
  String? getRole() => _role;

  // ──────────────────────────────────────────────────────────────
  // NEW PERMISSION GETTERS (safe defaults = false)
  // ──────────────────────────────────────────────────────────────
  bool get canCreateCustomers   => _canCreateCustomers ?? false;
  bool get canManageChallans    => _canManageChallans ?? false;
  bool get canManageGoodsItems  => _canManageGoodsItems ?? false;
  bool get canManageProfiles    => _canManageProfiles ?? false;
  bool get canManageSettings    => _canManageSettings ?? false;
  bool get canManagePassbook    => _canManagePassbook ?? false;


  // ──────────────────────────────────────────────────────────────
  // ORIGINAL CLEAR METHOD (extended to wipe new fields)
  // ──────────────────────────────────────────────────────────────
  void clearToken() {
    _token = null;
    _id = null;
    _role = null;

    // NEW: also clear permissions
    _canCreateCustomers   = null;
    _canManageChallans    = null;
    _canManageGoodsItems  = null;
    _canManageProfiles    = null;
    _canManageSettings    = null;
    _canManagePassbook    = null;
  }

  bool isAuthenticated() => _token != null && _token!.isNotEmpty;

  // ──────────────────────────────────────────────────────────────
  // NEW: Fill permission flags from login JSON
  // ──────────────────────────────────────────────────────────────
  /// Call this after you have already called setToken / setId / setRole.
  /// It only extracts the permission booleans.
  void setPermissionsFromJson(Map<String, dynamic> json) {
    _canCreateCustomers   = json['canCreateCustomers'] as bool?;
    _canManageChallans    = json['canManageChallans'] as bool?;
    _canManageGoodsItems  = json['canManageGoodsItems'] as bool?;
    _canManageProfiles    = json['canManageProfiles'] as bool?;
    _canManageSettings    = json['canManageSettings'] as bool?;
    _canManagePassbook    = json['canManagePassbook'] as bool?;
  }
}