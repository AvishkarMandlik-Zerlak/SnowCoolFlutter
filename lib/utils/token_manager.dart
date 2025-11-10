
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

  /// Store the authentication token
  void setToken(String? token) {
    _token = token;
  }

  /// Get the current authentication token
  String? getToken() {
    return _token;
  }

  /// Store the user id
  void setId(int? id) {
    _id = id;
  }

  /// Get the current user id
  int? getId() {
    return _id;
  }

  /// Store the user role
  void setRole(String? role) {
    _role = role;
  }

  /// Get the current user role
  String? getRole() {
    return _role;
  }

  /// Clear the stored token, id and role (for logout)
  void clearToken() {
    _token = null;
    _id = null;
    _role = null;
  }

  /// Check if user is authenticated
  bool isAuthenticated() {
    return _token != null && _token!.isNotEmpty;
  }
}