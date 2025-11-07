/// Simple token manager to store and retrieve authentication tokens
class TokenManager {
  static final TokenManager _instance = TokenManager._internal();

  factory TokenManager() {
    return _instance;
  }

  TokenManager._internal();

  String? _token;
  String? _username;

  /// Store the authentication token
  void setToken(String? token) {
    _token = token;
  }

  /// Get the current authentication token
  String? getToken() {
    return _token;
  }

  /// Store the username
  void setUsername(String? username) {
    _username = username;
  }

  /// Get the current username
  String? getUsername() {
    return _username;
  }

  /// Clear the stored token and username (for logout)
  void clearToken() {
    _token = null;
    _username = null;
  }

  /// Check if user is authenticated
  bool isAuthenticated() {
    return _token != null && _token!.isNotEmpty;
  }
}
